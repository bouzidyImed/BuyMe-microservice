import { Component, OnDestroy, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { timeout, catchError } from 'rxjs/operators';
import { throwError, Subscription } from 'rxjs';
import { OrderService, OrderItem } from '../../../services/order.service';
import { UserService, UserProfile } from '../../../services/user.service';
import { Router } from '@angular/router';

type AlertType = 'success' | 'error' | 'info';

@Component({
  selector: 'app-manageorders',
  standalone: true,
  templateUrl: './manageorders.component.html',
  styleUrls: ['./manageorders.component.css'],
  imports: [CommonModule, FormsModule, RouterModule]
})
export class ManageordersComponent implements OnInit, OnDestroy {
  autoRefreshPending = false;
  operationInProgress = false;
  orders: OrderItem[] = [];

  // user cache: userId -> UserProfile
  userMap: Record<number, UserProfile | undefined> = {};
  // pagination
  pageSize = 10;
  currentPage = 1;

  searchTerm = '';
  ordersLoading = false;
  approvingOrder = false;

  alertMessage = '';
  alertType: AlertType = 'info';
  showAlert = false;
  private alertTimeout?: ReturnType<typeof setTimeout>;
  private autoRefreshTimeout?: ReturnType<typeof setTimeout>;
  private subscriptions: Subscription[] = [];

  constructor(
    private orderService: OrderService,
    private router: Router,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    this.loadOrders();
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
    if (this.alertTimeout) clearTimeout(this.alertTimeout);
    if (this.autoRefreshTimeout) clearTimeout(this.autoRefreshTimeout);
  }

  displayAlert(message: string, type: AlertType = 'info') {
    this.alertMessage = message;
    this.alertType = type;
    this.showAlert = true;

    // Auto-close success/info alerts after 5 seconds (errors stay until manual close)
    if (type !== 'error') {
      this.alertTimeout = setTimeout(() => {
        this.showAlert = false;
      }, 5000);
    }
  }

  closeAlert() {
    this.showAlert = false;
    if (this.alertTimeout) {
      clearTimeout(this.alertTimeout);
      this.alertTimeout = undefined;
    }
  }

  loadOrders() {
    this.ordersLoading = true;
    const sub = this.orderService.getAllOrders()
      .pipe(
        timeout(10000),
        catchError(error => {
          this.displayAlert('Failed to load orders. Please try again.', 'error');
          return throwError(() => error);
        })
      )
      .subscribe({
        next: (orders) => {
          this.orders = orders || [];
          this.ordersLoading = false;
          this.loadUsersForOrders();
        },
        error: () => {
          this.ordersLoading = false;
        }
      });
    this.subscriptions.push(sub);
  }

  refreshAll() {
    this.autoRefreshPending = true;
    this.loadOrders();
    setTimeout(() => this.autoRefreshPending = false, 1000);
  }

  filteredOrders(): OrderItem[] {
    if (!this.searchTerm.trim()) {
      return this.orders;
    }
    const term = this.searchTerm.toLowerCase();
    return this.orders.filter(order =>
      order.id.toString().includes(term) ||
      order.status.toLowerCase().includes(term) ||
      order.paymentStatus.toLowerCase().includes(term) ||
      order.productId.toString().includes(term) ||
      order.userId.toString().includes(term)
    );
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.filteredOrders().length / this.pageSize));
  }

  get pagedOrders(): OrderItem[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.filteredOrders().slice(start, start + this.pageSize);
  }

  pagesArray(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

  changePage(page: number) {
    if (page < 1 || page > this.totalPages) { return; }
    this.currentPage = page;
    try { window.scrollTo({ top: 0, behavior: 'smooth' }); } catch (_) {}
  }

  approveOrder(order: OrderItem) {
    if (order.status === 'APPROVED') return;

    // Only require explicit force when payment FAILED. If payment is PENDING, allow approval.
    const needForce = order.paymentStatus === 'FAILED';
    if (needForce) {
      const ok = confirm(`Order #${order.id} payment status is '${order.paymentStatus}'. Force-approve?`);
      if (!ok) return;
    }

    this.approvingOrder = true;
    this.operationInProgress = true;

    const sub = this.orderService.approveOrder(order.id, needForce)
      .pipe(
        timeout(10000),
        catchError(error => {
          this.displayAlert('Failed to approve order. Please try again.', 'error');
          return throwError(() => error);
        })
      )
      .subscribe({
        next: (updatedOrder) => {
          // Update the order in the list
          const index = this.orders.findIndex(o => o.id === order.id);
          if (index !== -1) {
            this.orders[index] = updatedOrder;
          }
          this.displayAlert('Order approved successfully!', 'success');
          this.approvingOrder = false;
          this.operationInProgress = false;
        },
        error: () => {
          this.approvingOrder = false;
          this.operationInProgress = false;
        }
      });
    this.subscriptions.push(sub);
  }

  declineOrder(order: OrderItem) {
    if (order.status === 'CANCELLED') return;
    if (!confirm(`Decline order #${order.id}? This will cancel the order.`)) return;
    this.operationInProgress = true;
    const sub = this.orderService.declineOrder(order.id).subscribe({
      next: () => {
        // mark locally
        const idx = this.orders.findIndex(o => o.id === order.id);
        if (idx !== -1) {
          this.orders[idx].status = 'CANCELLED';
        }
        this.displayAlert('Order declined (cancelled).', 'info');
        this.operationInProgress = false;
      },
      error: () => {
        this.operationInProgress = false;
      }
    });
    this.subscriptions.push(sub);
  }

  deleteOrder(order: OrderItem) {
    if (!confirm(`Permanently delete order #${order.id}?`)) return;
    this.operationInProgress = true;
    const sub = this.orderService.deleteOrder(order.id).subscribe({
      next: () => {
        this.orders = this.orders.filter(o => o.id !== order.id);
        this.displayAlert('Order deleted.', 'success');
        this.operationInProgress = false;
      },
      error: () => {
        this.operationInProgress = false;
      }
    });
    this.subscriptions.push(sub);
  }

  // Fetch user profiles for all unique userIds in current orders
  private loadUsersForOrders() {
    const ids = Array.from(new Set(this.orders.map(o => o.userId)));
    ids.forEach(id => {
      if (this.userMap[id]) return; // already loaded
      const sub = this.userService.getUserById(id).subscribe({
        next: (user) => { if (user) this.userMap[id] = user; },
        error: () => { this.userMap[id] = undefined; }
      });
      this.subscriptions.push(sub);
    });
  }

  getStatusBadgeClass(status: string): string {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'bg-warning text-dark';
      case 'CONFIRMED': return 'bg-info text-white';
      case 'APPROVED': return 'bg-success text-white';
      case 'SHIPPED': return 'bg-primary text-white';
      case 'CANCELLED': return 'bg-danger text-white';
      default: return 'bg-secondary text-white';
    }
  }

  getPaymentStatusBadgeClass(status: string): string {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'bg-warning text-dark';
      case 'PAID': return 'bg-success text-white';
      case 'FAILED': return 'bg-danger text-white';
      case 'REFUNDED': return 'bg-info text-white';
      default: return 'bg-secondary text-white';
    }
  }

  get pendingApprovalCount(): number {
    return this.orders.filter(o => o.status === 'PENDING' && o.paymentStatus === 'PAID').length;
  }

  get approvedCount(): number {
    return this.orders.filter(o => o.status === 'APPROVED').length;
  }

  logout() {
    try {
      localStorage.removeItem('jwt_token');
      localStorage.removeItem('currentUser');
    } catch (e) {
      // ignore
    }
    this.router.navigate(['/login']);
  }
}