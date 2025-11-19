package tn.iteam.authregisterservice.controller;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import tn.iteam.authregisterservice.dto.LoginResponseDto;
import tn.iteam.authregisterservice.dto.RegistrationResponseDto;
import tn.iteam.authregisterservice.dto.RequestDto;
import tn.iteam.authregisterservice.dto.UserDto;
import tn.iteam.authregisterservice.interfaces.FileStorageService;
import tn.iteam.authregisterservice.model.Client;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.service.AuthService;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/auth")
/*@Tag(name = "Authentication", description = "Endpoints for user registration, login, and profile")*/
public class AuthController {

    private final AuthService authService;
    private final FileStorageService fileStorageService;

    public AuthController(AuthService authService, FileStorageService fileStorageService) {
        this.authService = authService;
        this.fileStorageService = fileStorageService;
    }

    // --- Registration (multipart) ---
    /*@PostMapping("/register")
    public ResponseEntity<RegistrationResponseDto> register(@ModelAttribute @Valid UserDto userDto) {
        try {
            RegistrationResponseDto response = authService.register(userDto);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(new RegistrationResponseDto(null, e.getMessage()));
        }
    }*/

    @Operation(
            summary = "Register a new user (with profile picture)",
            description = "Registers a new client account. Supports multipart form-data for file upload.",
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            mediaType = MediaType.MULTIPART_FORM_DATA_VALUE,
                            schema = @Schema(implementation = UserDto.class)
                    )
            ),
            responses = {
                    @ApiResponse(
                            responseCode = "200",
                            description = "Client registered successfully",
                            content = @Content(mediaType = "application/json",
                                    schema = @Schema(implementation = RegistrationResponseDto.class))
                    ),
                    @ApiResponse(responseCode = "400", description = "Validation error or bad request")
            }
    )
    @PostMapping(
            value = "/register",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE
    )
    public ResponseEntity<RegistrationResponseDto> register(
            @ModelAttribute @Valid UserDto userDto
    ) {
        try {
            RegistrationResponseDto response = authService.register(userDto);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity
                    .badRequest()
                    .body(new RegistrationResponseDto(null, e.getMessage()));
        }
    }


    /*// --- Login (JSON) ---
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(@RequestBody @Valid RequestDto requestDto) {
        return authService.login(requestDto);
    }*/

    @Operation(
            summary = "User login",
            description = "Authenticates a user and returns a JWT token",
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = true,
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = RequestDto.class)
                    )
            ),
            responses = {
                    @ApiResponse(responseCode = "200", description = "Login successful",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = LoginResponseDto.class))),
                    @ApiResponse(responseCode = "401", description = "Invalid email or password")
            }
    )
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(
            @org.springframework.web.bind.annotation.RequestBody @Valid RequestDto requestDto
    ) {
        return authService.login(requestDto);
    }


    /*// ---------------- Get Current User ----------------
    @Operation(summary = "Get current authenticated user", description = "Returns user profile of currently authenticated user",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Current user retrieved",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = UserDto.class))),
                    @ApiResponse(responseCode = "401", description = "Unauthorized"),
                    @ApiResponse(responseCode = "404", description = "User not found")
            })*/
    // ---------------- Get Current User ----------------
    /*@GetMapping("/me")
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
    }*/

    @GetMapping("/me")
    @Operation(
            summary = "Get current authenticated user",
            description = "Returns user profile of currently authenticated user",
            responses = {
                    @ApiResponse(responseCode = "200", description = "Current user retrieved",
                            content = @Content(mediaType = "application/json", schema = @Schema(implementation = UserDto.class))),
                    @ApiResponse(responseCode = "401", description = "Unauthorized"),
                    @ApiResponse(responseCode = "404", description = "User not found")
            }
    )
    public ResponseEntity<UserDto> getCurrentUser() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

            if (authentication == null || !authentication.isAuthenticated() || authentication.getPrincipal() == null) {
                log.warn("Unauthorized access: authentication is null or not authenticated");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            String email = authentication.getName(); // principal name is email
            if (email == null) {
                log.warn("Email is null in authentication");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            User user = authService.getUserByEmail(email);
            if (user == null) {
                log.warn("User not found for email: {}", email);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }

            // map roles
            List<String> roles = authentication.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .collect(Collectors.toList());

            UserDto dto = UserDto.builder()
                    .id(user.getId())
                    .firstName(user.getFirstName())
                    .lastName(user.getLastName())
                    .email(user.getEmail())
                    .phone(user.getPhone())
                    .dob(user.getDob())
                    .country(user.getCountry())
                    .city(user.getCity())
                    .zip(user.getZip())
                    .address(user.getAddress())
                    .profilePic(user.getProfilePic())
                    .roles(roles)
                    .build();

            return ResponseEntity.ok(dto);
        } catch (Exception e) {
            log.error("Error in /me endpoint", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

}
