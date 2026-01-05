import { Component, Inject, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { forkJoin } from 'rxjs';
import { CategoryService } from '../../../services/category.service';
import { ProductService } from '../../../services/product.service';
import { CartService, CartItem } from '../../../services/cart.service';
import { RecommenderService } from '../../../services/recommender.service';
import { UserService } from '../../../services/user.service';
import { CustomerSegmentationService, Promotion } from '../../../services/customer-segmentation.service';
import { APP_CONFIG } from '../../../../main';

interface Category {
  id: number;
  name: string;
  description: string;
}

interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  quantity: number;
  images?: string[];
  categoryId: number;
  categoryName?: string;
  rate?: number;
}

interface CategoryGroup {
  category: Category;
  products: Product[];
}

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css'
})
export class HomeComponent implements OnInit, OnDestroy {
  cartProductIds = new Set<number>();

  navigateToProfile() {
    this.router.navigate(['/client/profile']);
  }

  logout() {
    try {
      // clear auth-related storage and navigate to login
      localStorage.removeItem('authToken');
      localStorage.removeItem('currentUser');
    } catch (e) {
      // ignore
    }
    this.router.navigate(['/login']);
  }

  categoriesWithProducts: CategoryGroup[] = [];
  allProducts: Product[] = [];
  loading = true;
  error: string | null = null;
  selectedCategoryId: number | 'all' = 'all';
  private readonly productImageBaseUrl: string;
  
  // Recommendations and Segmentation
  recommendedProducts: Product[] = [];
  loadingRecommendations = false;
  customerPromotions: Promotion[] = [];
  userDisplayName: string | null = null;
  loadingPromotions = false;
  currentPromotion: Promotion | null = null;
  discountPercent = 0;
  currentRecommendationIndex = 0;
  currentPromotionIndex = 0;
  promotionRotationInterval: any = null;
  recommendationRotationInterval: any = null;
  recommendationFade = true;


  constructor(
    private readonly categoryService: CategoryService,
    private readonly productService: ProductService,
    private readonly cartService: CartService,
    private readonly recommenderService: RecommenderService,
    private readonly userService: UserService,
    private readonly segmentationService: CustomerSegmentationService,
    private readonly router: Router,
    @Inject(APP_CONFIG) config: any
  ) {
    const apiFromConfig: string = (config?.apiUrl || '').replace(/\/$/, '');
    if (apiFromConfig.includes('api-gateway')) {
      // When running locally (not docker), the hostname 'api-gateway' may not resolve from the browser.
      // Use the local host and API gateway port so images load during local dev.
      this.productImageBaseUrl = `${globalThis.location.protocol}//${globalThis.location.hostname}:8081/api/uploads/products`;
    } else if (apiFromConfig.endsWith('/api')) {
      this.productImageBaseUrl = `${apiFromConfig}/uploads/products`;
    } else if (/^https?:\/\/[^/]+:\d+$/.test(apiFromConfig)) {
      // host:port without /api
      this.productImageBaseUrl = `${apiFromConfig}/api/uploads/products`;
    } else {
      this.productImageBaseUrl = `${apiFromConfig}/uploads/products`;
    }
  }

  onImageError(event: Event) {
    const img = event.target as HTMLImageElement;
    if (img && !img.src.includes('/assets/img/default-avatar.png')) {
      img.src = '/assets/img/product-3.png';
    }
  }

  ngOnInit(): void {
    // Determine display name early for promotions
    try {
      const token = localStorage.getItem('jwt_token') || '';
      if (token) {
        const parts = token.split('.');
        if (parts.length >= 2) {
          const payloadJson = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
          this.userDisplayName = payloadJson.preferred_username || payloadJson.name || payloadJson.email || null;
        }
      }
    } catch (e) {
      this.userDisplayName = null;
    }
    this.fetchCatalogue();
    // keep an updated set of product ids currently in the cart
    this.cartService.items$.subscribe((items: CartItem[]) => {
      this.cartProductIds.clear();
      for (const it of items) {
        this.cartProductIds.add(it.productId);
      }
      // Fetch recommendations when cart updates (based on user history)
      // Wait a bit to ensure products are loaded
      setTimeout(() => {
        if (this.allProducts.length > 0) {
          this.fetchRecommendations();
        }
      }, 500);
    });
    
    // Fetch promotions immediately
    this.fetchCustomerSegmentation();
  }

  getProductImage(product: Product): string {
    if (product.images && product.images.length > 0) {
      return product.images[0]; // now this is already "data:image/jpeg;base64,..."
    }
    return '/assets/img/product-3.png';
  }
  trackByCategory(_: number, group: CategoryGroup) {
    return group.category.id;
  }

  trackByProduct(_: number, product: Product) {
    return product.id;
  }

  selectCategory(categoryId: number | 'all'): void {
    this.selectedCategoryId = categoryId;
  }

  getProductsForActiveTab(): Product[] {
    if (this.selectedCategoryId === 'all') {
      return this.allProducts;
    }
    const group = this.categoriesWithProducts.find(g => g.category.id === this.selectedCategoryId);
    return group ? group.products : [];
  }

  cardAnimationDelay(index: number): string {
    const step = (index % 4) * 0.2;
    return `${0.1 + step}s`;
  }

  isInCart(product: Product): boolean {
    return this.cartProductIds.has(product.id);
  }

  addToCart(product: Product): void {
    const items = this.cartService.getItems();
    const existing = items.find(i => i.productId === product.id);
    const existingQty = existing ? existing.quantity : 0;
    // validate against stock
    const available = product.quantity ?? 0;
    if (existingQty + 1 > available) {
      alert('Cannot add to cart: requested quantity exceeds available stock.');
      return;
    }

    // include stock so cart keeps track of limits
    this.cartService.addToCartProduct({ id: product.id, name: product.name, price: product.price, images: product.images, stock: available }, 1);
    console.log('Product added to cart:', product.id);
  }

  applyPromotion(promo: Promotion | null): void {
    if (!promo) return;
    const target = this.userDisplayName || promo.customer_id || '';
    const pct = (promo as any).discount_percent ?? (promo as any).discount ?? 0;
    const msg = pct ? `Applied ${pct}% discount for ${target}` : `Promotion for ${target}`;
    // For now show a simple confirmation — integrators can wire this to checkout/coupon logic
    alert(msg);
  }

  private fetchCatalogue(): void {
    this.loading = true;
    forkJoin({
      categories: this.categoryService.getAll(),
      products: this.productService.getAll()
    }).subscribe({
      next: ({ categories, products }) => {
        // include all products (show out-of-stock items too) so categories display even when stock is zero
        const availableProducts = (products ?? []);
        const grouped: CategoryGroup[] = (categories ?? [])
          .map((category) => ({
            category,
            products: availableProducts
              .filter(p => p.categoryId === category.id)
              .sort((a, b) => a.name.localeCompare(b.name))
          }))
          .filter(group => group.products.length > 0)
          .sort((a, b) => a.category.name.localeCompare(b.category.name));

        this.categoriesWithProducts = grouped;
        this.allProducts = grouped
          .flatMap(group => group.products.map(product => ({
            ...product,
            categoryName: group.category.name
          })))
          .sort((a, b) => {
            if (a.categoryName === b.categoryName) {
              return a.name.localeCompare(b.name);
            }
            return (a.categoryName || '').localeCompare(b.categoryName || '');
          });

        if (!grouped.length) {
          this.selectedCategoryId = 'all';
        } else if (this.selectedCategoryId !== 'all') {
          const exists = grouped.some(group => group.category.id === this.selectedCategoryId);
          if (!exists) {
            this.selectedCategoryId = 'all';
          }
        }

        this.loading = false;
        // After products are loaded, fetch recommendations
        // Use setTimeout to ensure DOM is ready
        setTimeout(() => {
          this.fetchRecommendations();
        }, 300);
      },
      error: (err) => {
        this.error = err.error?.message || err.message || 'Unable to load catalogue.';
        this.loading = false;
      }
    });
  }

  private fetchRecommendations(): void {
    if (this.loadingRecommendations || this.allProducts.length === 0) {
      return;
    }
    
    this.loadingRecommendations = true;
    
    // Get user's cart history (product IDs they've interacted with)
    const cartItems = this.cartService.getItems();
    const history = cartItems.map(item => item.productId);
    
    // Try to include current user id to improve personalization. If fetching user fails,
    // fall back to anonymous recommendations.
    this.userService.getCurrentUser().subscribe({
      next: (user) => {
        const userId = user?.id;
        this.recommenderService.getRecommendations(history, 5, userId).subscribe({
            next: (response) => {
            const recommendedIds = response.recommendations || [];
            // Map product IDs to full product objects (compare as strings)
            this.recommendedProducts = recommendedIds
              .map((id: any) => this.allProducts.find(p => String(p.id) === String(id)))
              .filter((p: Product | undefined): p is Product => p !== undefined)
              .slice(0, 5);
            this.loadingRecommendations = false;
            // start auto-rotation
            this.recommendationFade = true;
            this.startRecommendationRotation();
          },
          error: (err) => {
            console.error('[Home] personalized recommendations failed', { history, userId, error: err });
            this.recommendedProducts = [];
            this.loadingRecommendations = false;
            this.error = 'Unable to load personalized recommendations.';
          }
        });
      },
      error: () => {
        // fallback: anonymous recommendations
        this.recommenderService.getRecommendations(history, 5).subscribe({
            next: (response) => {
            const recommendedIds = response.recommendations || [];
            this.recommendedProducts = recommendedIds
              .map((id: any) => this.allProducts.find(p => String(p.id) === String(id)))
              .filter((p: Product | undefined): p is Product => p !== undefined)
              .slice(0, 5);
            this.loadingRecommendations = false;
            this.recommendationFade = true;
            this.startRecommendationRotation();
          },
          error: (err) => {
            console.error('[Home] anonymous recommendations failed', { history, error: err });
            this.recommendedProducts = [];
            this.loadingRecommendations = false;
            this.error = 'Unable to load recommendations.';
          }
        });
      }
    });
  }

  fetchCustomerSegmentation(): void {
    if (this.loadingPromotions) {
      return;
    }
    
    this.loadingPromotions = true;
    
    this.segmentationService.runSegmentation({ n_clusters: 3, send: false }).subscribe({
      next: (response) => {
        this.customerPromotions = (response.promotions || []).map((p: any) => ({
          ...p,
          display_name: this.userDisplayName || p.customer_id
        }));
        // Set the first promotion as current (or a random one)
        if (this.customerPromotions.length > 0) {
          this.currentPromotion = this.customerPromotions[0];
          this.currentPromotionIndex = 0;
          // capture discount percent and store to cart service
          const pct = Number((this.currentPromotion as any).discount_percent ?? (this.currentPromotion as any).discount ?? 0) || 0;
          this.discountPercent = pct;
          try { this.cartService.setDiscountPercent(pct); } catch (e) { /* ignore if service not available */ }
          // Start auto-rotating promotions
          this.startPromotionRotation();
        }
        this.loadingPromotions = false;
      },
      error: (err) => {
        console.error('[Home] fetchCustomerSegmentation failed', { payload: { n_clusters: 3, send: false }, error: err });
        // Service already handles errors gracefully, but just in case
        this.customerPromotions = [];
        this.currentPromotion = null;
        this.loadingPromotions = false;
        this.error = 'Unable to load customer promotions.';
      }
    });
  }

  // Navigation methods for recommendations carousel
  nextRecommendation(): void {
    if (this.recommendedProducts.length > 0) {
      this.recommendationFade = false;
      setTimeout(() => {
        this.currentRecommendationIndex = (this.currentRecommendationIndex + 1) % this.recommendedProducts.length;
        this.recommendationFade = true;
      }, 160);
    }
  }

  previousRecommendation(): void {
    if (this.recommendedProducts.length > 0) {
      this.recommendationFade = false;
      setTimeout(() => {
        this.currentRecommendationIndex = (this.currentRecommendationIndex - 1 + this.recommendedProducts.length) % this.recommendedProducts.length;
        this.recommendationFade = true;
      }, 160);
    }
  }

  goToRecommendation(index: number): void {
    if (index >= 0 && index < this.recommendedProducts.length) {
      this.recommendationFade = false;
      setTimeout(() => {
        this.currentRecommendationIndex = index;
        this.recommendationFade = true;
      }, 120);
    }
  }

  getCurrentRecommendation(): Product | null {
    if (this.recommendedProducts.length > 0 && this.currentRecommendationIndex < this.recommendedProducts.length) {
      return this.recommendedProducts[this.currentRecommendationIndex];
    }
    return null;
  }

  // Navigation methods for promotions
  nextPromotion(): void {
    if (this.customerPromotions.length > 0) {
      this.currentPromotionIndex = (this.currentPromotionIndex + 1) % this.customerPromotions.length;
      this.currentPromotion = this.customerPromotions[this.currentPromotionIndex];
    }
  }

  previousPromotion(): void {
    if (this.customerPromotions.length > 0) {
      this.currentPromotionIndex = (this.currentPromotionIndex - 1 + this.customerPromotions.length) % this.customerPromotions.length;
      this.currentPromotion = this.customerPromotions[this.currentPromotionIndex];
    }
  }

  startRecommendationRotation(): void {
    if (this.recommendationRotationInterval) {
      clearInterval(this.recommendationRotationInterval);
    }
    if (this.recommendedProducts.length > 1) {
      this.recommendationRotationInterval = setInterval(() => {
        this.nextRecommendation();
      }, 5000);
    }
  }

  stopRecommendationRotation(): void {
    if (this.recommendationRotationInterval) {
      clearInterval(this.recommendationRotationInterval);
      this.recommendationRotationInterval = null;
    }
  }

  goToPromotion(index: number): void {
    if (index >= 0 && index < this.customerPromotions.length) {
      this.currentPromotionIndex = index;
      this.currentPromotion = this.customerPromotions[index];
    }
  }

  startPromotionRotation(): void {
    // Clear existing interval
    if (this.promotionRotationInterval) {
      clearInterval(this.promotionRotationInterval);
    }
    // Auto-rotate promotions every 5 seconds
    if (this.customerPromotions.length > 1) {
      this.promotionRotationInterval = setInterval(() => {
        this.nextPromotion();
      }, 5000);
    }
  }

  stopPromotionRotation(): void {
    if (this.promotionRotationInterval) {
      clearInterval(this.promotionRotationInterval);
      this.promotionRotationInterval = null;
    }
  }

  ngOnDestroy(): void {
    this.stopPromotionRotation();
    this.stopRecommendationRotation();
  }
}