package tn.iteam.cartservice.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.iteam.cartservice.dto.AddToCartRequest;
import tn.iteam.cartservice.model.Cart;
import tn.iteam.cartservice.service.CartService;

import java.util.List;
@RestController
@RequestMapping("/api/cart")
public class CartController {
    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping("/myCart")
    public ResponseEntity<List<Cart>> getCart() {
        return ResponseEntity.ok(cartService.getUserCart());
    }

    @PostMapping("/new")
    public ResponseEntity<Cart> addToCart(@RequestBody AddToCartRequest request) {
        return ResponseEntity.ok(cartService.addToCart(request));
    }
}
