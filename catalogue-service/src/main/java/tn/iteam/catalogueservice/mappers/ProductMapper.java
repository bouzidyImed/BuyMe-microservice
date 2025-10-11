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
                .build();
    }

    public Product toEntity(ProductDto dto) {
        if (dto == null) return null;
        return Product.builder()
                .id(dto.getId())
                .name(dto.getName())
                .description(dto.getDescription())
                .build();
    }
}
