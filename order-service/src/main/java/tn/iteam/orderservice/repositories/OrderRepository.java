package tn.iteam.orderservice.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.iteam.orderservice.model.Order;

public interface OrderRepository extends JpaRepository<Order, Long> {
}
