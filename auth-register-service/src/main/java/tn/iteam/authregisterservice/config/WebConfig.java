package tn.iteam.authregisterservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.lang.NonNull;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.upload.dir}")
    private String uploadDirRoot;

    @Override
    public void addResourceHandlers(@NonNull ResourceHandlerRegistry registry) {
        registry
                .addResourceHandler("/uploads/resumes/**")
                .addResourceLocations("file:" + uploadDirRoot + "/resumes/");

        registry
                .addResourceHandler("/uploads/profile-pictures/**")
                .addResourceLocations("file:" + uploadDirRoot + "/profile-pictures/");

        registry
                .addResourceHandler("/uploads/tasks/**")
                .addResourceLocations("file:" + uploadDirRoot + "/tasks/");

        registry
                .addResourceHandler("/uploads/services/**")
                .addResourceLocations("file:" + uploadDirRoot + "/services/");

        registry
                .addResourceHandler("/uploads/categories/**")
                .addResourceLocations("file:" + uploadDirRoot + "/categories/");
    }
    /*@Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")                  // allow CORS for all paths
                .allowedOrigins("http://localhost:4200") // Angular dev server
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }*/
}


