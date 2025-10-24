package tn.iteam.authregisterservice.controller;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import tn.iteam.authregisterservice.dto.LoginResponseDto;
import tn.iteam.authregisterservice.dto.RegistrationResponseDto;
import tn.iteam.authregisterservice.dto.RequestDto;
import tn.iteam.authregisterservice.dto.UserDto;
import tn.iteam.authregisterservice.model.Client;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.service.AuthService;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    // ---------------- Register ----------------
    @PostMapping("/register")
    public ResponseEntity<RegistrationResponseDto> register(@RequestBody @Valid Client client) {
        try {
            RegistrationResponseDto response = authService.register(client);
            log.info("Client registered successfully: {}", client.getEmail());
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            log.error("Registration failed for {}: {}", client.getEmail(), e.getMessage());
            return ResponseEntity.badRequest()
                    .body(new RegistrationResponseDto(null, e.getMessage()));
        }
    }

    // ---------------- Login ----------------
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(@RequestBody @Valid RequestDto authRequestDto) {
        log.info("Login attempt for email: {}", authRequestDto.getEmail());
        return authService.login(authRequestDto);
    }

    // ---------------- Get Current User ----------------
    @GetMapping("/me")
    public ResponseEntity<UserDto> getCurrentUser() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication == null || !authentication.isAuthenticated() || authentication.getPrincipal() == null) {
                log.warn("Unauthorized access: authentication is null or not authenticated");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            String email = authentication.getName();
            if (email == null) {
                log.warn("Email is null in authentication");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            User user = authService.getUserByEmail(email);
            if (user == null) {
                log.warn("User not found for email: {}", email);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }

            List<String> roles = authentication.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .collect(Collectors.toList());

            UserDto dto = UserDto.builder()
                    .id(user.getId())
                    .email(user.getEmail())
                    .roles(roles)
                    .build();

            return ResponseEntity.ok(dto);
        } catch (Exception e) {
            log.error("Error in /me endpoint", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}