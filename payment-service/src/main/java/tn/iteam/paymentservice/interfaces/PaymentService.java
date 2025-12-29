package tn.iteam.paymentservice.interfaces;
import tn.iteam.paymentservice.dto.PaymentDto;
import java.util.List;

public interface PaymentService {
    PaymentDto createPayment(PaymentDto dto);
    PaymentDto getPayment(Long id);
    List<PaymentDto> getAllPayments();
    PaymentDto updatePayment(Long id, PaymentDto dto);
    void deletePayment(Long id);
}
