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
*/

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
}