import { HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

const MOCKS: Record<string, { status?: number; body: unknown }> = {
  'POST /api/auth/login': {
    body: {
      accessToken: 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZW1haWwiOiJoZXJuYW5AY29kZW1vbi5jb20iLCJ1c2VybmFtZSI6Ikhlcm5hbiIsImV4cCI6OTk5OTk5OTk5OX0.mock',
      refreshToken: '550e8400-e29b-41d4-a716-446655440000',
      expiresIn: 900000,
      user: { id: 1, username: 'Hernan', email: 'hernan@codemon.com', emailVerified: true, virtualCurrencyBalance: 500, skillRating: 1450 }
    }
  },
  'POST /api/auth/login:401': {
    status: 401,
    body: { error: 'INVALID_CREDENTIALS', message: 'Usuario o contraseña incorrectos' }
  },
  'POST /api/auth/register': {
    status: 201,
    body: { message: 'Registro exitoso. Revisá tu email para verificar tu cuenta.', userId: 4 }
  },
  'POST /api/auth/register:409': {
    status: 409,
    body: { error: 'EMAIL_TAKEN', message: 'El email ya está registrado' }
  },
  'POST /api/auth/verify-email': {
    body: { message: 'Email verificado correctamente.' }
  },
  'POST /api/auth/verify-email:400': {
    status: 400,
    body: { error: 'INVALID_CODE', message: 'Código inválido o expirado' }
  },
  'POST /api/auth/resend-verification': {
    body: { message: 'Código reenviado. Revisá tu email.' }
  },
  'POST /api/auth/logout': {
    body: { message: 'Sesión cerrada correctamente.' }
  },
  'POST /api/auth/refresh': {
    body: {
      accessToken: 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZW1haWwiOiJoZXJuYW5AY29kZW1vbi5jb20iLCJ1c2VybmFtZSI6Ikhlcm5hbiIsImV4cCI6OTk5OTk5OTk5OX0.mock_new',
      refreshToken: '550e8400-e29b-41d4-a716-446655440001',
      user: { id: 1, username: 'Hernan', email: 'hernan@codemon.com', emailVerified: true }
    }
  },
  'GET /api/auth/me': {
    body: { id: 1, username: 'Hernan', email: 'hernan@codemon.com', emailVerified: true, virtualCurrencyBalance: 500, skillRating: 1450, wins: 30, losses: 12, draws: 2 }
  }
};

export const mockAuthInterceptor: HttpInterceptorFn = (req, next) => {
  if (!environment.useMocks) return next(req);

  const path = new URL(req.url, 'http://x').pathname;
  const key = `${req.method} ${path}`;

  const body = req.body as Record<string, string> | null;
  const duplicateEmail = req.method === 'POST' && path === '/api/auth/register' &&
    body?.['email'] === 'duplicate@test.com';

  const wrongPassword = req.method === 'POST' && path === '/api/auth/login' &&
    body?.['password'] === 'wrongpassword';

  const wrongCode = req.method === 'POST' && path === '/api/auth/verify-email' &&
    body?.['code'] !== '123456';

  if (duplicateEmail) {
    const mock = MOCKS['POST /api/auth/register:409'];
    return of(new HttpResponse({ status: mock.status, body: mock.body })).pipe(delay(environment.mockDelayMs));
  }

  if (wrongPassword) {
    const mock = MOCKS['POST /api/auth/login:401'];
    return of(new HttpResponse({ status: mock.status ?? 200, body: mock.body })).pipe(delay(environment.mockDelayMs));
  }

  if (wrongCode) {
    const mock = MOCKS['POST /api/auth/verify-email:400'];
    return of(new HttpResponse({ status: mock.status ?? 200, body: mock.body })).pipe(delay(environment.mockDelayMs));
  }

  const mock = MOCKS[key];
  if (mock) {
    return of(new HttpResponse({ status: mock.status ?? 200, body: mock.body })).pipe(delay(environment.mockDelayMs));
  }

  return next(req);
};
