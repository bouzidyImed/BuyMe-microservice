import { Component, OnInit, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../../services/product.service';
import { CartService } from '../../../services/cart.service';
import { ReviewService } from '../../../services/review.service';
import { ModalService } from '../../../shared/modal.service';
import { APP_CONFIG } from '../../../../main';

@Component({
  selector: 'app-single',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './single.component.html',
  styleUrls: ['./single.component.css']
})
export class SingleComponent implements OnInit {
  product: any = null;
  loading = true;
  error: string | null = null;
  quantity = 1;
  reviews: any[] = [];
  selectedRating = 0;
  isAuthenticated = false;
  discountPercent = 0;

  constructor(
    private route: ActivatedRoute,
    private productService: ProductService,
    private cartService: CartService,
    private router: Router,
    private reviewService: ReviewService,
    private modalService: ModalService,
    @Inject(APP_CONFIG) private config: any
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id || isNaN(id)) {
      this.error = 'Invalid product ID';
      this.loading = false;
      return;
    }

    this.productService.getById(id).subscribe({
      next: (p) => {
        this.product = p;
        this.loading = false;

        // subscribe to current discount percent from cart service
        try {
          this.cartService.discount$.subscribe(pct => this.discountPercent = pct || 0);
        } catch (e) {
          this.discountPercent = 0;
        }

        // set authentication flag
        this.isAuthenticated = !!localStorage.getItem('jwt_token');

        // load existing reviews for product
        this.loadReviews();

        // Initialize carousel after images are loaded
        setTimeout(() => {
          this.initializeCarousel();
        }, 100);
      },
      error: (err) => {
        this.error = err.error?.message || err.message || 'Unable to load product.';
        this.loading = false;
      }
    });
  }

  increase(): void {
    const max = this.product?.quantity ?? Infinity;
    if (this.quantity < max) this.quantity += 1;
  }

  decrease(): void {
    if (this.quantity > 1) this.quantity -= 1;
  }

  addToCart(): void {
    if (!this.product) return;

    const available = this.product.quantity ?? Infinity;
    if (this.quantity > available) {
      this.modalService.showAlert('Cannot add to cart: requested quantity exceeds available stock.', 'Warning');
      return;
    }

    this.cartService.addToCartProduct(
      {
        id: this.product.id,
        name: this.product.name,
        price: this.product.price,
        images: this.product.images,
        stock: this.product.quantity
      },
      this.quantity
    );

    this.quantity = 1;
  }

  logout(): void {
    localStorage.removeItem('jwt_token');
    localStorage.removeItem('currentUser');
    this.router.navigate(['/login']);
  }

  // Updated method to match HomeComponent's logic
  getImageUrl(img: string): string {
    if (!img) return '/assets/img/product-3.png';
    
    // Check if it's already a data URL or full URL (like in HomeComponent)
    if (img.startsWith('data:') || img.startsWith('http') || img.startsWith('/')) {
      return img;
    }
    
    // If it's just a filename, construct the URL (fallback logic)
    const apiFromConfig: string = (this.config?.apiUrl || '').replace(/\/$/, '');
    let productImageBaseUrl = '';
    
    if (apiFromConfig.includes('api-gateway')) {
      productImageBaseUrl = `${globalThis.location.protocol}//${globalThis.location.hostname}:8081/api/uploads/products`;
    } else if (apiFromConfig.endsWith('/api')) {
      productImageBaseUrl = `${apiFromConfig}/uploads/products`;
    } else if (/^https?:\/\/[^/]+:\d+$/.test(apiFromConfig)) {
      productImageBaseUrl = `${apiFromConfig}/api/uploads/products`;
    } else {
      productImageBaseUrl = `${apiFromConfig}/uploads/products`;
    }
    
    return `${productImageBaseUrl}/${img}`;
  }

  // Method to get product image - same as HomeComponent
  getProductImage(product: any): string {
    if (product?.images && product.images.length > 0) {
      // In HomeComponent, images are already base64 strings
      // Return the first image as-is
      const firstImg = product.images[0];
      if (typeof firstImg === 'string') {
        return firstImg;
      }
      // If it's an object with properties, try to extract the image data
      if (typeof firstImg === 'object') {
        return (firstImg as any).url || (firstImg as any).data || (firstImg as any).src || 
               (firstImg as any).path || (firstImg as any).value || '/assets/img/product-3.png';
      }
    }
    return '/assets/img/product-3.png';
  }

  onImageError(event: Event): void {
    const img = event.target as HTMLImageElement;
    if (img && !img.src.includes('product-3.png')) {
      img.src = '/assets/img/product-3.png';
    }
  }

  onImageLoaded(): void {
    // Reinitialize carousel when images are loaded
    setTimeout(() => {
      this.initializeCarousel();
    }, 50);
  }

  loadReviews(): void {
    if (!this.product?.id) return;
    this.reviewService.getByProduct(this.product.id).subscribe({
      next: (r) => this.reviews = r || [],
      error: () => { /* ignore errors for now */ }
    });
  }

  setRating(n: number): void {
    this.selectedRating = n;
  }

  submitReview(): void {
    if (!this.isAuthenticated) {
      this.modalService.showAlert('You must be logged in to submit a rating.', 'Login required');
      return;
    }
    if (!this.selectedRating || this.selectedRating < 1 || this.selectedRating > 5) {
      this.modalService.showAlert('Please select a rating between 1 and 5 stars.', 'Invalid rating');
      return;
    }
    const payload = { rating: this.selectedRating };
    this.reviewService.addReview(this.product.id, payload).subscribe({
      next: () => {
        this.selectedRating = 0;
        this.loadReviews();
        this.productService.getById(this.product.id).subscribe(p => this.product = p);
        this.showSuccessModal();
      },
      error: (err) => this.modalService.showAlert(err.error || err.error?.message || err.message || 'Unable to submit review.', 'Error')
    });
  }

  showSuccessModal(): void {
    const el = document.getElementById('ratingSuccessModal');
    if (!el) return;
    try {
      const modal = (window as any).bootstrap?.Modal?.getOrCreateInstance(el) || (window as any).bootstrap?.Modal?.new(el);
      modal.show();
    } catch (e) {
      // fallback to simple alert modal
      this.modalService.showAlert('Rating submitted successfully', 'Success', 2000);
    }
  }

  private initializeCarousel(): void {
    try {
      window.dispatchEvent(new Event('carousel:refresh'));
      const $ = (window as any).$;
      if ($ && $.fn && typeof $.fn.owlCarousel !== 'undefined') {
        const el = $('.single-carousel');
        if (el && el.length) {
          // Destroy and reinitialize if needed
          if (el.data('owl.carousel')) {
            el.trigger('destroy.owl.carousel');
            el.removeClass('owl-loaded');
          }
          el.owlCarousel({
            items: 1,
            dots: true,
            nav: true,
            loop: true,
            autoplay: true,
            autoplayTimeout: 3000,
            dotsData: true
          });
        }
      }
    } catch (e) {
      console.warn('Could not initialize carousel:', e);
    }
  }
}