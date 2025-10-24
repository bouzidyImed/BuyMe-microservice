package tn.iteam.authregisterservice.config;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import tn.iteam.authregisterservice.model.User;

import java.util.Collection;
import java.util.stream.Collectors;

public class CustomUserDetails implements UserDetails {
    private final User user;

    public CustomUserDetails(User user) {
        this.user = user;
    }

    public User getUser() {
        return user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return user.getRoles().stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role.getName()))
                .collect(Collectors.toList());
    }

    @Override
    public String getPassword() { return user.getPassword(); }
    @Override
    public String getUsername() { return user.getEmail(); }
    @Override
    public boolean isAccountNonExpired() { return user.isAccountNonExpired(); }
    @Override
    public boolean isAccountNonLocked() { return user.isAccountNonLocked(); }
    @Override
    public boolean isCredentialsNonExpired() { return user.isCredentialsNonExpired(); }
    @Override
    public boolean isEnabled() { return user.isEnabled(); }
}