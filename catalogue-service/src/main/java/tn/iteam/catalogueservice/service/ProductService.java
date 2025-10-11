package tn.iteam.catalogueservice.service;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import tn.iteam.catalogueservice.dto.ProductDto;
import tn.iteam.catalogueservice.interfaces.IProduct;
import tn.iteam.catalogueservice.mappers.CatMapper;
import tn.iteam.catalogueservice.mappers.ProductMapper;
import tn.iteam.catalogueservice.models.Product;
import tn.iteam.catalogueservice.repos.ProductRepo;

import java.util.List;
@Service
public class ProductService implements IProduct {


    private final ProductMapper productMapper;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProductRepo productRepo;

    public ProductService(ProductMapper productMapper, KafkaTemplate<String, String> kafkaTemplate, ProductRepo productRepo) {
        this.productMapper = productMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.productRepo = productRepo;
    }

    @Override
    public ProductDto addProduct(ProductDto productDto) {
        Product product = productMapper.toEntity(productDto);
        Product savedProduct = productRepo.save(product);
        // ✅ Publish Kafka event after saving
        kafkaTemplate.send("product-events", "New product created: " + savedProduct.getName());
        return productMapper.toDto(savedProduct);
    }

    @Override
    public void removeProduct(Long id) {

    }

    @Override
    public ProductDto updateProduct(Long id, ProductDto productDto) {
        return null;
    }

    @Override
    public List<ProductDto> getProducts() {
        return productRepo.findAll().stream()
                .map(productMapper::toDto)
                .toList();
    }
}
