package tn.iteam.paymentservice.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import tn.iteam.paymentservice.enums.PaymentMethod;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class KillBillPaymentRequest {
    private Long orderId; // provided by frontend, validated by calling order-service
    private PaymentMethod paymentMethod;
    private String accountId;
    private String paymentMethodId; // Kill Bill payment method id (or plugin-specific)
    private String paymentExternalKey; // optional
    private Long amountInCents;
    private String currency;
    private String invoiceId; // to link payment to invoice
}
