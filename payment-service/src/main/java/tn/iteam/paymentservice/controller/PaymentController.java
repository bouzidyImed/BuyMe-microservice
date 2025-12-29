package tn.iteam.paymentservice.controller;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.iteam.paymentservice.dto.PaymentDto;
import tn.iteam.paymentservice.service.PaymentServiceImpl;

import java.util.List;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    private final PaymentServiceImpl paymentService;

    public PaymentController(PaymentServiceImpl paymentService) {
        this.paymentService = paymentService;
    }

    @PostMapping
    public ResponseEntity<PaymentDto> create(@RequestBody PaymentDto dto) {
        return ResponseEntity.ok(paymentService.createPayment(dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PaymentDto> get(@PathVariable Long id) {
        return ResponseEntity.ok(paymentService.getPayment(id));
    }

    @GetMapping
    public ResponseEntity<List<PaymentDto>> getAll() {
        return ResponseEntity.ok(paymentService.getAllPayments());
    }

    @PutMapping("/{id}")
    public ResponseEntity<PaymentDto> update(@PathVariable Long id, @RequestBody PaymentDto dto) {
        return ResponseEntity.ok(paymentService.updatePayment(id, dto));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        paymentService.deletePayment(id);
        return ResponseEntity.noContent().build();
    }
}

