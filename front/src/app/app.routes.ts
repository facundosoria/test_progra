import { Routes } from '@angular/router';
import { MainLayoutComponent } from './core/layouts/main-layout/main-layout.component';
import { authGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/launcher/play', pathMatch: 'full' },
  { path: 'auth', loadChildren: () => import('./auth/auth.routes').then(m => m.AUTH_ROUTES) },
  {
    path: 'launcher',
    component: MainLayoutComponent,
    canActivate: [authGuard],
    children: [
      { path: '', redirectTo: 'play', pathMatch: 'full' },
      { path: 'play',        loadComponent: () => import('./pages/play/play.component').then(m => m.PlayComponent) },
      { path: 'cards',       loadComponent: () => import('./pages/cards/cards.component').then(m => m.CardsComponent) },
      { path: 'decks',       loadComponent: () => import('./pages/decks/decks.component').then(m => m.DecksComponent) },
      { path: 'collection',  loadComponent: () => import('./pages/collection/collection.component').then(m => m.CollectionComponent) },
      { path: 'shop',        loadComponent: () => import('./pages/shop/shop.component').then(m => m.ShopComponent) },
      { path: 'leaderboard', loadComponent: () => import('./pages/leaderboard/leaderboard.component').then(m => m.LeaderboardComponent) },
      { path: 'settings',    loadComponent: () => import('./pages/settings/settings.component').then(m => m.SettingsComponent) },
      { path: 'profile',     loadComponent: () => import('./pages/profile/profile.component').then(m => m.ProfileComponent) }
    ]
  },
  { path: '**', redirectTo: '/launcher/play' }
];
