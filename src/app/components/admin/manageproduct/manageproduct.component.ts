import { Component, OnDestroy, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { timeout, catchError } from 'rxjs/operators';
import { throwError, Subscription } from 'rxjs';
import { ProductService } from '../../../services/product.service';
import { CategoryService } from '../../../services/category.service';

type AlertType = 'success' | 'error' | 'info';

interface Category {
  id: number | null;
  name: string;
  description: string;
}

interface Product {
  id: number | null;
  name: string;
  description: string;
  price: number;
  quantity: number;
  review?: string;
  images?: string[];
  rate?: number;
  categoryId: number | null;
  categoryName?: string;
}

@Component({
  selector: 'app-manageproduct',
  standalone: true,
  templateUrl: './manageproduct.component.html',
  styleUrls: ['./manageproduct.component.css'],
  imports: [CommonModule, FormsModule]
})
export class ManageproductComponent implements OnInit, OnDestroy {
  autoRefreshPending = false;
  products: Product[] = [];
  categories: Category[] = [];

  newCategory: Category = this.getEmptyCategory();
  newProduct: Product = this.getEmptyProduct();
  selectedProductFiles: File[] = [];
  productImagePreviews: string[] = [];

  showCategoryModal = false;
  showProductModal = false;
  isEditingCategory = false;
  isEditingProduct = false;
  categoryFormValid = false;
  productFormValid = false;
  categorySearchTerm = '';
  productSearchTerm = '';

  categoriesLoading = false;
  productsLoading = false;
  savingCategory = false;
  savingProduct = false;

  alertMessage = '';
  alertType: AlertType = 'info';
  showAlert = false;
  private alertTimeout?: ReturnType<typeof setTimeout>;
  private autoRefreshTimeout?: ReturnType<typeof setTimeout>;
  private subscriptions: Subscription[] = [];

  activeSection: 'categories' | 'products' = 'categories';

  constructor(
    private productService: ProductService,
    private categoryService: CategoryService
  ) {}

  ngOnInit(): void {
    this.loadCategories();
    this.loadProducts();
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
    if (this.alertTimeout) {
      clearTimeout(this.alertTimeout);
    }
    if (this.autoRefreshTimeout) {
      clearTimeout(this.autoRefreshTimeout);
    }
  }

  displayAlert(message: string, type: AlertType = 'info', refreshTarget?: 'categories' | 'products' | 'all') {
    if (this.alertTimeout) {
      clearTimeout(this.alertTimeout);
    }
    this.alertMessage = message;
    this.alertType = type;
    this.showAlert = true;
    this.alertTimeout = setTimeout(() => this.showAlert = false, 4500);
    if (refreshTarget) {
      this.scheduleAutoRefresh(refreshTarget);
    }
  }

  closeAlert() {
    if (this.alertTimeout) {
      clearTimeout(this.alertTimeout);
    }
    this.showAlert = false;
  }

  /* ========= CATEGORY CRUD ========= */
  loadCategories(showLoader: boolean = true) {
    this.categoriesLoading = showLoader;
    const sub = this.categoryService.getAll().subscribe({
      next: (res) => {
        this.categories = res ?? [];
        this.categoriesLoading = false;
      },
      error: (err) => {
        this.categoriesLoading = false;
        this.displayAlert('Error loading categories: ' + (err.message || 'Unknown error'), 'error');
      },
    });
    this.subscriptions.push(sub);
  }

  openCategoryModal(category?: Category) {
    this.isEditingCategory = !!category;
    this.newCategory = category ? { ...category } : this.getEmptyCategory();
    this.savingCategory = false;
    this.showCategoryModal = true;
    this.validateCategoryForm();
  }

  validateCategoryForm() {
    this.categoryFormValid = !!this.newCategory.name.trim() && !!this.newCategory.description.trim();
  }

  saveCategory() {
    if (!this.categoryFormValid || this.savingCategory) {
      return;
    }

    this.savingCategory = true;
    const request$ = this.isEditingCategory
      ? this.categoryService.update(this.newCategory.id!, this.newCategory)
      : this.categoryService.create(this.newCategory);

    const sub = request$.pipe(
      timeout(30000),
      catchError(err => throwError(() => err))
    ).subscribe({
      next: () => {
        this.showCategoryModal = false;
        this.savingCategory = false;
        this.displayAlert(
          `Category ${this.isEditingCategory ? 'updated' : 'created'} successfully! Refreshing in 3 seconds...`,
          'success',
          'categories'
        );
      },
      error: (err) => {
        this.savingCategory = false;
        const operation = this.isEditingCategory ? 'updating' : 'creating';
        const errorMsg = err.name === 'TimeoutError'
          ? 'Request timeout (30s) – backend is slow; operation may still succeed (refresh to verify).'
          : this.extractErrorMessage(err);
        this.displayAlert(`Error ${operation} category: ${errorMsg}`, 'error');
      },
    });
    this.subscriptions.push(sub);
  }

  deleteCategory(id: number) {
    if (!confirm('Delete this category? This cannot be undone.')) {
      return;
    }
    const sub = this.categoryService.delete(id).pipe(
      timeout(30000),
      catchError(err => throwError(() => err))
    ).subscribe({
      next: () => {
        this.displayAlert('Category deleted successfully! Refreshing in 3 seconds...', 'success', 'categories');
      },
      error: (err) => {
        const errorMsg = err.name === 'TimeoutError'
          ? 'Request timeout (30s) – backend is slow; operation may still succeed (refresh to verify).'
          : this.extractErrorMessage(err);
        this.displayAlert(`Error deleting category: ${errorMsg}`, 'error');
      }
    });
    this.subscriptions.push(sub);
  }

  /* ========= PRODUCT CRUD ========= */
  loadProducts(showLoader: boolean = true) {
    this.productsLoading = showLoader;
    const sub = this.productService.getAll().subscribe({
      next: (res) => {
        this.products = res ?? [];
        this.productsLoading = false;
      },
      error: (err) => {
        this.productsLoading = false;
        this.displayAlert('Error loading products: ' + (err.message || 'Unknown error'), 'error');
      },
    });
    this.subscriptions.push(sub);
  }

  openProductModal(product?: Product) {
    this.isEditingProduct = !!product;
    this.newProduct = product
      ? {
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          quantity: product.quantity ?? 0,
          review: product.review ?? '',
          images: [...(product.images ?? [])],
          rate: product.rate ?? 0,
          categoryId: product.categoryId ?? null,
          categoryName: product.categoryName
        }
      : this.getEmptyProduct();

    this.selectedProductFiles = [];
    this.productImagePreviews = [];
    this.savingProduct = false;
    this.showProductModal = true;
    this.validateProductForm();
  }

  validateProductForm() {
    const hasBasics = !!this.newProduct.name.trim() &&
      !!this.newProduct.description.trim() &&
      this.newProduct.price > 0 &&
      !!this.newProduct.categoryId &&
      this.toPositiveQuantity(this.newProduct.quantity) > 0;

    const hasImages = this.isEditingProduct
      ? (this.newProduct.images?.length ?? 0) > 0 || this.selectedProductFiles.length > 0
      : this.selectedProductFiles.length > 0;

    this.productFormValid = hasBasics && hasImages;
  }

  onProductFilesSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files) {
      return;
    }
    this.selectedProductFiles = Array.from(input.files);
    this.productImagePreviews = [];
    this.selectedProductFiles.forEach(file => {
      const reader = new FileReader();
      reader.onload = () => this.productImagePreviews.push(reader.result as string);
      reader.readAsDataURL(file);
    });
    this.validateProductForm();
  }

  removeImageChip(index: number, existing: boolean) {
    if (existing && this.newProduct.images) {
      this.newProduct.images.splice(index, 1);
    } else {
      this.selectedProductFiles.splice(index, 1);
      this.productImagePreviews.splice(index, 1);
    }
    this.validateProductForm();
  }

  saveProduct() {
    if (!this.productFormValid || this.savingProduct) {
      return;
    }

    this.savingProduct = true;
    const payload = this.isEditingProduct
      ? this.buildProductUpdatePayload()
      : this.buildProductCreatePayload();

    const request$ = this.isEditingProduct
      ? this.productService.update(this.newProduct.id!, payload).pipe(
          timeout(30000),
          catchError(err => throwError(() => err))
        )
      : this.productService.create(payload as FormData).pipe(
          timeout(30000),
          catchError(err => throwError(() => err))
        );

    const sub = request$.subscribe({
      next: () => {
        this.showProductModal = false;
        this.savingProduct = false;
        this.displayAlert(
          `Product ${this.isEditingProduct ? 'updated' : 'created'} successfully! Refreshing in 3 seconds...`,
          'success',
          'products'
        );
        this.resetProductForm();
      },
      error: (err) => {
        this.savingProduct = false;
        const operation = this.isEditingProduct ? 'updating' : 'creating';
        const errorMsg = err.error?.message || err.message || JSON.stringify(err) || 'Unknown error';
        this.displayAlert(`Error ${operation} product: ${errorMsg}`, 'error');
        console.error('PUT/POST error for product:', err, errorMsg);
      },
    });
    this.subscriptions.push(sub);
  }

  deleteProduct(id: number) {
    if (!confirm('Delete this product? This cannot be undone.')) {
      return;
    }
    const sub = this.productService.delete(id).pipe(
      timeout(30000),
      catchError(err => throwError(() => err))
    ).subscribe({
      next: () => {
        this.displayAlert('Product deleted successfully! Refreshing in 3 seconds...', 'success', 'products');
      },
      error: (err) => {
        const errorMsg = err.name === 'TimeoutError'
          ? 'Request timeout (30s) – backend is slow; operation may still succeed (refresh to verify).'
          : this.extractErrorMessage(err);
        this.displayAlert(`Error deleting product: ${errorMsg}`, 'error');
      }
    });
    this.subscriptions.push(sub);
  }

  /* ========= HELPERS ========= */
  filteredCategories(): Category[] {
    const term = this.categorySearchTerm.trim().toLowerCase();
    if (!term) return this.categories;
    return this.categories.filter(cat =>
      cat.name.toLowerCase().includes(term) ||
      cat.description.toLowerCase().includes(term)
    );
  }

  filteredProducts(): Product[] {
    const term = this.productSearchTerm.trim().toLowerCase();
    if (!term) return this.products;
    return this.products.filter(prod =>
      prod.name.toLowerCase().includes(term) ||
      prod.description.toLowerCase().includes(term) ||
      (prod.categoryName?.toLowerCase().includes(term) ?? false)
    );
  }

  getCategoryName(catId: number) {
    return this.categories.find((c) => c.id === catId)?.name || 'N/A';
  }

  setSection(section: 'categories' | 'products') {
    this.activeSection = section;
  }

  refreshAll() {
    this.loadCategories();
    this.loadProducts();
  }

  private buildProductCreatePayload(): FormData {
    const formData = new FormData();
    const quantity = this.toPositiveQuantity(this.newProduct.quantity);
    formData.append('name', this.newProduct.name.trim());
    formData.append('description', this.newProduct.description.trim());
    formData.append('price', this.newProduct.price.toString());
    formData.append('categoryId', String(this.newProduct.categoryId));
    formData.append('quantity', quantity.toString());
    if (this.newProduct.review) {
      formData.append('review', this.newProduct.review.trim());
    }
    this.selectedProductFiles.forEach(file => formData.append('images', file, file.name));
    return formData;
  }

  private buildProductUpdatePayload(): Product {
    const images = (this.newProduct.images ?? []).filter((img): img is string => !!img && img.trim().length > 0);
    if (!images.length) {
      // No image would be a backend validation error
      images.push('placeholder.jpg'); // Optionally signal error if you have a fallback
    }
    const payload = {
      id: this.newProduct.id,
      name: this.newProduct.name.trim(),
      description: this.newProduct.description.trim(),
      price: Number(this.newProduct.price),
      quantity: this.toPositiveQuantity(this.newProduct.quantity),
      review: this.newProduct.review?.trim() || '',
      images,
      rate: this.newProduct.rate ?? 0,
      categoryId: this.newProduct.categoryId,
      categoryName: this.newProduct.categoryName || undefined
    };
    console.log('PUT update payload:', payload);
    return payload;
  }

  private resetProductForm() {
    this.newProduct = this.getEmptyProduct();
    this.selectedProductFiles = [];
    this.productImagePreviews = [];
    this.productFormValid = false;
  }

  private getEmptyCategory(): Category {
    return { id: null, name: '', description: '' };
  }

  private getEmptyProduct(): Product {
    return {
      id: null,
      name: '',
      description: '',
      price: 0,
      quantity: 1,
      review: '',
      images: [],
      rate: 0,
      categoryId: null
    };
  }

  private scheduleAutoRefresh(target: 'categories' | 'products' | 'all') {
    if (this.autoRefreshTimeout) {
      clearTimeout(this.autoRefreshTimeout);
    }
    this.autoRefreshPending = true;
    this.autoRefreshTimeout = setTimeout(() => {
      this.autoRefreshPending = false;
      this.autoRefreshTimeout = undefined;
      globalThis.location.reload();
    }, 3000);
  }

  private toPositiveQuantity(value: number | null | undefined): number {
    const numeric = Number(value);
    if (Number.isFinite(numeric) && numeric > 0) {
      return Math.floor(numeric);
    }
    return 1;
  }

  private extractErrorMessage(err: any): string {
    if (err?.error) {
      if (typeof err.error === 'string') {
        return err.error;
      }
      if (err.error.message) {
        return err.error.message;
      }
    }
    return err?.message || 'Unknown error';
  }
}