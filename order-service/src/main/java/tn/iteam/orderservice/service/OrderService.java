package tn.iteam.orderservice.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import feign.FeignException;
import jakarta.transaction.Transactional;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import tn.iteam.orderservice.dto.ProductDto;
import tn.iteam.orderservice.dto.UserDto;
import tn.iteam.orderservice.enums.OrderStatus;
import tn.iteam.orderservice.exceptions.BusinessException;
import tn.iteam.orderservice.feign.AuthClient;
import tn.iteam.orderservice.feign.KafkaClient;
import tn.iteam.orderservice.feign.ProductClient;
import tn.iteam.orderservice.model.Order;
import tn.iteam.orderservice.repositories.OrderRepository;

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

        // Configure ObjectMapper once
        this.objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
        objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    /**
     * Places an order for the authenticated user.
     * All business rules are validated here.
     *
     * @param bearerToken  Authorization header (with or without "Bearer ")
     * @param orderRequest Order payload from client
     * @return Persisted Order entity
     * @throws BusinessException with proper HTTP status and message
     */
    @Transactional
    public Order placeOrder(String bearerToken, Order orderRequest) {

        // ----- Token normalisation -----
        String token = bearerToken.startsWith("Bearer ") ? bearerToken : "Bearer " + bearerToken;
        // ----- Fetch & validate user -----
        UserDto user = authClient.getCurrentUser(token);
        if (user == null) {
            throw new BusinessException("Unauthorized: user not found", HttpStatus.UNAUTHORIZED);
        }
        orderRequest.setUserId(user.getId());
        // ----- Fetch & validate product + stock -----
        ProductDto product;
        try {
            product = productClient.getProductById(orderRequest.getProductId());
        } catch (FeignException.NotFound e) {
            throw new BusinessException(
                    "Product not found: " + orderRequest.getProductId(),
                    HttpStatus.NOT_FOUND);
        } catch (FeignException e) {
            log.error("Product service error – status={}, body={}", e.status(), e.contentUTF8(), e);
            throw new BusinessException("Product service unavailable", HttpStatus.SERVICE_UNAVAILABLE);
        }
        // ----- Quantity validation -----
        if (orderRequest.getQteOrdered() <= 0) {
            throw new BusinessException("Quantity must be greater than zero", HttpStatus.BAD_REQUEST);
        }
        Integer available = product.getQuantity();
        if (available == null || available <= 0) {
            throw new BusinessException(
                    "Product is out of stock or quantity not set (ID: " + product.getId() + ")",
                    HttpStatus.BAD_REQUEST);
        }
        if (orderRequest.getQteOrdered() > available) {
            throw new BusinessException(
                    "Requested quantity (%d) exceeds available stock (%d)"
                            .formatted(orderRequest.getQteOrdered(), available),
                    HttpStatus.BAD_REQUEST);
        }

        // ----- Set order date if missing -----
        if (orderRequest.getOrderDate() == null) {
            orderRequest.setOrderDate(new Date());
        }
        //set default status as pending
        orderRequest.setStatus(OrderStatus.PENDING);
        // ----- Logging -----
        log.info("Placing order for user {} (email={}) – product {} – qty {}",
                user.getId(), user.getEmail(), product.getId(), orderRequest.getQteOrdered());
        // ----- Persist order -----
        Order savedOrder = orderRepository.save(orderRequest);
        logSavedOrder(savedOrder);

        // ----- Async: Publish Kafka event -----
        publishOrderCreatedEventAsync(savedOrder);
        return savedOrder;
    }

    /**
     * Logs the saved order in JSON format.
     */
    private void logSavedOrder(Order order) {
        try {
            log.info("Order saved: {}", objectMapper.writeValueAsString(order));
        } catch (JsonProcessingException e) {
            log.warn("Could not serialize saved order for logging", e);
        }
    }
    @Transactional()
    public List<Order> getMyOrders(String bearerToken) {
        String token = bearerToken.startsWith("Bearer ") ? bearerToken : "Bearer " + bearerToken;

        UserDto user = authClient.getCurrentUser(token);
        if (user == null) {
            throw new BusinessException("Unauthorized", HttpStatus.UNAUTHORIZED);
        }

        log.info("Fetching orders for user {} (email={})", user.getId(), user.getEmail());

        return orderRepository.findByUserId(user.getId());
    }
    /**
     * Publishes order creation event asynchronously via KafkaClient (Feign).
     * Fire-and-forget: failures are logged but do not affect the HTTP response.
     */
    private void publishOrderCreatedEventAsync(Order order) {
        String message = String.format(
                "Order %d created by user %d for product %d (qty=%d)",
                order.getId(), order.getUserId(), order.getProductId(), order.getQteOrdered());

        CompletableFuture.runAsync(() -> {
            try {
                kafkaClient.publish("order-created", message);
                log.info("Published order-created event: {}", message);
            } catch (Exception ex) {
                log.error("Failed to publish Kafka event for order {}: {}", order.getId(), ex.getMessage(), ex);
            }
        });
    }
    @Transactional
    public void cancelOrder(String bearerToken, Long orderId) {

        // Extract token early for logging
        String token = bearerToken.startsWith("Bearer ") ? bearerToken.substring(7) : bearerToken;
        String tokenPreview = token.length() > 10 ? token.substring(0, 10) + "..." : token;

        log.info(">>> Starting order cancellation | orderId={} | tokenPreview={}", orderId, tokenPreview);

        // === 1. Validate & authenticate user ===
        UserDto user;
        try {
            user = authClient.getCurrentUser("Bearer " + token);
            if (user == null) {
                log.warn("Authentication failed: getCurrentUser returned null | orderId={}", orderId);
                throw new BusinessException("Unauthorized: invalid or expired token", HttpStatus.UNAUTHORIZED);
            }
            log.info("User authenticated | orderId={} | userId={} | email={}", orderId, user.getId(), user.getEmail());
        } catch (Exception e) {
            log.error("Failed to authenticate user via auth service | orderId={} | error={}", orderId, e.toString(), e);
            throw new BusinessException("Authentication service error", HttpStatus.UNAUTHORIZED);
        }

        // === 2. Load order ===
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> {
                    log.warn("Order not found in database | orderId={}", orderId);
                    return new BusinessException("Order not found: " + orderId, HttpStatus.NOT_FOUND);
                });

        log.debug("Order loaded | orderId={} | status={} | userId={} | productId={} | qte={}",
                order.getId(), order.getStatus(), order.getUserId(), order.getProductId(), order.getQteOrdered());

        // === 3. Ownership check ===
        if (!order.getUserId().equals(user.getId())) {
            log.warn("Forbidden: user {} attempted to cancel order {} owned by {}",
                    user.getId(), orderId, order.getUserId());
            throw new BusinessException("You can only cancel your own orders", HttpStatus.FORBIDDEN);
        }

        // === 4. Idempotency: already cancelled? ===
        if (order.getStatus() == OrderStatus.CANCELLED) {
            log.info("Order already cancelled (idempotent) | orderId={} | userId={}", orderId, user.getId());
            return; // 200 OK
        }

        // === 5. Status validation ===
        if (order.getStatus() != OrderStatus.PENDING) {
            log.warn("Cannot cancel order in state {} | orderId={}", order.getStatus(), orderId);
            throw new BusinessException("Only pending orders can be cancelled", HttpStatus.BAD_REQUEST);
        }

        // === 6. Perform cancellation ===
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        log.info("Order cancelled successfully | orderId={} | userId={} | from=PENDING to=CANCELLED",
                orderId, user.getId());

        // === 7. Async event publish (fire-and-forget with logging) ===
        publishOrderCancelledEventAsync(order, user.getId());
    }

    private void publishOrderCancelledEventAsync(Order order, Long userId) {
        CompletableFuture.runAsync(() -> {
            String message = String.format("Order %d cancelled by user %d", order.getId(), userId);
            try {
                kafkaClient.publish("order-cancelled", message);
                log.info("Published Kafka event | topic=order-cancelled | orderId={} | message='{}'",
                        order.getId(), message);
            } catch (Exception e) {
                log.error("Failed to publish order-cancelled event to Kafka | orderId={} | error={}",
                        order.getId(), e.toString(), e);
                // Do NOT throw — this is background
            }
        });
    }
}