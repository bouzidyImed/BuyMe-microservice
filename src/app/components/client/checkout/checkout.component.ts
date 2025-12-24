import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CartService } from '../../../services/cart.service';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'app-checkout',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './checkout.component.html',
  styleUrl: './checkout.component.css'
})
export class CheckoutComponent {
  items$;
  mobile: string = '';

  constructor(private readonly cartService: CartService, private readonly router: Router) {
    this.items$ = this.cartService.items$;
  }

  placeOrders() {
    const items = this.cartService.getItems();
    if (!items.length) {
      alert('Cart is empty');
      return;
    }

    const normalizedPhone = String(this.mobile || '').trim();

    const calls = items.map(i => {
      const payload = {
        orderDate: new Date(),
        productId: i.productId,
        qteOrdered: i.quantity,
        mobile: normalizedPhone
      };
      return firstValueFrom(this.cartService.placeOrder(payload))
        .then(res => ({ success: true, item: i, res }))
        .catch(err => ({ success: false, item: i, err }));
    });

    Promise.all(calls).then(results => {
      const failed = results.filter((r: any) => !r.success);
      if (failed.length === 0) {
        this.cartService.clear();
        alert('Order placed successfully');
        this.router.navigate(['/client/home']);
        return;
      }

      // Build friendly error message
      const messages = failed.map((f: any) => {
        const reason = f.err?.error?.message || f.err?.message || 'Unavailable';
        return `${f.item.name || 'Product ' + f.item.productId}: ${reason}`;
      });
      alert('Some items could not be ordered:\n' + messages.join('\n'));
    }).catch(err => {
      console.error('Unexpected error placing orders', err);
      alert('Failed to place orders: ' + (err?.message || err));
    });
  }

  getSubtotal(items: { price: number; quantity: number }[]) {
    return items.reduce((s, it) => s + (it.price * it.quantity), 0);
  }
}
