package tn.iteam.catalogueservice.service;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import tn.iteam.catalogueservice.dto.ReviewDto;
import tn.iteam.catalogueservice.mappers.ReviewMapper;
import tn.iteam.catalogueservice.models.Product;
import tn.iteam.catalogueservice.models.Review;
import tn.iteam.catalogueservice.repos.ProductRepo;
import tn.iteam.catalogueservice.repos.ReviewRepo;

import java.util.List;

@Service
public class ReviewService {

    private final ReviewRepo reviewRepo;
    private final ProductRepo productRepo;
    private final ReviewMapper reviewMapper;

    public ReviewService(ReviewRepo reviewRepo, ProductRepo productRepo, ReviewMapper reviewMapper) {
        this.reviewRepo = reviewRepo;
        this.productRepo = productRepo;
        this.reviewMapper = reviewMapper;
    }

    /**
     * Add a review for a given product and update product rating automatically.
     */
    @Transactional
    public Review addReview(Long productId, ReviewDto dto) {
        Product product = productRepo.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));

        Review review = reviewMapper.toEntity(dto);
        review.setProduct(product);

        reviewRepo.save(review);

        updateProductAverageRating(product);

        return review;
    }

    /**
     * Update an existing review and recalculate product rating.
     */
    @Transactional
    public Review updateReview(Long reviewId, ReviewDto dto) {
        Review review = reviewRepo.findById(reviewId)
                .orElseThrow(() -> new RuntimeException("Review not found"));

        review.setComment(dto.getComment());
        review.setRating(dto.getRating());
        review.setReviewerName(dto.getReviewerName());

        reviewRepo.save(review);

        updateProductAverageRating(review.getProduct());

        return review;
    }

    /**
     * Delete a review and recalculate product rating.
     */
    @Transactional
    public void deleteReview(Long reviewId) {
        Review review = reviewRepo.findById(reviewId)
                .orElseThrow(() -> new RuntimeException("Review not found"));

        Product product = review.getProduct();
        reviewRepo.delete(review);

        updateProductAverageRating(product);
    }

    /**
     * Calculates and updates the product's average rating based on all its reviews.
     */
    private void updateProductAverageRating(Product product) {
        List<Review> reviews = reviewRepo.findByProduct(product);

        double avgRating = reviews.isEmpty()
                ? 0.0
                : reviews.stream()
                .mapToInt(Review::getRating)
                .average()
                .orElse(0.0);

        product.setRate(avgRating);
        productRepo.save(product);
    }
    @Transactional
    public List<Review> getReviewsByProduct(Long productId) {
        Product product = productRepo.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));
        return reviewRepo.findByProduct(product);
    }

}

