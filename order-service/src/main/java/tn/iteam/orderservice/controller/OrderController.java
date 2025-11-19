package tn.iteam.orderservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.iteam.orderservice.dto.OrderDto;
import tn.iteam.orderservice.dto.UserDto;
import tn.iteam.orderservice.exceptions.BusinessException;
import tn.iteam.orderservice.feign.AuthClient;
import tn.iteam.orderservice.model.Order;
import tn.iteam.orderservice.repositories.OrderRepository;
import tn.iteam.orderservice.service.OrderService;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
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

    @GetMapping("/my-orders")
    @Operation(summary = "Get my orders", description = "Returns list of authenticated user's orders.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Orders retrieved"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<List<Order>> getMyOrders(
            @Parameter(description = "JWT Bearer token") @RequestHeader("Authorization") String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new BusinessException("Invalid token", HttpStatus.UNAUTHORIZED);
        }
        List<Order> orders = orderService.getMyOrders(authHeader);
        return ResponseEntity.ok(orders);
    }

    @PostMapping("/place-order")
    @Operation(summary = "Place a new order", description = "Creates an order after validating user, product, and stock.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Order created"),
            @ApiResponse(responseCode = "400", description = "Invalid quantity or insufficient stock"),
            @ApiResponse(responseCode = "401", description = "Invalid or missing token"),
            @ApiResponse(responseCode = "404", description = "Product not found"),
            @ApiResponse(responseCode = "503", description = "Product service down")
    })
    public ResponseEntity<Order> createOrder(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody @Valid Order orderRequest) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new BusinessException("Missing or invalid Authorization header", HttpStatus.UNAUTHORIZED);
        }

        Order saved = orderService.placeOrder(authHeader, orderRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
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
    @DeleteMapping("/{orderId}")
    @Operation(summary = "Cancel an order", description = "Only pending orders can be cancelled.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Order cancelled successfully"),
            @ApiResponse(responseCode = "400", description = "Order already processed or invalid state"),
            @ApiResponse(responseCode = "404", description = "Order not found"),
            @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    public ResponseEntity<Void> cancelOrder(
            @Parameter(description = "JWT Bearer token") @RequestHeader("Authorization") String authHeader,
            @Parameter(description = "Order ID") @PathVariable Long orderId) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new BusinessException("Invalid token", HttpStatus.UNAUTHORIZED);
        }

        orderService.cancelOrder(authHeader, orderId);
        return ResponseEntity.ok().build();
    }
}
