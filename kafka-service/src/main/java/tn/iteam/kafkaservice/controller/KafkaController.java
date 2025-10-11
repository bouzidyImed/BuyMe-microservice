package tn.iteam.kafkaservice.controller;

import org.springframework.web.bind.annotation.*;
import tn.iteam.kafkaservice.producer.MessageProducer;

@RestController
@RequestMapping("/kafka")
public class KafkaController {
    private final MessageProducer producer;

    public KafkaController(MessageProducer producer) {
        this.producer = producer;
    }

    @PostMapping("/publish/{topic}")
    public String publish(@PathVariable String topic, @RequestBody String message) {
        producer.send(topic, message);
        return "Message sent to topic: " + topic;
    }
}
