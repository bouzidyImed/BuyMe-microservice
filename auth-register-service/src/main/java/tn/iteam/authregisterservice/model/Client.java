package tn.iteam.authregisterservice.model;

import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@Setter
public class Client extends  User {
    /*@OneToMany(mappedBy = "client")
    private List<Review> reviews;
    @OneToMany(mappedBy = "client")
    private List<Reservation> reservations = new ArrayList<>();*/
}
