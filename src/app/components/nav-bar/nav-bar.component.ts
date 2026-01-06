import { Component, OnDestroy, OnInit } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs/operators';
import { Subscription } from 'rxjs';
import { LoginService } from '../../services/login.service';
import { CommonModule } from '@angular/common';
import { UserProfile, UserService } from '../../services/user.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [
    CommonModule
  ],
  templateUrl: './nav-bar.component.html',
  styleUrl: './nav-bar.component.css'
})
export class NavbarComponent implements OnInit, OnDestroy {
  showLogout = false;
  currentUser: UserProfile | null = null;
  userAvatar = 'assets/img/default-avatar.png';
  private routerSub?: Subscription;
  private userSub?: Subscription;
  private cachedToken: string | null = null;

  constructor(
    private router: Router,
    private loginService: LoginService,
    private userService: UserService
  ) {
    this.routerSub = this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: NavigationEnd) => {
        this.showLogout = this.isDashboardRoute(event.urlAfterRedirects);
        this.loadUserProfile();
      });
  }

  ngOnInit(): void {
    this.loadUserProfile();
  }

  isDashboardRoute(url: string): boolean {
    return url.includes('/admin') ||
      url.includes('/client') ||
      url.includes('/consultant');
  }

  logout() {
    this.loginService.logout();
    this.currentUser = null;
    this.userAvatar = 'assets/img/default-avatar.png';
    this.cachedToken = null;
    this.userSub?.unsubscribe();
    this.router.navigate(['/login']);
  }

  ngOnDestroy(): void {
    this.routerSub?.unsubscribe();
    this.userSub?.unsubscribe();
  }

  private loadUserProfile(): void {
    const token = localStorage.getItem('jwt_token');
    if (!token) {
      this.currentUser = null;
      this.userAvatar = 'assets/img/default-avatar.png';
      this.cachedToken = null;
      return;
    }

    if (token === this.cachedToken && this.currentUser) {
      return;
    }
    this.cachedToken = token;

    this.userSub?.unsubscribe();
    this.userSub = this.userService.getCurrentUser().subscribe({
      next: (user) => {
        this.currentUser = user;
        this.userAvatar = this.userService.resolveProfileImage(user.profilePic);
      },
      error: () => {
        this.currentUser = null;
        this.userAvatar = 'assets/img/default-avatar.png';
        this.cachedToken = null;
      }
    });
  }
}



