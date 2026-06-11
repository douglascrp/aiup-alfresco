# Requirements: Event Listener (Out-of-Process)

## 1. Business Purpose
Provide a Spring Boot Out-of-Process application that listens to Alfresco repository events via
ActiveMQ and logs every node-created event, so an external system can react asynchronously to
content changes without running inside the ACS JVM.

## 2. Project Architecture
- **Extension type**: Event Handler only (out-of-process Spring Boot)
- **groupId**: com.someco
- **artifactId**: events
- **Event Handler module**: events
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an integrator, when a node is created in the repository my external listener receives the
  `NodeCreatedEvent` and logs the node type and id.

## 5. Content Model Requirements
None.

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Event handler requirements
- Listen to `NodeCreatedEvent` on the default topic `alfresco.repo.event2`
- Log node type and id at INFO level on each event
- Consumer group: `sc.nodeCreatedListener`
- Dead-letter queue: `sc.nodeCreatedListener.DLQ`

## 8. Deployment Requirements
- Spring Boot app built via `mvn package` and run as a separate Docker Compose service.
- `pom.xml` parent is `alfresco-java-sdk` 7.2.0; depends on
  `alfresco-java-event-api-spring-boot-starter`.
- `application.properties` configures the ActiveMQ broker URL and default exchange.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | NodeCreatedEventHandler.java (@AlfrescoEventListener), application.properties | (structure validation) |
