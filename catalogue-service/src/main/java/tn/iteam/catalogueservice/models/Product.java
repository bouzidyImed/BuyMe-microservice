package tn.iteam.catalogueservice.models;

import com.fasterxml.jackson.core.JsonToken;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private String description;
    private Double price;

    // Many products belong to one category
    @ManyToOne
    @JoinColumn(name = "category_id")
    private Category category;

}
