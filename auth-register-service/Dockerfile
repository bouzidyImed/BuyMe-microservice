# Stage 1: build the jar
ARG REGISTRY=
FROM ${REGISTRY}maven:3.9.4-jdk-17-slim AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: run the jar
FROM ${REGISTRY}openjdk:17-jdk-slim
VOLUME /tmp
VOLUME /uploads
COPY --from=build /app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]