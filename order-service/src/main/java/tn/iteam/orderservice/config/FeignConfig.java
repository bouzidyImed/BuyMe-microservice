package tn.iteam.orderservice.config;

import feign.Logger;
import feign.Request;
import feign.codec.ErrorDecoder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FeignConfig {
    @Bean
    Logger.Level feignLoggerLevel() {
        return Logger.Level.FULL;  // Logs full Feign requests/responses
    }

    @Bean
    public Request.Options options() {
        return new Request.Options(5000, 10000);  // Connect/read timeouts
    }

    @Bean
    public ErrorDecoder errorDecoder() {
        return new ErrorDecoder() {
            @Override
            public Exception decode(String methodKey, feign.Response response) {
                return new RuntimeException("Feign error: " + response.reason() + " (status: " + response.status() + ")");
            }
        };
    }
}
