package tn.iteam.authregisterservice.service;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import tn.iteam.authregisterservice.config.JwtUtil;
import tn.iteam.authregisterservice.dto.LoginResponseDto;
import tn.iteam.authregisterservice.dto.RequestDto;
import tn.iteam.authregisterservice.dto.RegistrationResponseDto;
//import tn.iteam.authregisterservice.enums.AccountStatus;
import tn.iteam.authregisterservice.model.Client;
import tn.iteam.authregisterservice.model.Role;
//import tn.iteam.authregisterservice.model.Salarie;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.repos.ClientRepository;
import tn.iteam.authregisterservice.repos.RoleRepository;
import tn.iteam.authregisterservice.repos.UserRepository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

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

    // Registration without token
    public RegistrationResponseDto register(Client client) {
        if (userRepository.findByEmail(client.getEmail()).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        client.setPassword(passwordEncoder.encode(client.getPassword()));

        Role clientRole = roleRepository.findByName("CLIENT")
                .orElseGet(() -> roleRepository.save(new Role("CLIENT")));

        if (client.getRoles() == null) client.setRoles(new ArrayList<>());
        client.getRoles().add(clientRole);

        userRepository.save(client);

        List<String> roles = client.getRoles().stream()
                .map(Role::getName)
                .collect(Collectors.toList());

        return new RegistrationResponseDto(roles, "Client registered successfully");
    }

    public ResponseEntity<LoginResponseDto> login(RequestDto dto) {
        String email = dto.getEmail();
        String password = dto.getPassword();

        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new LoginResponseDto(null, null, "Invalid email or password"));
        }

        User user = userOpt.get();

        if (!passwordEncoder.matches(password, user.getPassword())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new LoginResponseDto(null, null, "Invalid email or password"));
        }
        // Extract role names
        List<String> roles = user.getRoles().stream()
                .map(Role::getAuthority)
                .collect(Collectors.toList());

        // Generate JWT token
        String token = jwtUtil.generateToken((UserDetails) user);

        // Return proper DTO
        LoginResponseDto response = new LoginResponseDto(token, roles, "Login successful");
        return ResponseEntity.ok(response);
    }

    private UserDetails buildUserDetails(String email, String password, String role) {
        return new org.springframework.security.core.userdetails.User(
                email,
                password,
                List.of(new SimpleGrantedAuthority(role))
        );
    }
}
