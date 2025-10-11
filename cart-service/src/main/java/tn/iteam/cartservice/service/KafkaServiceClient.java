package tn.iteam.cartservice.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import tn.iteam.cartservice.dto.ProductEventDTO;
@Service
@RequiredArgsConstructor
public class KafkaServiceClient {
    @Value("${kafka.service.url:http://localhost:8085/api/kafka/publish}")
    private String kafkaServiceUrl;
    private final RestTemplate restTemplate;

    public void sendProductEvent(ProductEventDTO event) {
        restTemplate.postForObject(kafkaServiceUrl, event, String.class);
}
}
