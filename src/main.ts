/*import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));*/

import {importProvidersFrom, InjectionToken} from '@angular/core';
import {bootstrapApplication} from '@angular/platform-browser';
//import {HttpClientModule} from '@angular/common/module.d-CnjH8Dlt';
import {HttpClientModule} from '@angular/common/http';
import {provideHttpClient} from '@angular/common/http';
import {AppComponent} from './app/app.component';
import {provideRouter} from '@angular/router';
import {routes} from './app/app.routes';

export const APP_CONFIG = new InjectionToken<any>('APP_CONFIG');

fetch('/assets/config/config.json')
  .then(res => {
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    return res.json();
  })
  .then(config => {
    bootstrapApplication(AppComponent, {
      providers: [
        importProvidersFrom(HttpClientModule),
        provideHttpClient(),
        provideRouter(routes),
        { provide: APP_CONFIG, useValue: config }
      ]
    });
  })
  .catch(err => {
    console.error('Failed to load config.json', err);
    const fallbackConfig = { apiUrl: 'http://localhost:8081/api' };
    bootstrapApplication(AppComponent, {
      providers: [
        importProvidersFrom(HttpClientModule),
        provideHttpClient(),
        provideRouter(routes),
        { provide: APP_CONFIG, useValue: fallbackConfig }
      ]
    });
  });
