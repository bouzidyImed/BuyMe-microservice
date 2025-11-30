/*
package tn.iteam.authregisterservice.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import tn.iteam.authregisterservice.config.JwtUtil;
import tn.iteam.authregisterservice.dto.LoginResponseDto;
import tn.iteam.authregisterservice.dto.RequestDto;
import tn.iteam.authregisterservice.dto.RegistrationResponseDto;
import tn.iteam.authregisterservice.dto.UserDto;
import tn.iteam.authregisterservice.exceptions.EmailAlreadyExistsException;
import tn.iteam.authregisterservice.interfaces.FileStorageService;
import tn.iteam.authregisterservice.mappers.UserMapper;
import tn.iteam.authregisterservice.model.Client;
import tn.iteam.authregisterservice.model.Role;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.repos.ClientRepository;
import tn.iteam.authregisterservice.repos.RoleRepository;
import tn.iteam.authregisterservice.repos.UserRepository;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
public class AuthService {
    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final ClientRepository clientRepository;
    private final FileStorageService fileStorageService;
    private UserDto dto;

    public AuthService(JwtUtil jwtUtil, UserRepository userRepository, RoleRepository roleRepository, PasswordEncoder passwordEncoder, ClientRepository clientRepository, FileStorageService fileStorageService) {
        this.jwtUtil = jwtUtil;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.clientRepository = clientRepository;
        this.fileStorageService = fileStorageService;
    }



    */
/*public RegistrationResponseDto register(UserDto dto) {
        log.info("Registering new client: {}", dto.getEmail());

        // 1. Email uniqueness
        if (userRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new EmailAlreadyExistsException("Email already exists: " + dto.getEmail());
        }
        // 2. Map DTO → Entity using mapper
        Client client = UserMapper.toClientEntity(dto);
        // 3. Encode password
        client.setPassword(passwordEncoder.encode(dto.getPassword()));
        // 4. Handle profile picture
        String profilePicFilename = null;
        MultipartFile file = dto.getProfilePicFile();
        if (file != null && !file.isEmpty()) {
            try {
                profilePicFilename = fileStorageService.storeFile(file, "profiles");
                client.setProfilePic(profilePicFilename);
            } catch (IOException e) {
                log.error("Failed to upload profile picture", e);
                throw new RuntimeException("Failed to upload profile picture: " + e.getMessage());
            }
        }

        // 5. Assign default role
        Role clientRole = roleRepository.findByName("CLIENT")
                .orElseGet(() -> roleRepository.save(new Role("CLIENT")));

        if (client.getRoles() == null) {
            client.setRoles(new ArrayList<>());
        }
        client.getRoles().add(clientRole);
        // 6. Save to DB
        client = userRepository.save(client);
        // 7. Extract roles
        List<String> roles = client.getRoles().stream()
                .map(Role::getName)
                .toList();
        log.info("Client registered successfully: {}", client.getEmail());
        // 9. Return response
        return new RegistrationResponseDto(roles, "Client registered successfully");
    }
*//*


    // --- Registration ---
    public RegistrationResponseDto register(UserDto dto) {
        if (userRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        Client client = new Client();
        client.setFirstName(dto.getFirstName());
        client.setLastName(dto.getLastName());
        client.setEmail(dto.getEmail());
        client.setPassword(passwordEncoder.encode(dto.getPassword()));
        client.setPhone(dto.getPhone());
        client.setDob(dto.getDob());
        client.setCountry(dto.getCountry());
        client.setCity(dto.getCity());
        client.setZip(dto.getZip());
        client.setAddress(dto.getAddress());

        // --- handle profile pic ---
        if (dto.getProfilePicFile() != null && !dto.getProfilePicFile().isEmpty()) {
            try {
                String filename = fileStorageService.storeFile(dto.getProfilePicFile(), "profile-pics");
                client.setProfilePic(filename);
            } catch (IOException e) {
                throw new RuntimeException("Failed to store profile picture", e);
            }
        }

        // --- roles ---
        Role clientRole = roleRepository.findByName("CLIENT")
                .orElseGet(() -> roleRepository.save(new Role("CLIENT")));
        client.setRoles(List.of(clientRole));

        userRepository.save(client);

        return new RegistrationResponseDto(
                client.getRoles().stream().map(Role::getName).toList(),
                "Client registered successfully"
        );
    }



    // --- Login ---
    public ResponseEntity<LoginResponseDto> login(RequestDto dto) {
        Optional<User> userOpt = userRepository.findByEmail(dto.getEmail());
        if (userOpt.isEmpty() || !passwordEncoder.matches(dto.getPassword(), userOpt.get().getPassword())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new LoginResponseDto(null, null, "Invalid email or password"));
        }

        User user = userOpt.get();
        String token = jwtUtil.generateToken(user);

        LoginResponseDto response = new LoginResponseDto();
        response.setToken(token);
        response.setRoles(user.getRoles().stream().map(Role::getName).toList());
        response.setMessage("Login successful");
        return ResponseEntity.ok(response);
    }

    public User getUserByEmail(String email) {
        log.debug("Fetching user by email: {}", email);
        Optional<User> user = userRepository.findByEmail(email);
        if (user.isPresent()) {
            return user.get();
        }
        log.warn("No user found for email: {}", email);
        return null;
    }
}*/
package tn.iteam.authregisterservice.service;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.keycloak.OAuth2Constants;
import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.KeycloakBuilder;
import org.keycloak.representations.idm.CredentialRepresentation;
import org.keycloak.representations.idm.RoleRepresentation;
import org.keycloak.representations.idm.UserRepresentation;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import tn.iteam.authregisterservice.dto.*;
import tn.iteam.authregisterservice.exceptions.EmailAlreadyExistsException;
import tn.iteam.authregisterservice.interfaces.FileStorageService;
import tn.iteam.authregisterservice.model.Client;
import tn.iteam.authregisterservice.model.Role;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.repos.ClientRepository;
import tn.iteam.authregisterservice.repos.RoleRepository;
import tn.iteam.authregisterservice.repos.UserRepository;

import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final ClientRepository clientRepository;
    private final FileStorageService fileStorageService;

    @Value("${keycloak.auth-server-url}")
    private String keycloakUrl;
    @Value("${keycloak.realm}")
    private String realm;
    @Value("${keycloak.resource}")
    private String clientId;
    @Value("${keycloak.credentials.secret}")
    private String clientSecret;
    @Value("${keycloak.admin.username}")
    private String adminUsername;

    @Value("${keycloak.admin.password}")
    private String adminPassword;
    private Keycloak keycloakAdminClient;
    public AuthService(UserRepository userRepository,
                       RoleRepository roleRepository,
                       ClientRepository clientRepository,
                       FileStorageService fileStorageService) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.clientRepository = clientRepository;
        this.fileStorageService = fileStorageService;
    }

    // ---------------------------
    //   FIXED: Initialize Admin Client AFTER @Value injection
    // ---------------------------
    @PostConstruct
    public void initKeycloakAdminClient() {
        this.keycloakAdminClient = KeycloakBuilder.builder()
                .serverUrl(keycloakUrl)
                .realm("master")
                .clientId("admin-cli")
                .username(adminUsername)
                .password(adminPassword)
                .build();

        log.info("Keycloak admin client initialized for server: {}", keycloakUrl);
    }

    // --------------------------------------------------------------------
    // REGISTER USER
    // --------------------------------------------------------------------
    public RegistrationResponseDto register(RegisterRequestDto dto) {
        log.info("Registering new client: {}", dto.getEmail());

        if (userRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new EmailAlreadyExistsException("Email already exists: " + dto.getEmail());
        }

        Client client = new Client();
        client.setFirstName(dto.getFirstName());
        client.setLastName(dto.getLastName());
        client.setEmail(dto.getEmail());
        client.setPassword(dto.getPassword()); // must not be null
        client.setPhone(Integer.valueOf(dto.getPhone()));
        client.setDob(LocalDate.parse(dto.getDob()));
        client.setCountry(dto.getCountry());
        client.setCity(dto.getCity());
        client.setZip(Integer.valueOf(dto.getZip()));
        client.setAddress(dto.getAddress());
        client.setAccountNonExpired(true);
        client.setAccountNonLocked(true);
        client.setCredentialsNonExpired(true);
        client.setEnabled(true);

        if (dto.getProfilePicFile() != null && !dto.getProfilePicFile().isEmpty()) {
            try {
                String filename = fileStorageService.storeFile(dto.getProfilePicFile(), "profile-pics");
                client.setProfilePic(filename);
            } catch (IOException e) {
                throw new RuntimeException("Failed to store profile picture", e);
            }
        }
        Role clientRole = roleRepository.findByName("CLIENT")
                .orElseGet(() -> roleRepository.save(new Role("CLIENT")));
        client.setRoles(List.of(clientRole));
        client = userRepository.save(client);
        // Keycloak user creation
        createKeycloakUser(client, dto.getPassword());
        return new RegistrationResponseDto(
                client.getRoles().stream().map(Role::getName).toList(),
                "Client registered successfully"
        );
    }


    // --------------------------------------------------------------------
    // LOGIN (local lookup only, auth handled by Keycloak)
    // --------------------------------------------------------------------
    /*public LoginResponseDto login(RequestDto dto) {
        Optional<User> userOpt = userRepository.findByEmail(dto.getEmail());
        if (userOpt.isEmpty()) {
            return new LoginResponseDto(null, null, "User not found");
        }
        User user = userOpt.get();

        // --- Authenticate with Keycloak ---
        try {
            Keycloak keycloak = KeycloakBuilder.builder()
                    .serverUrl(keycloakUrl)
                    .realm(realm)
                    .clientId(clientId)
                    .clientSecret(clientSecret)
                    .username(dto.getEmail())
                    .password(dto.getPassword())
                    .build();

            String token = keycloak.tokenManager().getAccessTokenString();

            LoginResponseDto response = new LoginResponseDto();
            response.setUserId(user.getId().toString());
            response.setRoles(user.getRoles().stream().map(Role::getName).toList());
            response.setToken(token); // <-- ici tu mets le token
            response.setMessage("Login successful with Keycloak");

            return response;
        } catch (Exception e) {
            return new LoginResponseDto(user.getId().toString(), null, "Invalid credentials or Keycloak error");
        }
    }*/

    public LoginResponseDto login(RequestDto dto) {
        Optional<User> userOpt = userRepository.findByEmail(dto.getEmail());
        if (userOpt.isEmpty()) {
            return new LoginResponseDto(null, null, "User not found");
        }
        User user = userOpt.get();

        try {
            Keycloak keycloak = KeycloakBuilder.builder()
                    .serverUrl(keycloakUrl)                   // http://localhost:8080
                    .realm(realm)                             // e-commerce
                    .clientId(clientId)                       // auth-service
                    .clientSecret(clientSecret)               // your secret
                    .username(dto.getEmail())                 // login username
                    .password(dto.getPassword())              // login password
                    .grantType(OAuth2Constants.PASSWORD)      // 🔥 MISSING IN YOUR CODE
                    .build();

            String token = keycloak.tokenManager().getAccessTokenString();

            LoginResponseDto response = new LoginResponseDto();
            response.setUserId(user.getId().toString());
            response.setRoles(user.getRoles().stream().map(Role::getName).toList());
            response.setToken(token);
            response.setMessage("Login successful with Keycloak");

            return response;

        } catch (Exception e) {
            e.printStackTrace();
            return new LoginResponseDto(user.getId().toString(), null, "Invalid credentials or Keycloak error");
        }
    }



    // --------------------------------------------------------------------
    // GET CURRENT USER (from JWT token)
    // --------------------------------------------------------------------
    public User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken token) {

            String email = token.getToken().getClaimAsString("email");
            return userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User not found: " + email));
        }
        throw new RuntimeException("No authenticated user found");
    }
    // --------------------------------------------------------------------
    // CREATE USER IN KEYCLOAK
    // --------------------------------------------------------------------
    private void createKeycloakUser(Client client, String password) {
        try {
            // Check if exists
            List<UserRepresentation> existingUsers = keycloakAdminClient.realm(realm)
                    .users().search(client.getEmail());

            if (!existingUsers.isEmpty()) {
                log.warn("User {} already exists in Keycloak", client.getEmail());
                return;
            }
            // Build user
            UserRepresentation user = new UserRepresentation();
            user.setUsername(client.getEmail());
            user.setEmail(client.getEmail());
            user.setFirstName(client.getFirstName());
            user.setLastName(client.getLastName());
            user.setEnabled(true);
            // Password
            CredentialRepresentation cred = new CredentialRepresentation();
            cred.setType(CredentialRepresentation.PASSWORD);
            cred.setValue(password);
            cred.setTemporary(false);
            user.setCredentials(Collections.singletonList(cred));
            // Create user
            Response res = keycloakAdminClient.realm(realm).users().create(user);

            if (res.getStatus() != 201) {
                throw new RuntimeException("Failed to create Keycloak user, status: " + res.getStatus());
            }
            String userId = res.getLocation().getPath().replaceAll(".*/([^/]+)$", "$1");
            // Assign role CLIENT
            RoleRepresentation kcRole = keycloakAdminClient.realm(realm)
                    .roles().get("CLIENT").toRepresentation();

            keycloakAdminClient.realm(realm).users().get(userId)
                    .roles().realmLevel().add(List.of(kcRole));

            log.info("CLIENT role assigned to user {}", client.getEmail());

        } catch (Exception e) {
            throw new RuntimeException("Keycloak user creation failed: " + e.getMessage(), e);
        }
    }
    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email).orElse(null);
    }
}
