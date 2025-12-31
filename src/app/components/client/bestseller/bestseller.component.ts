import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-bestseller',
  imports: [],
  templateUrl: './bestseller.component.html',
  styleUrl: './bestseller.component.css'
})
export class BestsellerComponent {

  constructor(private router: Router) {}

  logout() {
    try { localStorage.removeItem('authToken'); localStorage.removeItem('currentUser'); } catch(_){}
    this.router.navigate(['/login']);
  }

}
