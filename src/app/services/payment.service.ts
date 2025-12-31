import { Injectable, Inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { of } from 'rxjs';
import { APP_CONFIG } from '../../main';

export type PaymentMethod = 'CARD' | 'COD';

export interface PaymentDto {
  id?: number;
  orderId: number;
  amount?: number;
  paymentStatus?: string;
  paymentMethod?: PaymentMethod;
  transactionId?: string;
}

@Injectable({ providedIn: 'root' })
export class PaymentService {
  private readonly apiUrl: string;

  constructor(private readonly http: HttpClient, @Inject(APP_CONFIG) private readonly config: any) {
    const base = (this.config?.apiUrl || '').replace(/\/$/, '');
    this.apiUrl = base.replace(/\/api$/, '') + '/api/payments';
  }

  createPayment(dto: Partial<PaymentDto>): Observable<PaymentDto> {
    return this.http.post<PaymentDto>(this.apiUrl, dto).pipe(
      catchError(err => { console.error('[PaymentService] createPayment error', err); return of(null as any); })
    );
  }

validateCard(card: { cardNumber: string; cvv: string; expiry: string }) {
  return this.http.post(`${this.apiUrl}/validate-card`, card, { observe: 'response' }).pipe(
    map(resp => resp.status === 200),
    catchError(err => {
      console.error('[PaymentService] validateCard error', err);
      return of(false);
    })
  );
}

  createPaymentWithCard(payment: Partial<PaymentDto>, card: { cardNumber: string; cvv: string; expiry: string }) {
    const body = { payment, card };
    return this.http.post<PaymentDto>(`${this.apiUrl}/card`, body).pipe(
      catchError(err => { console.error('[PaymentService] createPaymentWithCard error', err); return of(null as any); })
    );
  }

  confirmCodPayment(orderId: number) {
    return this.http.post<PaymentDto>(`${this.apiUrl}/confirm-cod/${orderId}`, {}).pipe(
      catchError(err => { console.error('[PaymentService] confirmCodPayment error', err); return of(null as any); })
    );
  }

  getPayment(id: number): Observable<PaymentDto> {
    return this.http.get<PaymentDto>(`${this.apiUrl}/${id}`).pipe(
      catchError(() => of(null as any))
    );
  }
}
