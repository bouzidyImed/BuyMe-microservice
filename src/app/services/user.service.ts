import { Inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { APP_CONFIG } from '../../main';

export interface UserProfile {
  id?: number;
  firstName: string;
  lastName: string;
  email: string;
  phone?: number;
  dob?: string;
  country?: string;
  city?: string;
  zip?: number;
  address?: string;
  profilePic?: string;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private apiUrl: string;
  private profilePicBaseUrl: string;

  constructor(
    private http: HttpClient,
    @Inject(APP_CONFIG) private config: any
  ) {
    this.apiUrl = `${this.config.apiUrl}/auth`;
    this.profilePicBaseUrl = `${this.config.apiUrl}/uploads/profiles-pics`;
  }

  getCurrentUser(): Observable<UserProfile> {
    return this.http.get<UserProfile>(`${this.apiUrl}/me`);
  }

  resolveProfileImage(filename?: string | null): string {
    if (!filename) {
      return 'assets/img/default-avatar.png';
    }
    return `${this.profilePicBaseUrl}/${filename}`;
  }
}

