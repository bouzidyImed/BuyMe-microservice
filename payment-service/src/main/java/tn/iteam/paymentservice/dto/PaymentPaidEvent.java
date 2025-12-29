package tn.iteam.paymentservice.dto;

import java.time.Instant;
import java.util.UUID;
import java.util.List;

public class PaymentPaidEvent {
    private String eventId = UUID.randomUUID().toString();
    private String aggregate = "payment";
    private String aggregateId;
    private Long orderId;
    private String status = "PAID";
    private Instant occurredAt = Instant.now();
    private List<Item> items;

    public static class Item {
        public Long productId;
        public Integer quantity;
    }

    public String getEventId() { return eventId; }
    public String getAggregate() { return aggregate; }
    public String getAggregateId() { return aggregateId; }
    public void setAggregateId(String aggregateId) { this.aggregateId = aggregateId; }
    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }
    public String getStatus() { return status; }
    public Instant getOccurredAt() { return occurredAt; }
    public List<Item> getItems() { return items; }
    public void setItems(List<Item> items) { this.items = items; }
}
