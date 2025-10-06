// import { Component } from '@angular/core';

// @Component({
//   selector: 'app-signup',
//   standalone: false,
//   templateUrl: './signup.component.html',
//   styleUrl: './signup.component.css'
// })
// export class SignupComponent {

// }


import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';

@Component({
  selector: 'app-signup',
  standalone: false,
  templateUrl: './signup.component.html',
  styleUrl: './signup.component.css'
})
export class SignupComponent {
  signupData = {
    email: '',
    firstName: '',
    lastName: '',
    phone: null,
    dob: null,
    country: '',
    city: '',
    zip: null,
    address: '',
    password: '',
    profilePic: ''
  };
  termsAccepted = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;

  constructor(private http: HttpClient, private router: Router) {}

  onSubmit() {
    if (!this.termsAccepted) {
      this.errorMessage = 'Please accept the Terms and Conditions.';
      return;
    }
this.http.post('http://localhost:8085/auth/register', this.signupData).subscribe({
        next: (response: any) => {
        this.successMessage = response.message || 'Registration successful!';
        this.errorMessage = null;
        this.router.navigate(['/signin']);
      },
      error: (error) => {
        this.errorMessage = error.error?.message || 'Registration failed. Please try again.';
        this.successMessage = null;
      }
    });
  }
}