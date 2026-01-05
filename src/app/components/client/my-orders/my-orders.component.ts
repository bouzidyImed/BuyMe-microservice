import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { OrderService, OrderItem } from '../../../services/order.service';

@Component({
  selector: 'app-my-orders',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './my-orders.component.html',
  styleUrls: ['./my-orders.component.css']
})
export class MyOrdersComponent implements OnInit {
  orders: OrderItem[] = [];
  loading = true;
  error: string | null = null;
  pageSize = 5;
  currentPage = 1;

  constructor(private readonly orderService: OrderService, private readonly router: Router) {}

  deleteOrder(orderOrId: number | OrderItem) {
    const id = typeof orderOrId === 'number' ? orderOrId : (orderOrId.id ?? (orderOrId as any).orderId ?? undefined);
    if (!id) {
      this.error = 'Order id is missing.';
      return;
    }
    if (!confirm(`Delete order #${id}?`)) return;
    this.loading = true;
    this.orderService.deleteMyOrder(id).subscribe({
      next: () => {
        this.orders = this.orders.filter(o => (o.id ?? (o as any).orderId) !== id);
        this.loading = false;
      },
      error: (err) => {
        this.error = err.error?.message || err.message || 'Unable to delete order.';
        this.loading = false;
      }
    });
  }

  cancelOrder(orderOrId: number | OrderItem) {
    const id = this.getOrderId(orderOrId);
    if (!id) {
      this.error = 'Order id is missing.';
      return;
    }

    // Locate order object to inspect status
    const order = typeof orderOrId === 'number' ? this.orders.find(o => this.getOrderId(o) === id) : (orderOrId as OrderItem);
    if (!order) {
      this.error = 'Order not found in local list.';
      return;
    }

    if (order.status !== 'PENDING') {
      // Friendly message and do not call backend
      this.error = null;
      alert('Only pending orders can be cancelled.');
      return;
    }

    if (!confirm(`Cancel order #${id}?`)) return;
    this.loading = true;
    this.orderService.cancelMyOrder(id).subscribe({
      next: (updated) => {
        const idx = this.orders.findIndex(o => (o.id ?? (o as any).orderId) === id);
        if (idx !== -1) {
          this.orders[idx].status = 'CANCELLED';
        }
        // Optionally remove from list: keep it but marked cancelled
        this.loading = false;
      },
      error: (err) => {
        this.error = err.error?.message || err.message || 'Unable to cancel order.';
        this.loading = false;
      }
    });
  }

  getStatusBadgeClass(status: string): string {
    if (!status) return 'bg-secondary text-white';
    switch (status.toUpperCase()) {
      case 'PENDING': return 'bg-warning text-dark';
      case 'APPROVED': return 'bg-info text-white';
      case 'DELIVERED': return 'bg-success text-white';
      case 'CANCELLED': return 'bg-danger text-white';
      default: return 'bg-secondary text-white';
    }
  }

  // Template helper: safely extract an order id from different shapes
  getOrderId(orderOrId: number | OrderItem | any): number | null {
    if (!orderOrId) return null;
    if (typeof orderOrId === 'number') return orderOrId;
    if (orderOrId.id != null) return orderOrId.id;
    if (orderOrId.orderId != null) return orderOrId.orderId;
    if (orderOrId.orderID != null) return orderOrId.orderID;
    return null;
  }

  ngOnInit(): void {
    this.loadOrders();
  }

  private loadOrders() {
    this.loading = true;
    this.orderService.getMyOrders().subscribe({
      next: (res) => { this.orders = res ?? []; this.currentPage = 1; this.loading = false; },
      error: (err) => { this.error = err.error?.message || err.message || 'Unable to load orders.'; this.loading = false; }
    });
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.orders.length / this.pageSize));
  }

  get pagedOrders(): OrderItem[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.orders.slice(start, start + this.pageSize);
  }

  pagesArray(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

  changePage(page: number) {
    if (page < 1 || page > this.totalPages) { return; }
    this.currentPage = page;
    try { window.scrollTo({ top: 0, behavior: 'smooth' }); } catch (_) {}
  }

  logout() {
    try {
      localStorage.removeItem('authToken');
      localStorage.removeItem('currentUser');
    } catch (e) {
      // ignore
    }
    this.router.navigate(['/login']);
  }

  getPaymentMethodDisplay(method: string | undefined): string {
    if (method === 'CARD') return 'Credit Card';
    if (method === 'COD') return 'Cash on Delivery';
    return 'Unknown';
  }
}