package tn.iteam.orderservice.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.Date;  // Changed from LocalDateTime to Date

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private int qteOrdered;
    @Temporal(TemporalType.TIMESTAMP)  // Explicit for JPA to map Date to datetime
    private Date orderDate;  // Reformulated as Date (serializes to ISO string in JSON)
    private Long productId;
    private Long userId;
}