package tn.iteam.authregisterservice.config;

import org.keycloak.admin.client.Keycloak;
import org.keycloak.admin.client.KeycloakBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class KeycloakConfig {
    @Bean
    public Keycloak keycloakAdminClient() {
        return KeycloakBuilder.builder()
                .serverUrl("http://localhost:8080")   // Keycloak server
                .realm("master")                      // Usually "master" for admin access
                .username("admin")                    // Keycloak admin username
                .password("admin123")                    // Keycloak admin password
                .clientId("admin-cli")                // admin-cli client
                .build();
    }
}
