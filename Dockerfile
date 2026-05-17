FROM gradle:9.2.1-jdk17 AS build

WORKDIR /app
COPY . /app

RUN gradle clean build

FROM quay.io/wildfly/wildfly:26.1.2.Final-jdk17 AS wildfly

RUN /opt/jboss/wildfly/bin/add-user.sh admin admin_password --silent

COPY --from=build /app/build/libs/lab3.war /opt/jboss/wildfly/standalone/deployments/

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
