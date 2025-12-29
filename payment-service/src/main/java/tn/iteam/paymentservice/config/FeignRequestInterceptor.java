package tn.iteam.paymentservice.config;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import tn.iteam.paymentservice.config.ServiceTokenProvider;

import jakarta.servlet.http.HttpServletRequest;

@Component
public class FeignRequestInterceptor implements RequestInterceptor {

    private static final Logger log = LoggerFactory.getLogger(FeignRequestInterceptor.class);
    private final ServiceTokenProvider tokenProvider;

    public FeignRequestInterceptor(ServiceTokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @Override
    public void apply(RequestTemplate template) {
        RequestAttributes requestAttributes = RequestContextHolder.getRequestAttributes();
        if (requestAttributes instanceof ServletRequestAttributes servletAttrs) {
            HttpServletRequest request = servletAttrs.getRequest();
            String auth = request.getHeader("Authorization");
            if (auth != null && !auth.isBlank()) {
                template.header("Authorization", auth);
                log.debug("Feign: forwarding incoming Authorization header to downstream service");
                return;
            }
        }

        // fallback to service account token (client credentials)
        String serviceToken = tokenProvider.getServiceToken();
        if (serviceToken != null && !serviceToken.isBlank()) {
            template.header("Authorization", "Bearer " + serviceToken);
            log.debug("Feign: using service account token for downstream call (not logging token contents)");
        } else {
            log.debug("Feign: no Authorization header and no service token available");
        }
    }
}
