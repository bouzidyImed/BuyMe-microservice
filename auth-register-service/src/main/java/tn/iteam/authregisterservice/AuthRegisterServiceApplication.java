package tn.iteam.authregisterservice;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import tn.iteam.authregisterservice.model.Role;
import tn.iteam.authregisterservice.model.User;
import tn.iteam.authregisterservice.repos.RoleRepository;
import tn.iteam.authregisterservice.repos.UserRepository;

import java.util.ArrayList;
import java.util.List;

@SpringBootApplication
public class AuthRegisterServiceApplication implements CommandLineRunner {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    public static void main(String[] args) {
        SpringApplication.run(AuthRegisterServiceApplication.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        // Seed roles
        if (roleRepository.findByName("ADMIN").isEmpty()) {
            roleRepository.save(new Role(null, "ADMIN"));
        }
        if (roleRepository.findByName("CLIENT").isEmpty()) {
            roleRepository.save(new Role(null, "CLIENT"));
        }

        // Seed admin user
        if (userRepository.findByEmail("admin@windowShopper.com").isEmpty()) {
            Role adminRole = roleRepository.findByName("ADMIN").get();
            User admin = new User();
            admin.setEmail("admin@windowShopper.com");
            admin.setFirstName("Admin");
            admin.setLastName("User");
            admin.setPassword(new BCryptPasswordEncoder().encode("admin"));
            List<Role> roles = new ArrayList<>();
            roles.add(adminRole);
            admin.setRoles(roles);
            userRepository.save(admin);
        }
    }
}
