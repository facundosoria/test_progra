import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-verify-email',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './verify-email.component.html',
  styleUrls: ['./verify-email.component.scss']
})
export class VerifyEmailComponent implements OnInit, OnDestroy {
  form!: FormGroup;
  loading = false;
  resending = false;
  errorMessage = '';
  successMessage = '';
  countdown = 0;
  email = '';
  private countdownInterval?: ReturnType<typeof setInterval>;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    const nav = this.router.getCurrentNavigation();
    this.email = nav?.extras?.state?.['email'] || '';
  }

  ngOnInit(): void {
    this.form = this.fb.group({
      code: ['', [Validators.required, Validators.pattern(/^\d{6}$/)]]
    });
    this.startCountdown();
  }

  ngOnDestroy(): void {
    if (this.countdownInterval) clearInterval(this.countdownInterval);
  }

  private startCountdown(): void {
    this.countdown = 60;
    if (this.countdownInterval) clearInterval(this.countdownInterval);
    this.countdownInterval = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = undefined;
      }
    }, 1000);
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.loading = true;
    this.errorMessage = '';
    this.authService.verifyEmail(this.form.value).subscribe({
      next: () => this.router.navigate(['/auth/login']),
      error: (err) => {
        this.loading = false;
        this.errorMessage = err.error?.message || 'Código inválido. Intentá de nuevo.';
      }
    });
  }

  onResend(): void {
    if (this.countdown > 0) return;
    this.resending = true;
    this.successMessage = '';
    this.errorMessage = '';
    this.authService.resendCode().subscribe({
      next: () => {
        this.resending = false;
        this.successMessage = 'Código reenviado. Revisá tu email.';
        this.startCountdown();
      },
      error: () => {
        this.resending = false;
        this.errorMessage = 'No se pudo reenviar el código.';
      }
    });
  }

  get code() { return this.form.get('code')!; }
}
