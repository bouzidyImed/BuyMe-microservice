package tn.iteam.paymentservice.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class KillBillPaymentResponse {
    private String transactionId;
    private String status;
    private String message;
    private String paymentId;
    private String pluginStatus; // plugin-specific
    private Long processedAmountInCents;
}
