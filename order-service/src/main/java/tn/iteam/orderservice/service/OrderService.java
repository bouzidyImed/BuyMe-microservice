package tn.iteam.orderservice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import feign.FeignException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import tn.iteam.orderservice.dto.ProductDto;
import tn.iteam.orderservice.dto.UserDto;
import tn.iteam.orderservice.feign.AuthClient;
import tn.iteam.orderservice.feign.KafkaClient;
import tn.iteam.orderservice.feign.ProductClient;
import tn.iteam.orderservice.model.Order;
import tn.iteam.orderservice.repositories.OrderRepository;

import java.util.Date;
import java.util.concurrent.CompletableFuture;

@Service
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final AuthClient authClient;
    private final KafkaClient kafkaClient;
    private final ProductClient productClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public OrderService(OrderRepository orderRepository,
                        AuthClient authClient,
                        KafkaClient kafkaClient,
                        ProductClient productClient) {
        this.orderRepository = orderRepository;
        this.authClient = authClient;
        this.kafkaClient = kafkaClient;
        this.productClient = productClient;

        objectMapper.registerModule(new JavaTimeModule());
        objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    public Order placeOrder(String token, Order order) {
        try {
            // --- Token normalization ---
            String bearerToken = token.startsWith("Bearer ") ? token : "Bearer " + token;
            // --- Fetch user ---
            UserDto user = authClient.getCurrentUser(bearerToken);
            if (user == null) {
                throw new RuntimeException("Unauthorized: user not found");
            }
            order.setUserId(user.getId());
            // --- Validate product ---
            ProductDto product;
            try {
                product = productClient.getProductById(order.getProductId());
            } catch (FeignException.NotFound e) {
                throw new RuntimeException("Product not found: " + order.getProductId());
            } catch (FeignException e) {
                log.error("Error calling Product service: status={}, body={}", e.status(), e.contentUTF8());
                throw new RuntimeException("Product service error: " + e.contentUTF8());
            }
            if (order.getQteOrdered() <= 0) {
                throw new RuntimeException("Quantity must be greater than zero");
            }
            // --- Set order date ---
            if (order.getOrderDate() == null) {
                order.setOrderDate(new Date());
            }
            log.info("Placing order for user {} on product {} qty {}", user.getEmail(), product.getId(), order.getQteOrdered());
            // --- Save order ---
            Order savedOrder = orderRepository.save(order);
            log.info("Order saved: {}", objectMapper.writeValueAsString(savedOrder));
            // --- Publish Kafka event asynchronously ---
            String message = String.format(
                    "Order %d created by user %d for product %d (qty=%d)",
                    savedOrder.getId(),
                    savedOrder.getUserId(),
                    savedOrder.getProductId(),
                    savedOrder.getQteOrdered()
            );
            CompletableFuture.runAsync(() -> {
                try {
                    kafkaClient.publish("order-created", message);
                    log.info("Published order-created event to Kafka: {}", message);
                } catch (Exception ex) {
                    log.error("Failed to publish Kafka message for order {}: {}", savedOrder.getId(), ex.getMessage(), ex);
                }
            });

            return savedOrder;

        } catch (FeignException.Unauthorized ex) {
            log.error("Unauthorized: Invalid token", ex);
            throw new RuntimeException("Unauthorized: Invalid or expired token");
        } catch (FeignException.Forbidden ex) {
            log.error("Forbidden: Access denied", ex);
            throw new RuntimeException("Access denied: Invalid or expired token");
        } catch (Exception ex) {
            log.error("Failed to place order", ex);
            throw new RuntimeException("Internal error: " + ex.getMessage());
        }
    }
}
