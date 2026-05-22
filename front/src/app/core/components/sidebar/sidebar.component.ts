import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router, NavigationEnd } from '@angular/router';
import { Subscription } from 'rxjs';
import { filter } from 'rxjs/operators';
import { LucideAngularModule, LucideIconData, Gamepad2, Layers, FolderOpen, Grid3x3, ShoppingBag, Trophy, Settings, LogOut } from 'lucide-angular';
import { AuthService } from '../../../auth/services/auth.service';

interface NavItem { label: string; route: string; icon: LucideIconData; }

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule, LucideAngularModule],
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss']
})
export class SidebarComponent implements OnInit, OnDestroy {
  activeRoute = '';
  private routerSub?: Subscription;

  readonly icons = { Gamepad2, Layers, FolderOpen, Grid3x3, ShoppingBag, Trophy, Settings, LogOut };

  readonly navItems: NavItem[] = [
    { label: 'Jugar',       route: '/launcher/play',        icon: Gamepad2 },
    { label: 'Cartas',      route: '/launcher/cards',       icon: Layers },
    { label: 'Mazos',       route: '/launcher/decks',       icon: FolderOpen },
    { label: 'Colección',   route: '/launcher/collection',  icon: Grid3x3 },
    { label: 'Tienda',      route: '/launcher/shop',        icon: ShoppingBag },
    { label: 'Ranking',     route: '/launcher/leaderboard', icon: Trophy }
  ];

  readonly bottomItems: NavItem[] = [
    { label: 'Ajustes', route: '/launcher/settings', icon: Settings }
  ];

  constructor(private router: Router, private authService: AuthService) {}

  ngOnInit(): void {
    this.activeRoute = this.router.url;
    this.routerSub = this.router.events.pipe(
      filter(e => e instanceof NavigationEnd)
    ).subscribe(e => this.activeRoute = (e as NavigationEnd).urlAfterRedirects);
  }

  ngOnDestroy(): void {
    this.routerSub?.unsubscribe();
  }

  isActive(route: string): boolean {
    return this.activeRoute.startsWith(route);
  }

  onLogout(): void {
    if (confirm('¿Cerrar sesión?')) this.authService.logout();
  }
}
