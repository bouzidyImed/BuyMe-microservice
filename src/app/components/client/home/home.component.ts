import { Component, Inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { forkJoin } from 'rxjs';
import { CategoryService } from '../../../services/category.service';
import { ProductService } from '../../../services/product.service';
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
  imports: [CommonModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css'
})
export class HomeComponent implements OnInit {
  // ...existing code...

  navigateToProfile() {
    this.router.navigate(['/client/profile']);
  }

  categoriesWithProducts: CategoryGroup[] = [];
  allProducts: Product[] = [];
  loading = true;
  error: string | null = null;
  selectedCategoryId: number | 'all' = 'all';
  private readonly productImageBaseUrl: string;


  constructor(
    private readonly categoryService: CategoryService,
    private readonly productService: ProductService,
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
    this.fetchCatalogue();
  }

  getProductImage(product: Product): string {
    if (product.images && product.images.length > 0) {
      return `${this.productImageBaseUrl}/${product.images[0]}`;
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

  private fetchCatalogue(): void {
    this.loading = true;
    forkJoin({
      categories: this.categoryService.getAll(),
      products: this.productService.getAll()
    }).subscribe({
      next: ({ categories, products }) => {
        const availableProducts = (products ?? []).filter(p => (p.quantity ?? 0) > 0);
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
      },
      error: (err) => {
        this.error = err.error?.message || err.message || 'Unable to load catalogue.';
        this.loading = false;
      }
    });
  }

}
