package tn.iteam.catalogueservice.repos;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.iteam.catalogueservice.models.Product;

public interface ProductRepo extends JpaRepository<Product, Long> {
    boolean existsByName(String name);
}
