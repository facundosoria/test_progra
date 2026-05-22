package com.codemon.auth.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AuthResponse {

    private String accessToken;
    private String refreshToken;
    private long expiresIn;
    private UserDto user;

    @Data
    @Builder
    public static class UserDto {
        private Long id;
        private String username;
        private String email;
        private Boolean emailVerified;
    }
}
