import { Component, Inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../../services/product.service';
import { CartService } from '../../../services/cart.service';
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
  private productImageBaseUrl: string;

  constructor(
    private route: ActivatedRoute,
    private productService: ProductService,
    private cartService: CartService,
    private router: Router,
    @Inject(APP_CONFIG) private config: any
  ) {
    const apiFromConfig: string = (config?.apiUrl || '').replace(/\/$/, '');
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
    if (!id) {
      this.error = 'Invalid product id';
      this.loading = false;
      return;
    }
    this.productService.getById(id).subscribe({
      next: (p) => { this.product = p; this.loading = false; },
      error: (err) => { this.error = err.error?.message || err.message || 'Unable to load product.'; this.loading = false; }
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
    this.cartService.addToCartProduct({ id: this.product.id, name: this.product.name, price: this.product.price, images: this.product.images, stock: this.product.quantity }, this.quantity);
    // Reset quantity to 1 for UX
    this.quantity = 1;
  }

  navigateToCart() {
    this.router.navigate(['/client/cart']);
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

  getImageUrl(img?: string): string {
    if (img) return `${this.productImageBaseUrl}/${img}`;
    return '/assets/img/product-3.png';
  }

  onImageError(event: Event) {
    const img = event.target as HTMLImageElement;
    if (img && !img.src.includes('/assets/img/product-3.png')) {
      img.src = '/assets/img/product-3.png';
    }
  }

  
}
