package tn.iteam.authregisterservice.controller;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import tn.iteam.authregisterservice.dto.LoginResponseDto;
import tn.iteam.authregisterservice.dto.RegistrationResponseDto;
import tn.iteam.authregisterservice.dto.RequestDto;
import tn.iteam.authregisterservice.model.Client;
import tn.iteam.authregisterservice.service.AuthService;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    public AuthController(AuthService authService) {
        this.authService = authService;
    }
    // ---------------- Register ----------------
    @PostMapping("/register")
    public ResponseEntity<RegistrationResponseDto> register(@RequestBody Client client) {
        try {
            RegistrationResponseDto response = authService.register(client);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(new RegistrationResponseDto(null, e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(@RequestBody RequestDto authRequestDto) {
        return authService.login(authRequestDto);
    }

}
