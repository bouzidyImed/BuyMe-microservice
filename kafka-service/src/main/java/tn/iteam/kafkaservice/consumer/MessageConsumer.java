package tn.iteam.kafkaservice.consumer;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
public class MessageConsumer {
    @KafkaListener(topics = "user-registered", groupId = "kafka-service-group")
    public void consumeUserRegistered(String message) {
        System.out.println("📥 Received from user-registered: " + message);
    }

    @KafkaListener(topics = "order-created", groupId = "kafka-service-group")
    public void consumeOrderCreated(String message) {
        System.out.println("📥 Received from order-created: " + message);
    }
}
