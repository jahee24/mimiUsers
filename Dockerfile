FROM gradle:8.11.1-jdk17 as build
WORKDIR /myapp
COPY . /myapp
RUN chmod +x gradlew
RUN ./gradlew clean build --no-daemon -x test
FROM openjdk:17-alpine
WORKDIR /myapp
COPY --from=build /myapp/build/libs/*.jar /myapp/mimiuser.jar
EXPOSE 5679
ENTRYPOINT ["java","-jar","/myapp/mimiuser.jar"]