package tn.iteam.catalogueservice.service;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import tn.iteam.catalogueservice.dto.ProductDto;
import tn.iteam.catalogueservice.interfaces.IProduct;
import tn.iteam.catalogueservice.mappers.CatMapper;
import tn.iteam.catalogueservice.mappers.ProductMapper;
import tn.iteam.catalogueservice.models.Category;
import tn.iteam.catalogueservice.models.Product;
import tn.iteam.catalogueservice.repos.CategoryRepo;
import tn.iteam.catalogueservice.repos.ProductRepo;

import java.util.List;
@Service
public class ProductService implements IProduct {


    private final ProductMapper productMapper;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProductRepo productRepo;
    private final CategoryRepo categoryRepo;

    public ProductService(ProductMapper productMapper, KafkaTemplate<String, String> kafkaTemplate, ProductRepo productRepo, CategoryRepo categoryRepo) {
        this.productMapper = productMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.productRepo = productRepo;
        this.categoryRepo = categoryRepo;
    }

    @Override
    public ProductDto addProduct(ProductDto productDto) {
        Product product = productMapper.toEntity(productDto);
        // 🟢 Set the Category based on categoryId
        Category category = categoryRepo.findById(productDto.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found with id: " + productDto.getCategoryId()));
        product.setCategory(category);
        // 🟢 Save product
        Product savedProduct = productRepo.save(product);
        // 🟢 Send Kafka event
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

    @Override
    public ProductDto getProduct(Long id) {
        return productRepo.findById(id)
                .map(productMapper::toDto)
                .orElseThrow(() -> new RuntimeException("Product with ID " + id + " not found"));
    }
}
