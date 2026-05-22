import { Component, OnInit, OnDestroy, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, NavigationEnd } from '@angular/router';
import { Subscription } from 'rxjs';
import { filter } from 'rxjs/operators';
import { LucideAngularModule, Coins, LogOut, User } from 'lucide-angular';
import { AuthService } from '../../../auth/services/auth.service';

const SECTION_LABELS: Record<string, string> = {
  play: 'Jugar', cards: 'Cartas', decks: 'Mazos',
  collection: 'Colección', shop: 'Tienda',
  leaderboard: 'Ranking', settings: 'Ajustes', profile: 'Perfil'
};

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [CommonModule, LucideAngularModule],
  templateUrl: './topbar.component.html',
  styleUrls: ['./topbar.component.scss']
})
export class TopbarComponent implements OnInit, OnDestroy {
  currentSection = '';
  showUserMenu = false;
  coins = 1250;
  private routerSub?: Subscription;

  readonly icons = { Coins, LogOut, User };
  currentUser$ = this.authService.currentUser$;

  constructor(private router: Router, private authService: AuthService) {}

  ngOnInit(): void {
    this.updateSection(this.router.url);
    this.routerSub = this.router.events.pipe(
      filter(e => e instanceof NavigationEnd)
    ).subscribe(e => this.updateSection((e as NavigationEnd).urlAfterRedirects));
  }

  ngOnDestroy(): void {
    this.routerSub?.unsubscribe();
  }

  private updateSection(url: string): void {
    const segment = url.split('/').pop() || '';
    this.currentSection = SECTION_LABELS[segment] || '';
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (!(event.target as HTMLElement).closest('.trainer-menu-wrap')) {
      this.showUserMenu = false;
    }
  }

  onLogout(): void {
    this.showUserMenu = false;
    this.authService.logout();
  }
}
