package tn.iteam.catalogueservice.exeptions;

public class ProductNotFoundException extends RuntimeException {
    public ProductNotFoundException(Long id) {
        super("Product not found with ID: " + id);
    }
}
