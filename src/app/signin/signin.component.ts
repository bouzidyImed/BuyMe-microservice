// import { Component } from '@angular/core';

// @Component({
//   selector: 'app-signin',
//   standalone: false,
//   templateUrl: './signin.component.html',
//   styleUrl: './signin.component.css'
// })
// export class SigninComponent {

// }


import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';

@Component({
  selector: 'app-signin',
  standalone: false,
  templateUrl: './signin.component.html',
  styleUrl: './signin.component.css'
})
export class SigninComponent {
  loginData = { email: '', password: '' };
  errorMessage: string | null = null;
  successMessage: string | null = null;

  constructor(private http: HttpClient, private router: Router) {}

  onSubmit() {
this.http.post('http://localhost:8081/auth/login', this.loginData).subscribe({
        next: (response: any) => {
        this.successMessage = response.message || 'Login successful!';
        this.errorMessage = null;
        // Store token if needed (e.g., in localStorage)
        if (response.token) {
          localStorage.setItem('token', response.token);
        }
        // Redirect to dashboard or another route
        this.router.navigate(['/dashboard']);
      },
      error: (error) => {
        this.errorMessage = error.error?.message || 'Login failed. Please try again.';
        this.successMessage = null;
      }
    });
  }
}