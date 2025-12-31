import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-shop',
  imports: [],
  templateUrl: './shop.component.html',
  styleUrl: './shop.component.css'
})
export class ShopComponent {
  constructor(private router: Router) {}

  logout() {
    try { localStorage.removeItem('authToken'); localStorage.removeItem('currentUser'); } catch(_){}
    this.router.navigate(['/login']);
  }

}
