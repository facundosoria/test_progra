package com.codemon.auth.service;

import com.codemon.auth.dto.*;
import com.codemon.auth.entity.RefreshToken;
import com.codemon.auth.entity.User;
import com.codemon.auth.repository.RefreshTokenRepository;
import com.codemon.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("PASSWORDS_MISMATCH");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("EMAIL_TAKEN");
        }
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("USERNAME_TAKEN");
        }

        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .emailVerified(true)
                .build();

        user = userRepository.save(user);
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getUsernameOrEmail())
                .or(() -> userRepository.findByUsername(request.getUsernameOrEmail()))
                .orElseThrow(() -> new BadCredentialsException("INVALID_CREDENTIALS"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("INVALID_CREDENTIALS");
        }

        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse refresh(String rawToken) {
        String tokenHash = jwtTokenProvider.hashToken(rawToken);
        RefreshToken stored = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new BadCredentialsException("INVALID_REFRESH_TOKEN"));

        if (stored.getRevokedAt() != null) {
            throw new BadCredentialsException("REFRESH_TOKEN_REVOKED");
        }
        if (stored.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadCredentialsException("REFRESH_TOKEN_EXPIRED");
        }

        User user = userRepository.findById(stored.getUserId())
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        String newAccessToken = jwtTokenProvider.generateAccessToken(user);
        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(rawToken)
                .expiresIn(jwtTokenProvider.getExpiryMs())
                .user(toUserDto(user))
                .build();
    }

    @Transactional
    public void logout(String rawToken) {
        String tokenHash = jwtTokenProvider.hashToken(rawToken);
        refreshTokenRepository.findByTokenHash(tokenHash)
                .ifPresent(token -> {
                    token.setRevokedAt(LocalDateTime.now());
                    refreshTokenRepository.save(token);
                });
    }

    public User getCurrentUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userId));
    }

    private AuthResponse buildAuthResponse(User user) {
        String rawRefresh = jwtTokenProvider.generateRefreshToken();
        String accessToken = jwtTokenProvider.generateAccessToken(user);

        RefreshToken refreshToken = RefreshToken.builder()
                .userId(user.getId())
                .tokenHash(jwtTokenProvider.hashToken(rawRefresh))
                .expiresAt(LocalDateTime.now().plusSeconds(604800))
                .build();
        refreshTokenRepository.save(refreshToken);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(rawRefresh)
                .expiresIn(jwtTokenProvider.getExpiryMs())
                .user(toUserDto(user))
                .build();
    }

    private AuthResponse.UserDto toUserDto(User user) {
        return AuthResponse.UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .emailVerified(user.getEmailVerified())
                .build();
    }
}
