package tn.iteam.paymentservice.outbox;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import tn.iteam.paymentservice.model.OutboxEvent;
import tn.iteam.paymentservice.repos.OutboxRepository;

import java.time.Instant;
import java.util.List;

@Component
public class OutboxPublisher {

    private static final Logger log = LoggerFactory.getLogger(OutboxPublisher.class);

    private final OutboxRepository outboxRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public OutboxPublisher(OutboxRepository outboxRepository,
                           KafkaTemplate<String, String> kafkaTemplate) {
        this.outboxRepository = outboxRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Scheduled(fixedDelayString = "${outbox.publisher.delay-ms:1000}")
    public void pollAndPublish() {
        try {
            publishNewEvents();
        } catch (Exception e) {
            log.warn("Outbox publisher failed: {}", e.getMessage(), e);
        }
    }

    @Transactional
    public void publishNewEvents() {
        List<OutboxEvent> events = outboxRepository.findTop100ByStatusOrderByCreatedAtAsc("NEW");

        for (OutboxEvent ev : events) {
            try {
                String topic = mapEventToTopic(ev.getEventType());

                // Convert payload object to JSON string
                String payloadJson = ev.getPayload(); // assume already stored as JSON string
                kafkaTemplate.send(topic, ev.getAggregateId(), payloadJson).get();

                OutboxEvent locked = outboxRepository.lockByEventId(ev.getEventId());
                locked.setStatus("SENT");
                locked.setSentAt(Instant.now());
                outboxRepository.save(locked);

                log.debug("Published event {} to topic {}", ev.getEventId(), topic);

            } catch (Exception ex) {
                log.warn("Failed to publish event {}: {}", ev.getEventId(), ex.getMessage(), ex);
                OutboxEvent locked = outboxRepository.lockByEventId(ev.getEventId());
                locked.setAttempts(locked.getAttempts() + 1);
                if (locked.getAttempts() > 5) locked.setStatus("FAILED");
                outboxRepository.save(locked);
            }
        }
    }

    private String mapEventToTopic(String eventType) {
        return switch (eventType) {
            case "PAYMENT_PAID" -> "payments.events";
            case "STOCK_DECREASE" -> "stock.commands";
            default -> "domain.events";
        };
    }
}
