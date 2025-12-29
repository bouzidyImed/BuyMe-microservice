package tn.iteam.orderservice.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import tn.iteam.orderservice.config.FeignConfig;
import tn.iteam.orderservice.dto.ProductDto;

@FeignClient(name = "catalogue-service", configuration = FeignConfig.class)
public interface ProductClient {
    @GetMapping("/api/products/{id}")
    ProductDto getProductById(@PathVariable("id") Long id);

    @PutMapping("/api/products/{id}/decrease")
    void decreaseQuantity(@PathVariable("id") Long id, @RequestParam("amount") Integer amount);
}


