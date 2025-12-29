package tn.iteam.paymentservice.properties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;


@Component
@ConfigurationProperties(prefix = "killbill")
public class KillBillProperties {
    private String url;
    private String apiKey;
    private String apiSecret;
    private String basicAuth;


    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
    public String getApiKey() { return apiKey; }
    public void setApiKey(String apiKey) { this.apiKey = apiKey; }
    public String getApiSecret() { return apiSecret; }
    public void setApiSecret(String apiSecret) { this.apiSecret = apiSecret; }
    public String getBasicAuth() { return basicAuth; }
    public void setBasicAuth(String basicAuth) { this.basicAuth = basicAuth; }
}
