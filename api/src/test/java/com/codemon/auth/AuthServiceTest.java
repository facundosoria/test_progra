package com.codemon.auth;

import com.codemon.auth.dto.*;
import com.codemon.auth.entity.RefreshToken;
import com.codemon.auth.entity.User;
import com.codemon.auth.repository.RefreshTokenRepository;
import com.codemon.auth.repository.UserRepository;
import com.codemon.auth.service.AuthService;
import com.codemon.auth.service.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AuthServiceTest {

    @Mock UserRepository userRepository;
    @Mock RefreshTokenRepository refreshTokenRepository;
    @Mock JwtTokenProvider jwtTokenProvider;
    @Mock PasswordEncoder passwordEncoder;

    @InjectMocks AuthService authService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(1L)
                .username("ash")
                .email("ash@test.com")
                .passwordHash("$2a$10$hashed")
                .emailVerified(true)
                .role("USER")
                .build();

        when(jwtTokenProvider.generateAccessToken(any())).thenReturn("access.token.jwt");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("raw-refresh-uuid");
        when(jwtTokenProvider.hashToken(anyString())).thenReturn("hashed-token");
        when(jwtTokenProvider.getExpiryMs()).thenReturn(900000L);
        when(refreshTokenRepository.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void register_success_emailVerifiedTrue() {
        RegisterRequest req = new RegisterRequest();
        req.setUsername("ash");
        req.setEmail("ash@test.com");
        req.setPassword("Test123!");
        req.setConfirmPassword("Test123!");

        when(userRepository.existsByEmail("ash@test.com")).thenReturn(false);
        when(userRepository.existsByUsername("ash")).thenReturn(false);
        when(passwordEncoder.encode("Test123!")).thenReturn("$2a$10$hashed");
        when(userRepository.save(any())).thenReturn(testUser);

        AuthResponse response = authService.register(req);

        assertThat(response.getAccessToken()).isEqualTo("access.token.jwt");
        assertThat(response.getUser().getEmailVerified()).isTrue();
        verify(userRepository).save(argThat(u -> u.getEmailVerified()));
    }

    @Test
    void register_emailDuplicate_throws() {
        RegisterRequest req = new RegisterRequest();
        req.setUsername("ash");
        req.setEmail("ash@test.com");
        req.setPassword("Test123!");
        req.setConfirmPassword("Test123!");

        when(userRepository.existsByEmail("ash@test.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("EMAIL_TAKEN");
    }

    @Test
    void register_usernameDuplicate_throws() {
        RegisterRequest req = new RegisterRequest();
        req.setUsername("ash");
        req.setEmail("new@test.com");
        req.setPassword("Test123!");
        req.setConfirmPassword("Test123!");

        when(userRepository.existsByEmail("new@test.com")).thenReturn(false);
        when(userRepository.existsByUsername("ash")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("USERNAME_TAKEN");
    }

    @Test
    void register_passwordMismatch_throws() {
        RegisterRequest req = new RegisterRequest();
        req.setUsername("ash");
        req.setEmail("ash@test.com");
        req.setPassword("Test123!");
        req.setConfirmPassword("Different!");

        assertThatThrownBy(() -> authService.register(req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("PASSWORDS_MISMATCH");
    }

    @Test
    void login_success() {
        LoginRequest req = new LoginRequest();
        req.setUsernameOrEmail("ash@test.com");
        req.setPassword("Test123!");

        when(userRepository.findByEmail("ash@test.com")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches("Test123!", "$2a$10$hashed")).thenReturn(true);

        AuthResponse response = authService.login(req);

        assertThat(response.getAccessToken()).isEqualTo("access.token.jwt");
        assertThat(response.getUser().getId()).isEqualTo(1L);
    }

    @Test
    void login_wrongPassword_throws() {
        LoginRequest req = new LoginRequest();
        req.setUsernameOrEmail("ash@test.com");
        req.setPassword("wrong");

        when(userRepository.findByEmail("ash@test.com")).thenReturn(Optional.of(testUser));
        when(passwordEncoder.matches("wrong", "$2a$10$hashed")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void login_unknownEmail_throws() {
        LoginRequest req = new LoginRequest();
        req.setUsernameOrEmail("nobody@test.com");
        req.setPassword("Test123!");

        when(userRepository.findByEmail("nobody@test.com")).thenReturn(Optional.empty());
        when(userRepository.findByUsername("nobody@test.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void refresh_valid_returnsNewAccessToken() {
        RefreshToken stored = RefreshToken.builder()
                .id(1L)
                .userId(1L)
                .tokenHash("hashed-token")
                .expiresAt(LocalDateTime.now().plusDays(7))
                .build();

        when(refreshTokenRepository.findByTokenHash("hashed-token")).thenReturn(Optional.of(stored));
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser));

        AuthResponse response = authService.refresh("raw-refresh-uuid");

        assertThat(response.getAccessToken()).isEqualTo("access.token.jwt");
    }

    @Test
    void refresh_revoked_throws() {
        RefreshToken stored = RefreshToken.builder()
                .id(1L)
                .userId(1L)
                .tokenHash("hashed-token")
                .expiresAt(LocalDateTime.now().plusDays(7))
                .revokedAt(LocalDateTime.now().minusHours(1))
                .build();

        when(refreshTokenRepository.findByTokenHash("hashed-token")).thenReturn(Optional.of(stored));

        assertThatThrownBy(() -> authService.refresh("raw-refresh-uuid"))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessage("REFRESH_TOKEN_REVOKED");
    }

    @Test
    void refresh_expired_throws() {
        RefreshToken stored = RefreshToken.builder()
                .id(1L)
                .userId(1L)
                .tokenHash("hashed-token")
                .expiresAt(LocalDateTime.now().minusDays(1))
                .build();

        when(refreshTokenRepository.findByTokenHash("hashed-token")).thenReturn(Optional.of(stored));

        assertThatThrownBy(() -> authService.refresh("raw-refresh-uuid"))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessage("REFRESH_TOKEN_EXPIRED");
    }

    @Test
    void logout_revokesToken() {
        RefreshToken stored = RefreshToken.builder()
                .id(1L)
                .userId(1L)
                .tokenHash("hashed-token")
                .expiresAt(LocalDateTime.now().plusDays(7))
                .build();

        when(refreshTokenRepository.findByTokenHash("hashed-token")).thenReturn(Optional.of(stored));

        authService.logout("raw-refresh-uuid");

        verify(refreshTokenRepository).save(argThat(t -> t.getRevokedAt() != null));
    }
}
