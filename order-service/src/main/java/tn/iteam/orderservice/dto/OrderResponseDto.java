package tn.iteam.orderservice.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderResponseDto {
    private Long orderId;
    private Long productId;
    private Integer qteOrdered;
    private Double amount;
    private String paymentStatus;
}
