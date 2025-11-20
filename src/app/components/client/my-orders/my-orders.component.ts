import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
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

  constructor(private readonly orderService: OrderService) {}

  ngOnInit(): void {
    this.loadOrders();
  }

  private loadOrders() {
    this.loading = true;
    this.orderService.getMyOrders().subscribe({
      next: (res) => { this.orders = res ?? []; this.loading = false; },
      error: (err) => { this.error = err.error?.message || err.message || 'Unable to load orders.'; this.loading = false; }
    });
  }
}
