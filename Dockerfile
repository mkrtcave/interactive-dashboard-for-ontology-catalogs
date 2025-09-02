FROM node:14.16.1 AS frontend-build
RUN git clone https://github.com/opendata-mvcr/dashboard-indexer-frontend.git /indexer-frontend
WORKDIR /indexer-frontend
RUN npm install
RUN npm run build

FROM maven:3.8.5-openjdk-17-slim AS server-build
COPY --from=frontend-build /indexer-frontend/build indexer/frontend/build
COPY dashboard-for-ontologies /dashboard-for-ontologies
COPY indexer /indexer
COPY pom.xml /pom.xml
RUN mvn -f /pom.xml clean package

FROM openjdk:17.0.2-slim
EXPOSE 8080
COPY --from=server-build indexer/target/eea-rdf-river-indexer-*-altered.jar app.jar
ENTRYPOINT java -jar -Xmx8192M  -Xms2048M app.jar