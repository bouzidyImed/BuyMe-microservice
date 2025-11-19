package tn.iteam.catalogueservice.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())  // Disable CSRF for stateless API (JWT-based)
                .authorizeHttpRequests(authz -> authz
                        .requestMatchers("/api/categories/**").permitAll()  // Allow public access to categories (GET/POST/PUT/DELETE)
                        .requestMatchers("/api/products/**").permitAll()
                        .requestMatchers("/actuator/**").permitAll()  // Allow actuator endpoints for monitoring
                        .requestMatchers("/api/reviews/**").authenticated()
                        // === SWAGGER UI & OPENAPI (on management port 9090) ===
                        // SWAGGER UI + OPENAPI JSON (MUST include both!)
                        .requestMatchers(
                                "/swagger-ui.html",
                                "/swagger-ui/**",
                                "/swagger-ui/index.html",
                                "/v3/api-docs",
                                "/v3/api-docs/**",
                                "/swagger-resources",
                                "/swagger-resources/**",
                                "/webjars/**"
                        ).permitAll()
                        .requestMatchers("/error").permitAll()  // Allow error handling for anonymous users
                        .anyRequest().authenticated()  // Require auth for other endpoints
                );
        return http.build();
    }
}
