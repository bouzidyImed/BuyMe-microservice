import { Injectable, Inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { APP_CONFIG } from '../../main';

export interface OrderItem {
  id: number;
  qteOrdered: number;
  orderDate: string;
  productId: number;
  userId: number;
  status: string;
}

@Injectable({ providedIn: 'root' })
export class OrderService {
  private readonly apiUrl: string;

  constructor(private readonly http: HttpClient, @Inject(APP_CONFIG) private readonly config: any) {
    const base = (this.config?.apiUrl || '').replace(/\/$/, '');
    this.apiUrl = base.replace(/\/api$/, '') + '/api/orders';
  }

  getMyOrders(): Observable<OrderItem[]> {
    const url = `${this.apiUrl}/my-orders`;
    console.debug('[OrderService] getMyOrders ->', { url, tokenPreview: (localStorage.getItem('jwt_token') || '').slice(0,20) + '...' });
    return this.http.get<OrderItem[]>(url);
  }
}
