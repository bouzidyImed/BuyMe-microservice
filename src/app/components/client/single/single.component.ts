import { Component, OnInit, Inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../../services/product.service';
import { CartService } from '../../../services/cart.service';
import { ReviewService } from '../../../services/review.service';
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
  private readonly productImageBaseUrl: string;
  discountPercent = 0;

  constructor(
    private route: ActivatedRoute,
    private productService: ProductService,
    private cartService: CartService,
    private router: Router,
    private reviewService: ReviewService,
    @Inject(APP_CONFIG) private config: any
  ) {
    const apiFromConfig: string = (this.config?.apiUrl || '').replace(/\/$/, '');
    if (apiFromConfig.includes('api-gateway')) {
      this.productImageBaseUrl = `${globalThis.location.protocol}//${globalThis.location.hostname}:8081/api/uploads/products`;
    } else if (apiFromConfig.endsWith('/api')) {
      this.productImageBaseUrl = `${apiFromConfig}/uploads/products`;
    } else if (/^https?:\/\/[^/]+:\d+$/.test(apiFromConfig)) {
      this.productImageBaseUrl = `${apiFromConfig}/api/uploads/products`;
    } else {
      this.productImageBaseUrl = `${apiFromConfig}/uploads/products`;
    }
  }

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

        // CRITICAL: Trigger Owl Carousel re-initialization via global event
        // This tells main.js to initialize new carousels. Also attempt jQuery trigger if available.
        setTimeout(() => {
          try {
            window.dispatchEvent(new Event('carousel:refresh'));
            const $ = (window as any).$;
            if ($ && $.fn && typeof $.fn.owlCarousel !== 'undefined') {
              // refresh owl carousel instances if present
              const el = $('.single-carousel');
              if (el && el.length) {
                try { el.trigger('refresh.owl.carousel'); } catch (e) { /* ignore */ }
              }
            }
          } catch (e) {
            // ignore
          }
        }, 500);
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
      alert('Cannot add to cart: requested quantity exceeds available stock.');
      return;
    }

    // Keep stored item prices as the original product price; discounts are applied at totals/checkout.
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

  getImageUrl(img: string): string {
    if (!img) return '/assets/img/product-3.png';
    try {
      // if the image value is an object (sometimes API returns objects), try common fields
      if (typeof img === 'object' && img !== null) {
        const obj: any = img as any;
        const candidate = obj.url || obj.path || obj.src || obj.data || obj.value;
        if (candidate) return this.getImageUrl(String(candidate));
      }
      // if already a data URL or absolute URL or root-relative, return as-is
      if (typeof img === 'string') {
        if (img.startsWith('data:') || img.startsWith('http') || img.startsWith('/')) return img;
      }
    } catch (e) {
      return '/assets/img/product-3.png';
    }
    return `${this.productImageBaseUrl}/${img}`;
  }

  getProductImage(product: any): string {
    if (product?.images && product.images.length > 0) {
      return this.getImageUrl(product.images[0]);
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
    try {
      window.dispatchEvent(new Event('carousel:refresh'));
      const $ = (window as any).$;
      if ($ && $.fn && typeof $.fn.owlCarousel !== 'undefined') {
        const el = $('.single-carousel');
        if (el && el.length) {
          try { el.trigger('refresh.owl.carousel'); } catch (e) { /* ignore */ }
        }
      }
    } catch (e) {
      // ignore
    }
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
      alert('You must be logged in to submit a rating.');
      return;
    }
    if (!this.selectedRating || this.selectedRating < 1 || this.selectedRating > 5) {
      alert('Please select a rating between 1 and 5 stars.');
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
      error: (err) => alert(err.error || err.error?.message || err.message || 'Unable to submit review.')
    });
  }

  showSuccessModal(): void {
    const el = document.getElementById('ratingSuccessModal');
    if (!el) return;
    try {
      const modal = (window as any).bootstrap?.Modal?.getOrCreateInstance(el) || (window as any).bootstrap?.Modal?.new(el);
      modal.show();
    } catch (e) {
      // fallback to simple alert
      alert('Rating submitted successfully');
    }
  }
}