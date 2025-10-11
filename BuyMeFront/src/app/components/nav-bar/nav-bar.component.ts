import { Component } from '@angular/core';
import {NavigationEnd, Router, RouterLink, RouterLinkActive} from '@angular/router';
import { filter } from 'rxjs/operators';
import {LoginService} from '../../services/login.service';
import{RegisterService} from '../../services/register.service';
import {CommonModule, NgOptimizedImage} from '@angular/common';
import {MatToolbar} from '@angular/material/toolbar';
import {MatAnchor, MatButton} from '@angular/material/button';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [
    RouterLink,
    RouterLinkActive,
    CommonModule,
    MatToolbar,
    MatAnchor,
    MatButton,
    NgOptimizedImage
  ],
  templateUrl: './nav-bar.component.html',
  styleUrl: './nav-bar.component.css'
})
export class NavbarComponent {
  showLogout = false;

  constructor(private router: Router, private loginService: LoginService, private registerService: RegisterService) {
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: NavigationEnd) => {
        this.showLogout = this.isDashboardRoute(event.urlAfterRedirects);
      });
  }

  isDashboardRoute(url: string): boolean {
    return url.includes('/admin') ||
      url.includes('/client') ||
      url.includes('/consultant');
  }

  logout() {
    this.loginService.logout();
    this.router.navigate(['/login']);
  }
}



