import { Component } from '@angular/core';
import { CommonModule, CurrencyPipe, AsyncPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CartService } from '../../../services/cart.service';
import { OrderService, CreateOrderRequest } from '../../../services/order.service';
import { PaymentService } from '../../../services/payment.service';
import { Router, RouterModule } from '@angular/router';
import { firstValueFrom, Observable } from 'rxjs';

interface CartItem {
  productId: number;
  quantity: number;
  price: number;
  // add more if needed (name, image, etc.)
}

@Component({
  selector: 'app-checkout',
  standalone: true,
  imports: [CommonModule, FormsModule, CurrencyPipe, AsyncPipe, RouterModule],
  templateUrl: './checkout.component.html',
  styleUrls: ['./checkout.component.css']
})
export class CheckoutComponent {
  mobile = '';
  paymentMethod: 'CARD' | 'COD' = 'COD';
  cardNumber = '';
  cardExpiry = '';
  cardCvv = '';
  processing = false;

  items$!: Observable<CartItem[]>;  // ← Will be assigned in constructor

  private cartService!: CartService;  // ← Non-null assertion
  private orderService!: OrderService;
  private paymentService!: PaymentService;
  private router!: Router;

  constructor(
    cartService: CartService,
    orderService: OrderService,
    paymentService: PaymentService,
    router: Router
  ) {
    this.cartService = cartService;
    this.orderService = orderService;
    this.paymentService = paymentService;
    this.router = router;

    this.items$ = this.cartService.items$;  // ← Safe: assigned after injection
  }

  getSubtotal(items: CartItem[]): number {
    return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  }

  async placeOrders() {
    if (this.processing) return;
    this.processing = true;

    try {
      const items: CartItem[] = await firstValueFrom(this.items$);
      if (!items || items.length === 0) {
        alert('Your cart is empty.');
        return;
      }

      const payments = [];

      for (const item of items) {
        const orderPayload: CreateOrderRequest = {
          productId: item.productId,
          qteOrdered: item.quantity,
          mobile: this.mobile,
          paymentMethod: this.paymentMethod
        };

        const order = await firstValueFrom(this.orderService.createOrder(orderPayload));

        if (this.paymentMethod === 'CARD') {
          const paymentDto = {
            orderId: order.id,
            paymentMethod: this.paymentMethod,
            amount: item.price * item.quantity
          };
          const cardDto = {
            cardNumber: this.cardNumber,
            cvv: this.cardCvv,
            expiry: this.cardExpiry
          };
          const pay = await firstValueFrom(this.paymentService.createPaymentWithCard(paymentDto, cardDto));
          payments.push(pay);
        } else {
          const codPayload = {
            orderId: order.id,
            paymentMethod: this.paymentMethod,
            amount: item.price * item.quantity
          };
          const pay = await firstValueFrom(this.paymentService.createPayment(codPayload));
          payments.push(pay);
        }
      }

      this.cartService.clear();
      alert(
        this.paymentMethod === 'CARD'
          ? 'Order placed and paid successfully — thank you!'
          : 'Order placed successfully. Pay on delivery when you receive the items.'
      );
      this.router.navigate(['/client/home']);
    } catch (err: any) {
      console.error('Checkout failed', err);
      alert('Checkout failed: ' + (err.error?.message || err.message || 'Please try again.'));
    } finally {
      this.processing = false;
    }
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