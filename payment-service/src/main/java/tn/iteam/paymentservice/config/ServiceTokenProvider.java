package tn.iteam.paymentservice.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;

@Component
public class ServiceTokenProvider {

    private static final Logger log = LoggerFactory.getLogger(ServiceTokenProvider.class);

    @Value("${security.oauth2.client.token-uri:}")
    private String tokenUri;

    @Value("${security.oauth2.client.client-id:}")
    private String clientId;

    @Value("${security.oauth2.client.client-secret:}")
    private String clientSecret;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper mapper = new ObjectMapper();

    private volatile String cachedToken;
    private volatile Instant expiresAt = Instant.EPOCH;

    public String getServiceToken() {
        if (cachedToken != null && Instant.now().isBefore(expiresAt.minusSeconds(10))) {
            return cachedToken;
        }

        if (tokenUri == null || tokenUri.isBlank() || clientId == null || clientId.isBlank()) {
            log.warn("Service token properties not configured (tokenUri/clientId). Skipping service token fetch.");
            return null;
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

            MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
            form.add("grant_type", "client_credentials");
            form.add("client_id", clientId);
            if (clientSecret != null && !clientSecret.isBlank()) {
                form.add("client_secret", clientSecret);
            }

            HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(form, headers);

            String response = restTemplate.postForObject(tokenUri, request, String.class);
            if (response == null) return null;

            JsonNode node = mapper.readTree(response);
            String accessToken = node.path("access_token").asText(null);
            int expiresIn = node.path("expires_in").asInt(300);
            if (accessToken != null) {
                cachedToken = accessToken;
                expiresAt = Instant.now().plusSeconds(expiresIn);
                return cachedToken;
            }
        } catch (Exception e) {
            log.warn("Failed to fetch service token: {}", e.getMessage());
        }
        return null;
    }
}
