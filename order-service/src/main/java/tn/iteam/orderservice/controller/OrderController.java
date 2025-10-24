package tn.iteam.orderservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.iteam.orderservice.dto.UserDto;
import tn.iteam.orderservice.feign.AuthClient;
import tn.iteam.orderservice.model.Order;
import tn.iteam.orderservice.repositories.OrderRepository;
import tn.iteam.orderservice.service.OrderService;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Slf4j
public class OrderController {

    private final OrderService orderService;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AuthClient authClient;
    private final OrderRepository orderRepository;
    @PostMapping("/place-Order")
    public ResponseEntity<Order> createOrder(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Order orderRequest) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            String jwtToken = authHeader.substring(7);
            UserDto userDto = authClient.getCurrentUser("Bearer " + jwtToken);
            Long userId = userDto.getId();

            log.info("Fetched user ID: {} for email: {}", userId, userDto.getEmail());

            Order order = Order.builder()
                    .userId(userId)
                    .productId(orderRequest.getProductId())
                    .qteOrdered(orderRequest.getQteOrdered())
                    .orderDate(new Date())
                    .build();

            Order savedOrder = orderRepository.save(order);

            return ResponseEntity.status(HttpStatus.CREATED).body(savedOrder);
        } catch (Exception e) {
            log.error("Failed to create order", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }


    private ResponseEntity<Map<String, Object>> buildErrorResponse(Exception ex, String path, HttpStatus status) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", LocalDateTime.now());
        body.put("path", path);
        body.put("status", status.value());
        body.put("message", ex.getMessage());
        body.put("exception", ex.getClass().getSimpleName());
        return ResponseEntity.status(status).body(body);
    }
}
