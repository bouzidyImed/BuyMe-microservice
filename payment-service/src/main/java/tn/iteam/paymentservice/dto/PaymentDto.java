package tn.iteam.paymentservice.dto;

import lombok.*;
import tn.iteam.paymentservice.enums.PaymentMethod;
import tn.iteam.paymentservice.enums.PaymentStatus;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PaymentDto {
    private Long id;
    private Long orderId;
    private Double amount;
    private PaymentStatus paymentStatus;
    private PaymentMethod paymentMethod;
    private String transactionId;
}
