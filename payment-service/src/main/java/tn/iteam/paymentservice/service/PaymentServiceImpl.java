package tn.iteam.paymentservice.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.iteam.paymentservice.dto.PaymentDto;
import tn.iteam.paymentservice.dto.OrderResponseDto;
import tn.iteam.paymentservice.dto.PaymentPaidEvent;
import tn.iteam.paymentservice.dto.ProductDto;
import tn.iteam.paymentservice.client.OrderClient;
import tn.iteam.paymentservice.client.ProductClient;
import tn.iteam.paymentservice.enums.PaymentStatus;
import tn.iteam.paymentservice.mapper.PaymentMapper;
import tn.iteam.paymentservice.model.OutboxEvent;
import tn.iteam.paymentservice.model.Payment;
import tn.iteam.paymentservice.repos.PaymentRepository;
import tn.iteam.paymentservice.interfaces.PaymentService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.stream.Collectors;

@Service

public class PaymentServiceImpl implements PaymentService {

    private final PaymentRepository paymentRepository;
    private final PaymentMapper paymentMapper;
    private final OrderClient orderClient;
    private final ProductClient productClient;
    private final tn.iteam.paymentservice.repos.OutboxRepository outboxRepository;
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper;
    private static final Logger log = LoggerFactory.getLogger(PaymentServiceImpl.class);

    public PaymentServiceImpl(PaymentRepository paymentRepository, PaymentMapper paymentMapper, OrderClient orderClient, ProductClient productClient, tn.iteam.paymentservice.repos.OutboxRepository outboxRepository, com.fasterxml.jackson.databind.ObjectMapper objectMapper) {
        this.paymentRepository = paymentRepository;
        this.paymentMapper = paymentMapper;
        this.orderClient = orderClient;
        this.productClient = productClient;
        this.outboxRepository = outboxRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    @Transactional
    public PaymentDto createPayment(PaymentDto dto) {
        // 1️⃣ Fetch order details
        OrderResponseDto order = orderClient.getOrder(dto.getOrderId());
        if (order == null) {
            throw new RuntimeException("Order not found: " + dto.getOrderId());
        }

        Long productId = order.getProductId();
        Integer qteOrdered = order.getQteOrdered();

        // 2️⃣ Fetch product details
        ProductDto product = productClient.getProductById(productId);
        if (product == null) {
            throw new RuntimeException("Product not found: " + productId);
        }

        if (product.getQuantity() == null || product.getQuantity() < qteOrdered) {
            throw new RuntimeException("Insufficient stock for product: " + productId);
        }

        // 3️⃣ Calculate total amount
        double total = product.getPrice() * qteOrdered;
        dto.setAmount(total);

        // 4️⃣ Simulate payment success
        dto.setPaymentStatus(PaymentStatus.SUCCESS);
        dto.setTransactionId("tx-" + System.currentTimeMillis());

        // 5️⃣ Save payment
        Payment payment = paymentMapper.toEntity(dto);
        payment = paymentRepository.save(payment);

        // 6️⃣ Create outbox event
        try {
            PaymentPaidEvent ev = new PaymentPaidEvent();
            ev.setAggregateId(payment.getId().toString());
            ev.setOrderId(dto.getOrderId());

            PaymentPaidEvent.Item item = new PaymentPaidEvent.Item();
            item.productId = order.getProductId();
            item.quantity = order.getQteOrdered();
            ev.setItems(List.of(item));

            String payload = objectMapper.writeValueAsString(ev);
            OutboxEvent out = new OutboxEvent(
                    "payment.paid",         // eventType
                    "payment",              // aggregate
                    payment.getId().toString(),
                    payload
            );
            outboxRepository.save(out);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create outbox event: " + e.getMessage(), e);
        }

        // 7️⃣ Automatically update order status to PAID
        try {
            orderClient.updatePaymentStatus(dto.getOrderId(), "PAID");
        } catch (Exception e) {
            log.warn("Failed to update order status for order {}: {}", dto.getOrderId(), e.getMessage());
        }


        // 8️⃣ Decrease product quantity in stock
        try {
            productClient.decreaseQuantity(productId, qteOrdered);
        } catch (Exception e) {
            log.warn("Failed to decrease stock for product {}: {}", productId, e.getMessage());
        }

        return paymentMapper.toDto(payment);
    }


    @Override
    public PaymentDto getPayment(Long id) {
        Payment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return paymentMapper.toDto(payment);
    }

    @Override
    public List<PaymentDto> getAllPayments() {
        return paymentRepository.findAll()
                .stream()
                .map(paymentMapper::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public PaymentDto updatePayment(Long id, PaymentDto dto) {
        Payment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        payment.setAmount(dto.getAmount());
        payment.setOrderId(dto.getOrderId());
        payment.setPaymentStatus(dto.getPaymentStatus());
        payment.setPaymentMethod(dto.getPaymentMethod());
        payment.setTransactionId(dto.getTransactionId());
        paymentRepository.save(payment);
        return paymentMapper.toDto(payment);
    }

    @Override
    public void deletePayment(Long id) {
        paymentRepository.deleteById(id);
    }
}

