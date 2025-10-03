package tn.iteam.authregisterservice.repos;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.iteam.authregisterservice.model.User;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
}
