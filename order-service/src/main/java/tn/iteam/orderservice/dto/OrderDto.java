package tn.iteam.orderservice.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.Date;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class OrderDto {
    private Date orderDate;
    private Long productId;
    private Long userId;
    private int qteOrdered;
}
