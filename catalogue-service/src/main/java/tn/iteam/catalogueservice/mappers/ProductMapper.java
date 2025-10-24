package tn.iteam.catalogueservice.mappers;

import org.springframework.stereotype.Component;
import tn.iteam.catalogueservice.dto.CategoryDto;
import tn.iteam.catalogueservice.dto.ProductDto;
import tn.iteam.catalogueservice.models.Category;
import tn.iteam.catalogueservice.models.Product;

@Component
public class ProductMapper {

    public ProductDto toDto(Product product) {
        if (product == null) return null;

        return ProductDto.builder()
                .id(product.getId())
                .name(product.getName())
                .description(product.getDescription())
                .price(product.getPrice())
                .categoryId(
                        product.getCategory() != null ? product.getCategory().getId() : null
                )
                .build();
    }

    public Product toEntity(ProductDto dto) {
        if (dto == null) return null;

        Product product = new Product();
        product.setId(dto.getId());
        product.setName(dto.getName());
        product.setDescription(dto.getDescription());
        product.setPrice(dto.getPrice());
        // 🟡 Category will be set in the service layer
        return product;
    }
}
