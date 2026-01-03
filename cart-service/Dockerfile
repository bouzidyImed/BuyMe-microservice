FROM maven:3.9.4-jdk-17-slim AS build
WORKDIR /app
COPY . /app
RUN mvn -B -DskipTests clean package

FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/target/*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
