import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { ProductService } from '../../../services/product.service';
import { CartService } from '../../../services/cart.service';

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

  constructor(
    private route: ActivatedRoute,
    private productService: ProductService,
    private cartService: CartService,
    private router: Router
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

        // CRITICAL: Trigger Owl Carousel re-initialization via global event
        // This tells main.js to initialize new carousels
        setTimeout(() => {
          // Dispatch a custom event that main.js can listen for
          window.dispatchEvent(new Event('carousel:refresh'));
        }, 300);
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
    localStorage.removeItem('authToken');
    localStorage.removeItem('currentUser');
    this.router.navigate(['/login']);
  }

  getImageUrl(img: string): string {
    return img || '/assets/img/product-3.png';
  }

  onImageError(event: Event): void {
    const img = event.target as HTMLImageElement;
    if (img && !img.src.includes('product-3.png')) {
      img.src = '/assets/img/product-3.png';
    }
  }
}