FROM gradle:9.2.1-jdk17 AS build

WORKDIR /app
COPY . /app

RUN gradle clean build

FROM quay.io/wildfly/wildfly:26.1.2.Final-jdk17 AS wildfly

COPY --from=build /app/build/libs/lab3.war /opt/jboss/wildfly/standalone/deployments/
