import { Injectable, Inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, catchError, of, throwError } from 'rxjs';
import { APP_CONFIG } from '../../main';

export interface RecommendationRequest {
  history: number[]; // product IDs
  n?: number; // number of recommendations
}

export interface RecommendationResponse {
  recommendations: number[]; // product IDs
}

@Injectable({
  providedIn: 'root'
})
export class RecommenderService {
  private gatewayUrl: string;

  constructor(private http: HttpClient, @Inject(APP_CONFIG) private config: any) {
    // Get hostname from current location for better compatibility
    const hostname = typeof window !== 'undefined' ? window.location.hostname : 'localhost';
    
    // Gateway URL (preferred)
    const base = (this.config?.apiUrl || '').replace(/\/$/, '');
    const gatewayBase = base.replace(/\/api$/, '');
    // Note: api-gateway route is /recommendation/** -> strip prefix leaves /recommend
    this.gatewayUrl = `${gatewayBase}/recommendation/recommend`;
  }

  getRecommendations(history: number[], n: number = 5, userId?: number | string): Observable<RecommendationResponse> {
    // Ensure IDs are sent as strings to match backend storage
    const historyStr = (history || []).map(h => String(h));
    const payload: any = { history: historyStr, n };
    if (userId !== undefined && userId !== null) {
      payload.user_id = String(userId);
    }
    
    const token = localStorage.getItem('jwt_token') || '';
    const headers = new HttpHeaders({ 'Authorization': token ? `Bearer ${token}` : '' });

    // Use API Gateway only to avoid CORS duplication and direct exposure
    return this.http.post<RecommendationResponse>(this.gatewayUrl, payload, { headers }).pipe(
      catchError((err) => {
        console.error('[RecommenderService] gateway request failed', { payload, error: err });
        return of({ recommendations: [] });
      })
    );
  }
}

