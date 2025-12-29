package tn.iteam.paymentservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import tn.iteam.paymentservice.dto.ProductDto;

@FeignClient(name = "catalogue-service", url = "http://localhost:8084")
public interface ProductClient {
    @GetMapping("/api/products/{id}")
    ProductDto getProductById(@PathVariable("id") Long id);

    @PutMapping("/api/products/{id}/decrease")
    ProductDto decreaseQuantity(
            @PathVariable("id") Long productId,
            @RequestParam("amount") Integer amount
    );
}
