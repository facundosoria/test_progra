export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn?: number;
  user: User;
}

export interface User {
  id: number;
  email: string;
  username: string;
  emailVerified: boolean;
  virtualCurrencyBalance?: number;
  skillRating?: number;
  wins?: number;
  losses?: number;
  draws?: number;
}

export interface LoginRequest {
  email: string;
  password: string;
  rememberMe: boolean;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  confirmPassword: string;
}

export interface VerifyEmailRequest {
  code: string;
}
