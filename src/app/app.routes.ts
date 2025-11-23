import { Routes } from '@angular/router';
import {LoginComponent} from './components/login/login.component';
import {RegisterComponent} from './components/register/register.component';
import {HomeComponent} from './components/client/home/home.component';
import {BestsellerComponent} from './components/client/bestseller/bestseller.component';
import {CartComponent} from './components/client/cart/cart.component';
import {CheckoutComponent} from './components/client/checkout/checkout.component';
import {ShopComponent} from './components/client/shop/shop.component';
import {SingleComponent} from './components/client/single/single.component';
import {ContactComponent} from './components/contact/contact.component';
import {NotfoundComponent} from './components/notfound/notfound.component';
import { ProfileComponent } from './components/client/profile/profile.component';
import { MyOrdersComponent } from './components/client/my-orders/my-orders.component';
import { ManageproductComponent } from './components/admin/manageproduct/manageproduct.component';

export const routes: Routes = [
  { path: 'client/home', component: HomeComponent },
    { path: 'client/my-orders', component: MyOrdersComponent },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  {path: 'client/bestseller', component: BestsellerComponent},
  {path: 'client/cart', component: CartComponent},
  {path: 'client/checkout', component: CheckoutComponent},
  {path: 'client/orders', component: MyOrdersComponent},
  {path: 'client/shop', component: ShopComponent},
  {path: 'client/single', component: SingleComponent},
  {path: 'contact', component: ContactComponent},
  {path: 'notfound', component: NotfoundComponent},
  {path: 'client/profile', component: ProfileComponent},
  {path: 'admin/manageproduct', component: ManageproductComponent}









];
