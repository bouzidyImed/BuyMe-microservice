package tn.iteam.catalogueservice.exeptions;

public class ProductAlreadyExistsException extends RuntimeException {
    public ProductAlreadyExistsException(String name) {
        super("Product already exists with name: " + name);
    }
}
