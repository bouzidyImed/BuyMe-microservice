package tn.iteam.cartservice.service;

import org.springframework.stereotype.Service;
import tn.iteam.cartservice.dto.AddToCartRequest;
import tn.iteam.cartservice.dto.ProductEventDTO;
import tn.iteam.cartservice.model.Cart;
import tn.iteam.cartservice.repos.CartRepository;
import tn.iteam.cartservice.util.SecurityUtils;

import java.util.List;

@Service
public class CartService {
    private final CartRepository cartRepository;
    private final KafkaServiceClient kafkaClient;

    public CartService(CartRepository cartRepository, KafkaServiceClient kafkaClient) {
        this.cartRepository = cartRepository;
        this.kafkaClient = kafkaClient;
    }

    public List<Cart> getUserCart() {
        Long userId = SecurityUtils.getCurrentUserId();
        return cartRepository.findByUserId(userId);
    }

    public Cart addToCart(AddToCartRequest request) {
        Long userId = SecurityUtils.getCurrentUserId();
        Cart cart = Cart.builder()
                .userId(userId)
                .productId(request.getProductId())
                .quantity(request.getQuantity())
                .build();
        Cart saved = cartRepository.save(cart);

        kafkaClient.sendProductEvent(
                ProductEventDTO.builder()
                        .productId(request.getProductId())
                        .userId(userId)
                        .eventType("PRODUCT_ADDED_TO_CART")
                        .quantity(request.getQuantity())
                        .build()
        );

        return saved;
    }
}
