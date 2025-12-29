package tn.iteam.paymentservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import tn.iteam.paymentservice.dto.OrderResponseDto;

    @FeignClient(name = "order-service")
    public interface OrderClient {
        @GetMapping("/api/orders/{orderId}")
        OrderResponseDto getOrder(@PathVariable("orderId") Long orderId);

        @PutMapping("/api/orders/{orderId}/payment-status")
        void updatePaymentStatus(@PathVariable("orderId") Long orderId, @RequestParam("paymentStatus") String paymentStatus);

}
