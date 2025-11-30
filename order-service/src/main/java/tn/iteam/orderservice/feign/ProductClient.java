package tn.iteam.orderservice.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import tn.iteam.orderservice.config.FeignConfig;
import tn.iteam.orderservice.dto.ProductDto;

@FeignClient(
        name = "catalogue-service",
        url = "http://localhost:8081",
        configuration = FeignConfig.class
)
public interface ProductClient {
    @GetMapping("/api/products/{id}")
    ProductDto getProductById(@PathVariable("id") Long id);
}


