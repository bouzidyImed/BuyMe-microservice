package tn.iteam.authregisterservice.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import tn.iteam.authregisterservice.config.JwtUtil;
import tn.iteam.authregisterservice.dto.LoginResponseDto;
import tn.iteam.authregisterservice.dto.RequestDto;
import tn.iteam.authregisterservice.dto.RegistrationResponseDto;
import tn.iteam.authregisterservice.model.Client;
import tn.iteam.authregisterservice.model.Role;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.repos.ClientRepository;
import tn.iteam.authregisterservice.repos.RoleRepository;
import tn.iteam.authregisterservice.repos.UserRepository;

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

    public AuthService(JwtUtil jwtUtil, UserRepository userRepository, RoleRepository roleRepository, PasswordEncoder passwordEncoder, ClientRepository clientRepository) {
        this.jwtUtil = jwtUtil;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.clientRepository = clientRepository;
    }

    /*public RegistrationResponseDto register(Client client) {
        log.info("Registering new client: {}", client.getEmail());
        if (userRepository.findByEmail(client.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        client.setPassword(passwordEncoder.encode(client.getPassword()));
        Role clientRole = roleRepository.findByName("CLIENT")
                .orElseGet(() -> roleRepository.save(new Role("CLIENT")));

        if (client.getRoles() == null) client.setRoles(new ArrayList<>());
        client.getRoles().add(clientRole);

        clientRepository.save(client);

        List<String> roles = client.getRoles().stream()
                .map(Role::getName)
                .collect(Collectors.toList());

        log.info("Client registered: {}", client.getEmail());
        return new RegistrationResponseDto(roles, "Client registered successfully");
    }*/

    public RegistrationResponseDto register(Client client) {
        log.info("Registering new client: {}", client.getEmail());
        if (userRepository.findByEmail(client.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        client.setPassword(passwordEncoder.encode(client.getPassword()));
        Role clientRole = roleRepository.findByName("CLIENT")
                .orElseGet(() -> roleRepository.save(new Role("CLIENT")));

        if (client.getRoles() == null) client.setRoles(new ArrayList<>());
        client.getRoles().add(clientRole);

        userRepository.save(client); // Save to users table

        List<String> roles = client.getRoles().stream()
                .map(Role::getName)
                .collect(Collectors.toList());

        log.info("Client registered: {}", client.getEmail());
        return new RegistrationResponseDto(roles, "Client registered successfully");
    }

    public ResponseEntity<LoginResponseDto> login(RequestDto dto) {
        String email = dto.getEmail();
        String password = dto.getPassword();

        log.info("Login attempt for: {}", email);
        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            log.warn("Invalid login for email: {}", email);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new LoginResponseDto(null, null, "Invalid email or password"));
        }

        User user = userOpt.get();
        if (!passwordEncoder.matches(password, user.getPassword())) {
            log.warn("Invalid password for email: {}", email);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new LoginResponseDto(null, null, "Invalid email or password"));
        }

        List<String> roles = user.getRoles().stream()
                .map(Role::getAuthority)
                .collect(Collectors.toList());

        String token = jwtUtil.generateToken(user);

        LoginResponseDto response = new LoginResponseDto(token, roles, "Login successful");
        log.info("Login successful for: {}", email);
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
}