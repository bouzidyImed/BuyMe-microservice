package tn.iteam.authregisterservice;

import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.resource.RealmResource;
import org.keycloak.representations.idm.CredentialRepresentation;
import org.keycloak.representations.idm.RoleRepresentation;
import org.keycloak.representations.idm.UserRepresentation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import tn.iteam.authregisterservice.model.Role;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.repos.RoleRepository;
import tn.iteam.authregisterservice.repos.UserRepository;

import jakarta.ws.rs.core.Response;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@SpringBootApplication
public class AuthRegisterServiceApplication implements CommandLineRunner {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private Keycloak keycloakAdminClient;

    private final String realm = "e-commerce"; // Your Keycloak realm

    public static void main(String[] args) {
        SpringApplication.run(AuthRegisterServiceApplication.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        // -----------------------------
        // 1️⃣ Seed roles locally
        // -----------------------------
        Role adminRole = roleRepository.findByName("ADMIN")
                .orElseGet(() -> roleRepository.save(new Role(null, "ADMIN")));

        Role clientRole = roleRepository.findByName("CLIENT")
                .orElseGet(() -> roleRepository.save(new Role(null, "CLIENT")));

        // -----------------------------
        // 2️⃣ Seed admin user locally
        // -----------------------------
        if (userRepository.findByEmail("admin@windowShopper.com").isEmpty()) {
            User admin = new User();
            admin.setEmail("admin@windowShopper.com");
            admin.setFirstName("Admin");
            admin.setLastName("User");
            admin.setPassword(new BCryptPasswordEncoder().encode("admin"));
            admin.setRoles(Collections.singletonList(adminRole));
            userRepository.save(admin);
        }

        // -----------------------------
        // 3️⃣ Seed admin user in Keycloak
        // -----------------------------
        RealmResource realmResource = keycloakAdminClient.realm(realm);

        // Check if user exists
        List<UserRepresentation> existingUsers = realmResource.users()
                .search("admin@windowShopper.com");
        if (existingUsers.isEmpty()) {
            // Create user
            UserRepresentation kcUser = new UserRepresentation();
            kcUser.setUsername("admin@windowShopper.com");
            kcUser.setEmail("admin@windowShopper.com");
            kcUser.setFirstName("Admin");
            kcUser.setLastName("User");
            kcUser.setEnabled(true);

            CredentialRepresentation passwordCred = new CredentialRepresentation();
            passwordCred.setTemporary(false);
            passwordCred.setType(CredentialRepresentation.PASSWORD);
            passwordCred.setValue("admin");

            kcUser.setCredentials(Collections.singletonList(passwordCred));

            Response response = realmResource.users().create(kcUser);
            if (response.getStatus() != 201) {
                System.out.println("Failed to create Keycloak admin: " + response.getStatus());
            } else {
                String userId = response.getLocation().getPath().replaceAll(".*/([^/]+)$", "$1");
                // Assign CLIENT & ADMIN roles
                RoleRepresentation kcAdminRole = realmResource.roles().get("ADMIN").toRepresentation();
                realmResource.users().get(userId).roles().realmLevel().add(Collections.singletonList(kcAdminRole));
                System.out.println("Admin user created in Keycloak with roles assigned.");
            }
        } else {
            System.out.println("Admin user already exists in Keycloak.");
        }
    }
}
