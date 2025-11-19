package tn.iteam.orderservice.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.core.annotation.Order;

@Configuration
@EnableWebSecurity
@Order(1) // Important if you have multiple chains
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(authz -> authz
                        // Public APIs
                        .requestMatchers("/api/orders/**").permitAll()
                        .requestMatchers("/api/products/**").permitAll()

                        // Actuator (health, info, prometheus, etc.)
                        .requestMatchers("/actuator/**").permitAll()

                        // Eureka client endpoints (required for service registry)
                        .requestMatchers("/eureka/**").permitAll()

                        // Swagger / OpenAPI (if you add later)
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                        // Error page
                        .requestMatchers("/error").permitAll()

                        // Health check fallback
                        .requestMatchers("/").permitAll()

                        // Require authentication for everything else
                        .anyRequest().authenticated()
                )
                .httpBasic(Customizer.withDefaults()) // or formLogin, or JWT later
                .formLogin(Customizer.withDefaults());

        return http.build();
    }
}