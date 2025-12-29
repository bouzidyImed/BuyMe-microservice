package tn.iteam.catalogueservice.service;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import tn.iteam.catalogueservice.dto.ProductDto;
import tn.iteam.catalogueservice.exceptions.ProductAlreadyExistsException;
import tn.iteam.catalogueservice.exceptions.ProductNotFoundException;
import tn.iteam.catalogueservice.interfaces.FileStorageService;
import tn.iteam.catalogueservice.interfaces.IProduct;
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
    private final FileStorageService fileStorageService;
    public ProductService(ProductMapper productMapper,
                          KafkaTemplate<String, String> kafkaTemplate,
                          ProductRepo productRepo,
                          CategoryRepo categoryRepo, FileStorageService fileStorageService) {
        this.productMapper = productMapper;
        this.kafkaTemplate = kafkaTemplate;
        this.productRepo = productRepo;
        this.categoryRepo = categoryRepo;
        this.fileStorageService = fileStorageService;
    }

    // ---------- Helper methods ----------
    private Product getProductOrThrow(Long id) {
        return productRepo.findById(id)
                .orElseThrow(() -> new ProductNotFoundException(id));
    }

    private Category getCategoryOrThrow(Long categoryId) {
        return categoryRepo.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category not found with ID: " + categoryId));
    }

    private void sendKafkaEvent(String message) {
        kafkaTemplate.send("product-events", message);
    }

    // ---------- CRUD METHODS ----------
    @Override
    public ProductDto addProduct(ProductDto productDto) {
        if (productRepo.existsByName(productDto.getName())) {
            throw new ProductAlreadyExistsException(productDto.getName());
        }

        Product product = productMapper.toEntity(productDto);
        product.setCategory(getCategoryOrThrow(productDto.getCategoryId()));
        product.setImages(productDto.getImages());

        Product savedProduct = productRepo.save(product);
        sendKafkaEvent("New product created: " + savedProduct.getName());

        return productMapper.toDto(savedProduct);
    }

    @Override
    public void removeProduct(Long id) {
        Product product = getProductOrThrow(id);
        productRepo.delete(product);
        sendKafkaEvent("Product deleted: " + product.getName());
    }

    @Override
    public ProductDto updateProduct(Long id, ProductDto productDto) {
        Product existingProduct = getProductOrThrow(id);

        // Prevent duplicate product names
        if (!existingProduct.getName().equalsIgnoreCase(productDto.getName())
                && productRepo.existsByName(productDto.getName())) {
            throw new ProductAlreadyExistsException(productDto.getName());
        }

        existingProduct.setName(productDto.getName());
        existingProduct.setDescription(productDto.getDescription());
        existingProduct.setPrice(productDto.getPrice());
        existingProduct.setImages(productDto.getImages());

        if (productDto.getCategoryId() != null) {
            existingProduct.setCategory(getCategoryOrThrow(productDto.getCategoryId()));
        }

        Product updatedProduct = productRepo.save(existingProduct);
        sendKafkaEvent("Product updated: " + updatedProduct.getName());

        return productMapper.toDto(updatedProduct);
    }

    @Override
    public List<ProductDto> getProducts() {
        return productRepo.findAll().stream()
                .map(productMapper::toDto)
                .toList();
    }

    @Override
    public ProductDto getProduct(Long id) {
        return productMapper.toDto(getProductOrThrow(id));
    }

    public ProductDto decreaseQuantity(Long id, Integer amount) {
        if (amount == null || amount <= 0) throw new RuntimeException("Invalid decrease amount");
        Product existing = getProductOrThrow(id);
        Integer current = existing.getQuantity();
        if (current == null || current < amount) {
            throw new RuntimeException("Insufficient stock for product: " + id);
        }
        existing.setQuantity(current - amount);
        Product saved = productRepo.save(existing);
        sendKafkaEvent("Product stock decreased: " + saved.getName() + " by " + amount);
        return productMapper.toDto(saved);
    }
}
