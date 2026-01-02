FROM maven:3.8.8-eclipse-temurin-17 AS build
WORKDIR /app
COPY . /app
RUN mvn -B -DskipTests clean package

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
