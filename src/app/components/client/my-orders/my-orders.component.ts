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
      // clear auth-related storage and navigate to login
      localStorage.removeItem('authToken');
      localStorage.removeItem('currentUser');
    } catch (e) {
      // ignore
    }
    this.router.navigate(['/login']);
  }
}
