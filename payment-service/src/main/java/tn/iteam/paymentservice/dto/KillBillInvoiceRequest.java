package tn.iteam.paymentservice.dto;

import java.util.List;

public class KillBillInvoiceRequest {
    private String accountId; // UUID customer account in Kill Bill
    private List<InvoiceItem> items;
}
