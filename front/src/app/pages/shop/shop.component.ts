import { Component } from '@angular/core';

@Component({
  selector: 'app-shop',
  standalone: true,
  template: `<div class="placeholder-page"><h2>Tienda</h2><p>Próximamente...</p></div>`,
  styles: [`.placeholder-page { padding: 2rem; color: #e8eaf6; } h2 { font-size: 1.5rem; font-weight: 600; margin-bottom: 0.5rem; } p { color: #6b7280; }`]
})
export class ShopComponent {}
