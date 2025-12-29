package tn.iteam.paymentservice.repos;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.iteam.paymentservice.model.Payment;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

}
