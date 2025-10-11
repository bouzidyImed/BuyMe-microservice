import { Component } from '@angular/core';
import { FormBuilder, ValidatorFn, ValidationErrors, FormGroup, Validators, AbstractControl, ReactiveFormsModule } from '@angular/forms';
import {RegisterService} from "../../services/register.service";
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import {Router} from '@angular/router';
import { FormControl } from '@angular/forms';
import {RegisterResponse} from '../../models/register-response';
@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule
  ]
})
export class RegisterComponent {
  registerForm: FormGroup;
  message: string | null = null;

  constructor(private fb: FormBuilder, private registerService: RegisterService, private router:Router) {
    this.registerForm = this.fb.nonNullable.group({
      firstName: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
      lastName: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
      email: new FormControl('', { nonNullable: true, validators: [Validators.required, Validators.email] }),
      password: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
      matchingPassword: new FormControl('', { nonNullable: true, validators: [Validators.required] }),
    }, { validators: this.passwordMatchValidator });

  }

  passwordMatchValidator: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
    const password = control.get('password')?.value;
    const confirmPassword = control.get('matchingPassword')?.value;
    return password === confirmPassword ? null : { passwordMismatch: true };
  };

  onSubmit() {
    if (this.registerForm.valid) {
      const user = this.registerForm.value;
      this.registerService.register(user).subscribe({
        next: (res: RegisterResponse) => {
          console.log('Registration successful:', res);
          this.message = res.message;

          // redirect after 1.5s delay
          setTimeout(() => {
            this.router.navigate(['/login']);
          }, 1500);
        },
        error: (err: any) => {
          console.error('Registration failed:', err);
          this.message = err.error?.message || 'Registration failed';
        }
      });
    }
  }
}

