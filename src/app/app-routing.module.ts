import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { SignupComponent } from './signup/signup.component';
import { SigninComponent } from './signin/signin.component';
import { LandingComponent } from './landing/landing.component';
import { NotfoundComponent } from './user/notfound/notfound.component';
import { BestsellerComponent } from './user/bestseller/bestseller.component';
import { CartComponent } from './user/cart/cart.component';
import { ContactComponent } from './user/contact/contact.component';
import { CheckoutComponent } from './user/checkout/checkout.component';
import { ShopComponent } from './user/shop/shop.component';
import { SingleComponent } from './user/single/single.component';
import { DashboardComponent } from './user/dashboard/dashboard.component';

const routes: Routes = [
  {path: 'signup', component: SignupComponent},
  {path: 'signin', component: SigninComponent},
  {path: 'notfound', component: NotfoundComponent},
  {path: 'bestseller', component: BestsellerComponent},
  {path: 'cart', component: CartComponent},
  {path: 'contact', component: ContactComponent},
  {path: 'checkout', component: CheckoutComponent},
  {path: 'shop', component: ShopComponent},
  {path: 'single', component: SingleComponent},
  {path: 'dashboard', component: DashboardComponent},
  { path: '', component: LandingComponent }

];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }




