import { Component } from '@angular/core';
//import { AuthService } from '../../services/auth.service';
import {LoginService} from "../../services/login.service";
import { FormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { NgIf } from '@angular/common';
import {MatButton} from '@angular/material/button';
import { Router } from '@angular/router';
//import {LoginResponseDto} from '../../models/login-response-dto';
import {LoginResponse} from '../../models/login-response';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
  standalone: true,
  imports: [
    FormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatProgressSpinnerModule,
    NgIf,
    MatButton
  ]
})
export class LoginComponent {
  credentials = {email: '', password: ''};
  message: string | null = null;
  isLoading = false;

  constructor(private loginService: LoginService, private router: Router) {
  }
onLogin() {
  this.isLoading = true;
  this.message = null;

  this.loginService.login(this.credentials.email, this.credentials.password)
    .subscribe({
      next: (res: LoginResponse) => {
        this.isLoading = false;

        if (res.token) {
          localStorage.setItem('jwt_token', res.token);
          localStorage.setItem('role', res.roles?.join(',') || '');
          this.message = res.message;

          // Normalize role names (remove "ROLE_" prefix if present)
          const roles = res.roles?.map(r => r.replace('ROLE_', ''));

          // ✅ Redirect based on normalized role
          if (roles?.includes('ADMIN')) {
            this.router.navigate(['/admin/manageproduct']);
          } else if (roles?.includes('CLIENT')) {
            this.router.navigate(['/client/home']);
          } else {
            this.router.navigate(['/notfound']);
          }

        } else {
          this.message = res.message;
        }
      },
      error: (err: any) => {
        this.isLoading = false;
        console.error('Login failed:', err);
        this.message = err.error?.message || 'Login failed';
      }
    });
}
}