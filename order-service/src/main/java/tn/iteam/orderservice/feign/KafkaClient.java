package tn.iteam.orderservice.feign;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(name = "kafka-service")
public interface KafkaClient {
    @PostMapping("/kafka/publish/{topic}")
    String publish(@PathVariable("topic") String topic, @RequestBody String message);
}

