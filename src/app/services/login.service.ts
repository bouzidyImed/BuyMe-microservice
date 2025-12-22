import {Inject, Injectable} from '@angular/core';
import {HttpClient} from '@angular/common/http';
import {Router} from '@angular/router';
import {catchError, Observable, tap, throwError} from 'rxjs';
import {APP_CONFIG} from '../../main';

@Injectable({
  providedIn: 'root'
})
export class LoginService {

  private apiUrl: string;

  constructor(
    private http: HttpClient,
    private router: Router,
    @Inject(APP_CONFIG) private config: any
  ) {
    this.apiUrl = `${this.config.apiUrl}/auth`;
  }

// Example for login.service.ts
login(email: string, password: string): Observable<any> {
  const url = `${this.apiUrl}/login`;
  console.log('Login Request:', { url, body: { email, password } });  // Log before send
  return this.http.post<any>(url, { email, password }).pipe(
    tap(response => console.log('Login Success:', response)),  // Import tap from 'rxjs/operators'
    catchError(err => {
      console.error('Login Error Details:', err);  // Full error
      return throwError(err);
    })
  );
}

  logout(): void {
    localStorage.removeItem('jwt_token');
    localStorage.removeItem('role');
    this.router.navigate(['/']);
  }
}
