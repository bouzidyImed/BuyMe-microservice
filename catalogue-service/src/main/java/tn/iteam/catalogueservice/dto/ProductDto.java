package tn.iteam.catalogueservice.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
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
    @Size(max = 500, message = "Review summary too long")
    private String review;

    // No validation on images (can be filenames, paths, or URLs)
    private List<String> images;

    @NotNull(message = "Category is required")
    private Long categoryId;

    private String categoryName; // optional convenience field for display

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
