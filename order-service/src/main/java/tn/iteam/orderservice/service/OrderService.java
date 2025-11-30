package tn.iteam.orderservice.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import feign.FeignException;
import jakarta.transaction.Transactional;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;
import tn.iteam.orderservice.dto.ProductDto;
import tn.iteam.orderservice.dto.UserDto;
import tn.iteam.orderservice.enums.OrderStatus;
import tn.iteam.orderservice.enums.PaymentStatus;
import tn.iteam.orderservice.exceptions.BusinessException;
import tn.iteam.orderservice.feign.AuthClient;
import tn.iteam.orderservice.feign.KafkaClient;
import tn.iteam.orderservice.feign.ProductClient;
import tn.iteam.orderservice.model.Order;
import tn.iteam.orderservice.repositories.OrderRepository;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final AuthClient authClient;
    private final KafkaClient kafkaClient;
    private final ProductClient productClient;
    private final ObjectMapper objectMapper;

    public OrderService(OrderRepository orderRepository,
                        AuthClient authClient,
                        KafkaClient kafkaClient,
                        ProductClient productClient) {
        this.orderRepository = orderRepository;
        this.authClient = authClient;
        this.kafkaClient = kafkaClient;
        this.productClient = productClient;

        this.objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
        objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    @Transactional
    public Order placeOrder(String bearerToken, Order orderRequest) {
        // Fetch & validate user via Auth service, fallback to JWT if service unavailable
        UserDto user = getCurrentUser();
        if (user == null) {
            throw new BusinessException("Unauthorized: user not found", HttpStatus.UNAUTHORIZED);
        }
        orderRequest.setUserId(user.getId());
        
        // Fetch product from product service
        ProductDto product;
        try {
            product = productClient.getProductById(orderRequest.getProductId());
            log.debug("Fetched product: id={}, name={}, availableQuantity={}", 
                product.getId(), product.getName(), product.getQuantity());
        } catch (FeignException.NotFound e) {
            throw new BusinessException("Product not found: " + orderRequest.getProductId(), HttpStatus.NOT_FOUND);
        } catch (FeignException e) {
            log.error("Product service error – status={}, body={}", e.status(), e.contentUTF8(), e);
            throw new BusinessException("Product service unavailable", HttpStatus.SERVICE_UNAVAILABLE);
        }
        
        // Validate product exists and is available
        if (product == null) {
            throw new BusinessException("Product not found: " + orderRequest.getProductId(), HttpStatus.NOT_FOUND);
        }
        
        // Validate ordered quantity is positive
        if (orderRequest.getQteOrdered() <= 0) {
            throw new BusinessException("Ordered quantity must be greater than zero. Received: " + orderRequest.getQteOrdered(), HttpStatus.BAD_REQUEST);
        }
        
        // Check product stock quantity from product service
        Integer availableQuantity = product.getQuantity();
        if (availableQuantity == null) {
            log.error("Product {} has null quantity", product.getId());
            throw new BusinessException("Product stock information is unavailable (ID: " + product.getId() + ")", HttpStatus.BAD_REQUEST);
        }
        
        if (availableQuantity <= 0) {
            log.warn("Order attempt for out-of-stock product: productId={}, availableQuantity={}", 
                product.getId(), availableQuantity);
            throw new BusinessException("Product is out of stock (ID: " + product.getId() + ", Available: " + availableQuantity + ")", HttpStatus.BAD_REQUEST);
        }
        
        // Validate ordered quantity doesn't exceed available stock
        if (orderRequest.getQteOrdered() > availableQuantity) {
            log.warn("Order quantity exceeds available stock: productId={}, ordered={}, available={}", 
                product.getId(), orderRequest.getQteOrdered(), availableQuantity);
            throw new BusinessException(
                    "Insufficient stock. Requested: %d, Available: %d (Product ID: %d)".formatted(
                        orderRequest.getQteOrdered(), availableQuantity, product.getId()),
                    HttpStatus.BAD_REQUEST
            );
        }
        
        log.info("Quantity validation passed: productId={}, ordered={}, available={}", 
            product.getId(), orderRequest.getQteOrdered(), availableQuantity);

        // Set defaults
        if (orderRequest.getOrderDate() == null) orderRequest.setOrderDate(new Date());
        orderRequest.setStatus(OrderStatus.PENDING);

        // Persist order
        Order savedOrder = orderRepository.save(orderRequest);
        logSavedOrder(savedOrder);

        // Async Kafka event
        publishOrderCreatedEventAsync(savedOrder);

        return savedOrder;
    }

    @Transactional
    public List<Order> getMyOrders(String bearerToken) {
        UserDto user = getCurrentUser();
        if (user == null) {
            throw new BusinessException("Unauthorized", HttpStatus.UNAUTHORIZED);
        }
        log.info("Fetching orders for user {} (email={})", user.getId(), user.getEmail());
        return orderRepository.findByUserId(user.getId());
    }

    @Transactional
    public void cancelOrder(String bearerToken, Long orderId) {
        UserDto user = getCurrentUser();
        if (user == null) {
            throw new BusinessException("Unauthorized", HttpStatus.UNAUTHORIZED);
        }

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found: " + orderId, HttpStatus.NOT_FOUND));

        if (!order.getUserId().equals(user.getId())) {
            throw new BusinessException("You can only cancel your own orders", HttpStatus.FORBIDDEN);
        }

        if (order.getStatus() == OrderStatus.CANCELLED) return; // idempotent

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new BusinessException("Only pending orders can be cancelled", HttpStatus.BAD_REQUEST);
        }

        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        publishOrderCancelledEventAsync(order, user.getId());
    }

    private void logSavedOrder(Order order) {
        try {
            log.info("Order saved: {}", objectMapper.writeValueAsString(order));
        } catch (JsonProcessingException e) {
            log.warn("Could not serialize saved order for logging", e);
        }
    }

    private void publishOrderCreatedEventAsync(Order order) {
        CompletableFuture.runAsync(() -> {
            String message = String.format(
                    "Order %d created by user %d for product %d (qty=%d)",
                    order.getId(), order.getUserId(), order.getProductId(), order.getQteOrdered()
            );
            try {
                kafkaClient.publish("order-created", message);
                log.info("Published order-created event: {}", message);
            } catch (Exception ex) {
                log.error("Failed to publish Kafka event for order {}: {}", order.getId(), ex.getMessage(), ex);
            }
        });
    }

    private void publishOrderCancelledEventAsync(Order order, Long userId) {
        CompletableFuture.runAsync(() -> {
            String message = String.format("Order %d cancelled by user %d", order.getId(), userId);
            try {
                kafkaClient.publish("order-cancelled", message);
                log.info("Published Kafka event | topic=order-cancelled | orderId={} | message='{}'", order.getId(), message);
            } catch (Exception e) {
                log.error("Failed to publish order-cancelled event to Kafka | orderId={} | error={}", order.getId(), e.toString(), e);
            }
        });
    }

    /**
     * Gets the current user from auth service, with fallback to JWT token extraction.
     * This method tries to call the auth service first, and if it fails (e.g., 404),
     * it extracts user information directly from the validated JWT token.
     */
    private UserDto getCurrentUser() {
        // Try auth service first
        try {
            UserDto user = authClient.getCurrentUser();
            if (user != null) {
                return user;
            }
        } catch (FeignException.NotFound e) {
            log.warn("Auth service endpoint not found (404), falling back to JWT token extraction. URL: http://localhost:8085/api/auth/me");
            // Fall through to JWT extraction
        } catch (FeignException.Unauthorized e) {
            log.error("Auth service unauthorized (401) – token may be invalid, body={}", e.contentUTF8(), e);
            throw new BusinessException("Unauthorized or token invalid", HttpStatus.UNAUTHORIZED);
        } catch (FeignException e) {
            log.warn("Auth service error (status={}), falling back to JWT token extraction. Error: {}", e.status(), e.getMessage());
            // Fall through to JWT extraction for other errors
        }

        // Fallback: Extract user info from JWT token
        return extractUserFromJwt();
    }

    /**
     * Extracts user information from the validated JWT token in Spring Security context.
     * Converts UUID sub claim to Long by hashing.
     */
    private UserDto extractUserFromJwt() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (!(auth instanceof JwtAuthenticationToken jwtAuth)) {
            log.error("Authentication is not a JwtAuthenticationToken. Type: {}", 
                auth != null ? auth.getClass().getName() : "null");
            throw new BusinessException("Invalid authentication context", HttpStatus.UNAUTHORIZED);
        }

        Jwt jwt = jwtAuth.getToken();
        String sub = jwt.getClaimAsString("sub");
        String email = jwt.getClaimAsString("email");
        String givenName = jwt.getClaimAsString("given_name");
        String familyName = jwt.getClaimAsString("family_name");

        if (sub == null || sub.isEmpty()) {
            log.error("JWT token missing 'sub' claim");
            throw new BusinessException("Invalid token: missing user identifier", HttpStatus.UNAUTHORIZED);
        }

        // Convert UUID string to Long by hashing (deterministic)
        Long userId = uuidToLong(sub);
        
        log.debug("Extracted user from JWT: id={}, email={}, name={} {}", userId, email, givenName, familyName);
        
        return new UserDto(userId, email, givenName, familyName);
    }

    /**
     * Converts a UUID string to a Long by hashing.
     * This provides a deterministic mapping from UUID to Long.
     */
    private Long uuidToLong(String uuid) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] hash = md.digest(uuid.getBytes(StandardCharsets.UTF_8));
            // Take first 8 bytes and convert to long
            long result = 0;
            for (int i = 0; i < 8; i++) {
                result = (result << 8) | (hash[i] & 0xFF);
            }
            // Ensure positive (remove sign bit)
            return Math.abs(result);
        } catch (NoSuchAlgorithmException e) {
            log.error("Failed to hash UUID to Long", e);
            // Fallback: use simple hash code
            return (long) Math.abs(uuid.hashCode());
        }
    }

    private String normalizeToken(String token) {
        if (!token.startsWith("Bearer ")) {
            return "Bearer " + token;
        }
        return token;
    }


    /**
     * Admin approves an order - only if payment is completed
     */
    @Transactional
    public Order approveOrder(String bearerToken, Long orderId) {
        UserDto admin = getCurrentUser();
        if (admin == null) {
            throw new BusinessException("Unauthorized", HttpStatus.UNAUTHORIZED);
        }

        // Check if user is admin (you might want to add role check)
        // This is handled by @PreAuthorize in controller, but double-check here if needed

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found: " + orderId, HttpStatus.NOT_FOUND));

        // Validate payment is completed
        if (order.getPaymentStatus() != PaymentStatus.PAID) {
            log.warn("Admin {} attempted to approve order {} without payment. Payment status: {}",
                    admin.getId(), orderId, order.getPaymentStatus());
            throw new BusinessException(
                    "Cannot approve order: Payment not completed. Current payment status: " + order.getPaymentStatus(),
                    HttpStatus.BAD_REQUEST
            );
        }

        // Validate order is in a valid state for approval
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new BusinessException("Cannot approve a cancelled order", HttpStatus.BAD_REQUEST);
        }

        if (order.getStatus() == OrderStatus.APPROVED) {
            log.info("Order {} already approved", orderId);
            return order; // Idempotent
        }

        // Approve the order
        order.setStatus(OrderStatus.APPROVED);
        order.setApprovedBy(admin.getId());
        order.setApprovedAt(new Date());

        Order savedOrder = orderRepository.save(order);
        log.info("Order {} approved by admin {}", orderId, admin.getId());

        // Publish approval event
        publishOrderApprovedEventAsync(savedOrder, admin.getId());

        return savedOrder;
    }

    @Transactional
    public List<Order> getAllOrders(String bearerToken) {
        UserDto user = getCurrentUser();
        if (user == null) {
            throw new BusinessException("Unauthorized", HttpStatus.UNAUTHORIZED);
        }

        List<Order> orders = orderRepository.findAll();
        log.info("Found {} total orders", orders.size());
        return orders;
    }


    /**
     * Updates payment status for an order (called by payment service or for testing)
     */
    @Transactional
    public Order updatePaymentStatus(Long orderId, PaymentStatus paymentStatus) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found: " + orderId, HttpStatus.NOT_FOUND));
        
        PaymentStatus oldStatus = order.getPaymentStatus();
        order.setPaymentStatus(paymentStatus);
        orderRepository.save(order);
        
        log.info("Payment status updated for order {}: {} -> {}", orderId, oldStatus, paymentStatus);
        
        // Publish event
        publishPaymentStatusUpdatedEventAsync(order, paymentStatus);
        
        return order;
    }

    // Helper methods for events
    private void publishPaymentStatusUpdatedEventAsync(Order order, PaymentStatus paymentStatus) {
        CompletableFuture.runAsync(() -> {
            String message = String.format("Order %d payment status updated to %s", order.getId(), paymentStatus);
            try {
                kafkaClient.publish("payment-status-updated", message);
                log.info("Published payment-status-updated event: {}", message);
            } catch (Exception ex) {
                log.error("Failed to publish payment status event for order {}: {}", order.getId(), ex.getMessage(), ex);
            }
        });
    }

    private void publishOrderApprovedEventAsync(Order order, Long adminId) {
        CompletableFuture.runAsync(() -> {
            String message = String.format("Order %d approved by admin %d", order.getId(), adminId);
            try {
                kafkaClient.publish("order-approved", message);
                log.info("Published order-approved event: {}", message);
            } catch (Exception ex) {
                log.error("Failed to publish order approved event for order {}: {}", order.getId(), ex.getMessage(), ex);
            }
        });
    }

    // Add to OrderService.java
    public Order getOrderById(Long orderId) {
        return orderRepository.findById(orderId)
                .orElseThrow(() -> new BusinessException("Order not found: " + orderId, HttpStatus.NOT_FOUND));
    }
}
