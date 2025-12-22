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
  operationInProgress = false;
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
    if (this.alertTimeout) clearTimeout(this.alertTimeout);
    if (this.autoRefreshTimeout) clearTimeout(this.autoRefreshTimeout);
  }

  displayAlert(message: string, type: AlertType = 'info', refreshTarget?: 'categories' | 'products' | 'all') {
    // Alerts are disabled per user request. This function is intentionally a no-op.
    // Kept for compatibility if other code calls it.
  }

  private scheduleCloseAndRefresh(target: 'categories' | 'products' | 'all') {
    // Clear any existing auto-refresh timeouts
    if (this.autoRefreshTimeout) {
      clearTimeout(this.autoRefreshTimeout);
      this.autoRefreshTimeout = undefined;
    }

    // Close modals after 3 seconds
    setTimeout(() => {
      if (target === 'categories' || target === 'all') this.showCategoryModal = false;
      if (target === 'products' || target === 'all') this.showProductModal = false;
      // also ensure loader overlay is hidden once modal is closed
      this.operationInProgress = false;
      this.savingCategory = false;
      this.savingProduct = false;
    }, 3000);

    // Reload page after 4 seconds to reflect backend state
    setTimeout(() => {
      globalThis.location.reload();
    }, 4000);
  }

  closeAlert() {
    if (this.alertTimeout) clearTimeout(this.alertTimeout);
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
    if (!this.categoryFormValid || this.savingCategory) return;

    this.savingCategory = true;
    this.operationInProgress = true;

    const request$ = this.isEditingCategory
      ? this.categoryService.update(this.newCategory.id!, this.newCategory)
      : this.categoryService.create(this.newCategory);

    const sub = request$.pipe(
      timeout(3000),
      catchError(err => throwError(() => err))
    ).subscribe({
      next: () => {
        // Close modal immediately
        this.showCategoryModal = false;
        this.savingCategory = false;
        this.operationInProgress = false;

        this.displayAlert(
          `Category ${this.isEditingCategory ? 'updated' : 'created'} successfully! Refreshing in 3 seconds...`,
          'success',
          'categories'
        );
      },
      error: (err) => {
        this.savingCategory = false;
        this.operationInProgress = false;

        const operation = this.isEditingCategory ? 'updating' : 'creating';
        let errorMsg = 'Unknown error';

        if (err.name === 'TimeoutError') {
          errorMsg = 'Request timed out (3s). Please try again.';
        } else {
          errorMsg = this.extractErrorMessage(err);
        }

        this.displayAlert(`Error ${operation} category: ${errorMsg}`, 'error');
      },
    });
    this.subscriptions.push(sub);
  }

  deleteCategory(id: number) {
    if (!confirm('Delete this category? This cannot be undone.')) return;

    this.operationInProgress = true;

    const sub = this.categoryService.delete(id).pipe(
      timeout(3000),
      catchError(err => throwError(() => err))
    ).subscribe({
      next: () => {
        this.operationInProgress = false;
        this.displayAlert('Category deleted successfully! Refreshing in 3 seconds...', 'success', 'categories');
      },
      error: (err) => {
        this.operationInProgress = false;
        const errorMsg = err.name === 'TimeoutError'
          ? 'Request timed out (3s). Please try again.'
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
          quantity: product.quantity ?? 1,
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
      Number(this.newProduct.price) > 0 &&
      !!this.newProduct.categoryId &&
      Number(this.newProduct.quantity) >= 1;

    const hasImages = this.isEditingProduct
      ? (this.newProduct.images?.length ?? 0) > 0 || this.selectedProductFiles.length > 0
      : this.selectedProductFiles.length > 0;

    this.productFormValid = hasBasics && hasImages;
  }

  onProductFilesSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files) return;

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
    if (!this.productFormValid || this.savingProduct) return;

    this.savingProduct = true;
    this.operationInProgress = true;

    const payload = this.isEditingProduct
      ? this.buildProductUpdatePayload()
      : this.buildProductCreatePayload();

    const request$ = this.isEditingProduct
      ? this.productService.update(this.newProduct.id!, payload)
      : this.productService.create(payload as FormData);

    const sub = request$.pipe(
      timeout(3000),
      catchError(err => throwError(() => err))
    ).subscribe({
      next: () => {
        this.showProductModal = false;
        this.savingProduct = false;
        this.operationInProgress = false;

        this.displayAlert(
          `Product ${this.isEditingProduct ? 'updated' : 'created'} successfully! Refreshing in 3 seconds...`,
          'success',
          'products'
        );
        this.resetProductForm();
      },
      error: (err) => {
        this.savingProduct = false;
        this.operationInProgress = false;

        const operation = this.isEditingProduct ? 'updating' : 'creating';
        let errorMsg = 'Unknown error';

        if (err.name === 'TimeoutError') {
          errorMsg = 'Request timed out (3s). Please try again.';
        } else {
          errorMsg = err.error?.message || err.message || 'Unknown error';
        }

        this.displayAlert(`Error ${operation} product: ${errorMsg}`, 'error');
      },
    });
    this.subscriptions.push(sub);
  }

  deleteProduct(id: number) {
    if (!confirm('Delete this product? This cannot be undone.')) return;

    this.operationInProgress = true;

    const sub = this.productService.delete(id).pipe(
      timeout(3000),
      catchError(err => throwError(() => err))
    ).subscribe({
      next: () => {
        this.operationInProgress = false;
        this.displayAlert('Product deleted successfully! Refreshing in 3 seconds...', 'success', 'products');
      },
      error: (err) => {
        this.operationInProgress = false;
        const errorMsg = err.name === 'TimeoutError'
          ? 'Request timed out (3s). Please try again.'
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
    return this.categories.find(c => c.id === catId)?.name || 'N/A';
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
    formData.append('name', this.newProduct.name.trim());
    formData.append('description', this.newProduct.description.trim());
    formData.append('price', this.newProduct.price.toString());
    formData.append('categoryId', String(this.newProduct.categoryId));
    
    // Ensure quantity is properly converted to string
    const quantity = Number(this.newProduct.quantity) || 1;
    formData.append('quantity', quantity.toString());
    
    if (this.newProduct.review) formData.append('review', this.newProduct.review.trim());
    this.selectedProductFiles.forEach(file => formData.append('images', file, file.name));
    return formData;
  }

  private buildProductUpdatePayload(): Product {
    const images = (this.newProduct.images ?? []).filter(img => img?.trim());
    
    // Ensure quantity is properly parsed as a number
    const quantity = Number(this.newProduct.quantity) || 1;
    
    return {
      id: this.newProduct.id,
      name: this.newProduct.name.trim(),
      description: this.newProduct.description.trim(),
      price: Number(this.newProduct.price),
      quantity: quantity,
      review: this.newProduct.review?.trim() || '',
      images: images.length ? images : ['placeholder.jpg'],
      rate: this.newProduct.rate ?? 0,
      categoryId: this.newProduct.categoryId,
      categoryName: this.newProduct.categoryName || undefined
    };
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
    if (this.autoRefreshTimeout) clearTimeout(this.autoRefreshTimeout);

    // Show the overlay and perform a full page reload after 3 seconds
    this.autoRefreshPending = true;
    this.autoRefreshTimeout = setTimeout(() => {
      this.autoRefreshPending = false;
      this.autoRefreshTimeout = undefined;
      // Full reload ensures the UI and any caches are consistent after backend changes
      globalThis.location.reload();
    }, 3000);
  }

  private extractErrorMessage(err: any): string {
    if (err?.error) {
      if (typeof err.error === 'string') return err.error;
      if (err.error.message) return err.error.message;
      if (typeof err.error === 'object') return JSON.stringify(err.error);
    }
    return err?.message || 'Unknown error';
  }
  // Add this method to your component class, right after the existing methods:

updateQuantity(value: any) {
  // Convert the value to a number, default to 1 if invalid
  const numValue = Number(value);
  this.newProduct.quantity = isNaN(numValue) || numValue < 1 ? 1 : numValue;
  this.validateProductForm();
}
}