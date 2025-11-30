package tn.iteam.orderservice.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.*;
import tn.iteam.orderservice.enums.OrderStatus;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class ProductDto {
    private Long id;
    @NotBlank(message = "Product name is required")
    private String name;
    @NotBlank(message = "Description is required")
    @Size(min = 10, max = 2000, message = "Description must be between 10 and 2000 characters")
    private String description;
    @NotNull(message = "Price is required")
    @Positive(message = "Price must be positive")
    private Double price;
    private Double rate;
    @NotNull(message = "Price is required")
    @Positive(message = "Price must be positive")
    private Integer quantity;
    // Review can be either String or List<String> from product service
    // Using List to handle array responses, ignored if not used
    private List<String> review;
    private OrderStatus status;

    // No validation on images (can be filenames, paths, or URLs)
    private List<String> images;

    @NotNull(message = "Category is required")
    private Long categoryId;

    private String categoryName; // optional convenience field for display

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
