package tn.iteam.paymentservice.client;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import tn.iteam.paymentservice.dto.KillBillInvoiceRequest;
import tn.iteam.paymentservice.dto.KillBillInvoiceResponse;
import tn.iteam.paymentservice.dto.KillBillPaymentRequest;
import tn.iteam.paymentservice.dto.KillBillPaymentResponse;

@FeignClient(name = "killbill", url = "${killbill.base-url}", configuration = {})
public interface KillBillClient {

    @PostMapping(value = "/1.0/kb/invoices", consumes = "application/json")
    KillBillInvoiceResponse createInvoice(
            @RequestBody KillBillInvoiceRequest request,
            @RequestHeader(value = "X-Killbill-ApiKey", required = false) String apiKey,
            @RequestHeader(value = "X-Killbill-ApiSecret", required = false) String apiSecret,
            @RequestHeader(value = "X-Killbill-Username", required = false) String username,
            @RequestHeader(value = "X-Killbill-Tenant", required = false) String tenant
    );

    @PostMapping(value = "/1.0/kb/payments", consumes = "application/json")
    KillBillPaymentResponse createPayment(
            @RequestBody KillBillPaymentRequest request,
            @RequestHeader(value = "X-Killbill-ApiKey", required = false) String apiKey,
            @RequestHeader(value = "X-Killbill-ApiSecret", required = false) String apiSecret,
            @RequestHeader(value = "X-Killbill-Username", required = false) String username,
            @RequestHeader(value = "X-Killbill-Tenant", required = false) String tenant
    );
}

