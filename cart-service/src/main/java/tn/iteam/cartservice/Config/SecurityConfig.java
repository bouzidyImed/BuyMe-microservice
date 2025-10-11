package tn.iteam.cartservice.Config;

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
                        .requestMatchers("/api/cart/**").authenticated()  // Allow public access to categories (GET/POST/PUT/DELETE)
                        .requestMatchers("/actuator/**").permitAll()  // Allow actuator endpoints for monitoring
                        .requestMatchers("/api/wishlist/**").permitAll()
                        .requestMatchers("/error").permitAll()  // Allow error handling for anonymous users
                        .anyRequest().authenticated()  // Require auth for other endpoints
                );
        return http.build();
    }
}
