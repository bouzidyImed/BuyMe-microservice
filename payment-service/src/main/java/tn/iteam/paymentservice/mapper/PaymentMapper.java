package tn.iteam.paymentservice.mapper;

import org.springframework.stereotype.Component;
import tn.iteam.paymentservice.dto.PaymentDto;
import tn.iteam.paymentservice.model.Payment;

@Component
    public class PaymentMapper {

        public PaymentDto toDto(Payment payment) {
            if (payment == null) return null;

            return PaymentDto.builder()
                    .id(payment.getId())
                    .orderId(payment.getOrderId())
                    .amount(payment.getAmount())
                    .paymentStatus(payment.getPaymentStatus())
                    .paymentMethod(payment.getPaymentMethod())
                    .transactionId(payment.getTransactionId())
                    .build();
        }

        public Payment toEntity(PaymentDto dto) {
            if (dto == null) return null;

            return Payment.builder()
                    .orderId(dto.getOrderId())
                    .amount(dto.getAmount())
                    .paymentStatus(dto.getPaymentStatus())
                    .paymentMethod(dto.getPaymentMethod())
                    .transactionId(dto.getTransactionId())
                    .build();
        }
}
