import { Injectable, Inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import {APP_CONFIG} from '../../main';

@Injectable({ providedIn: 'root' })
export class RegisterService {
  private apiUrl: string;

  constructor(
    private http: HttpClient,
    private router: Router,
    @Inject(APP_CONFIG) private config: any
  ) {
    this.apiUrl = `${this.config.apiUrl}/auth`;
  }
  register(user: any): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/register`, user);
  }
}
