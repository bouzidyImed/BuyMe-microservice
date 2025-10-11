package tn.iteam.catalogueservice.interfaces;

import tn.iteam.catalogueservice.dto.ProductDto;

import java.util.List;

public interface IProduct {
    ProductDto  addProduct(ProductDto productDto);
    void removeProduct(Long id);
    ProductDto updateProduct(Long id, ProductDto productDto);
    List<ProductDto> getProducts();
}
