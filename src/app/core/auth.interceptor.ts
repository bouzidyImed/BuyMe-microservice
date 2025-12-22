import { HttpInterceptorFn } from '@angular/common/http';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  // Don't attach Authorization header for authentication endpoints
  const url = typeof req.url === 'string' ? req.url : '';
  if (url.includes('/api/auth/login') || url.includes('/api/auth/register') || url.endsWith('/auth/login') || url.endsWith('/auth/register')) {
    return next(req);
  }

  const token = localStorage.getItem('jwt_token');
  if (token) {
    const authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
    return next(authReq);
  }

  return next(req);
};
