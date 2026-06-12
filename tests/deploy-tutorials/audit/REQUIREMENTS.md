# Requirements: Audit Deploy Test

## 1. Business Purpose
Validate that a custom audit application can be built with Maven, deployed inside ACS 26.1 via
Docker Compose, registered with the audit model registry, and reported as an enabled application
through the Audit admin REST endpoint.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: deploy-test-audit
- **Platform module**: deploy-test-audit
- **ACS version**: 26.1
- **Search profile**: Solr (Profile B — community default)

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17, Maven 3.9+
- Docker Compose v2

## 4. User Stories
- As a CI pipeline, the built JAR is mounted into the ACS container and ACS starts successfully.
- As an administrator, the Audit control endpoint reports the `sc` audit application as enabled.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:controlledDoc` extends `cm:content`

### Audit requirements
- **Audit application** `DocumentAccess`, key `sc` (must match `audit.sc.enabled`)
- Driven by the `alfresco-access` producer (`/alfresco-access/transaction` mapped to `/sc/transaction`)
- Record values: `user`, `action` (simpleValue)
- Enable properties: `audit.enabled=true`, `audit.sc.enabled=true`, `audit.alfresco-access.enabled=true`

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR mounted at:
  `/usr/local/tomcat/webapps/alfresco/WEB-INF/lib/deploy-test-audit-1.0.0-SNAPSHOT.jar`
- The audit enable properties must reach the ACS container's `alfresco-global.properties`
  (mounted or set via the `JAVA_OPTS`/global config in compose.yaml).
- Compose profile: Solr (no OpenSearch dependency for faster startup in CI)

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | compose.yaml (volume mount) | ACS /probes/-ready- returns 200 |
| US-02 | sc-audit.xml, audit-context.xml, audit enable properties | GET /api/audit/control/sc reports enabled |
