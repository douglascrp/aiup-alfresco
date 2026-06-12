# Requirements: REST API Deploy Test

## 1. Business Purpose
Validate that a v1 Public REST API resource (annotation-based `@EntityResource`) can be built
with Maven, deployed inside ACS 26.1 via Docker Compose, and that the custom resource is
registered and routed under the public API namespace.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: deploy-test-restapi
- **Platform module**: deploy-test-restapi
- **ACS version**: 26.1
- **Search profile**: Solr (Profile B — community default)

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17, Maven 3.9+
- Docker Compose v2

## 4. User Stories
- As a CI pipeline, the built JAR is mounted into the ACS container and ACS starts successfully.
- As an API client, `GET .../public/alfresco/versions/1/widgets` returns HTTP 200 with a paged list.
- As an API client, `GET .../public/alfresco/versions/1/widgets/{unknown-id}` resolves to the
  resource (HTTP 404 for a missing id — proves the resource is registered and routed, not a 500).

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:widget` extends `cm:content`
  - `sc:code` (d:text, mandatory)

## 6. API Requirements
- **Entity resource — `Widget`**
  - Collection name: `widgets`
  - Operations: Read (list) and ReadById (single)
  - Returns paged collections via `CollectionWithPagingInfo`
  - `readAll` returns an empty paged collection if there is no data (still HTTP 200)
  - `readById` throws `EntityNotFoundException` for an unknown id (HTTP 404)
- The model POJO exposes a `@UniqueId` identifier getter.
- Annotation-based (`@EntityResource`) — not `DeclarativeWebScript`.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR mounted at:
  `/usr/local/tomcat/webapps/alfresco/WEB-INF/lib/deploy-test-restapi-1.0.0-SNAPSHOT.jar`
- Compose profile: Solr (no OpenSearch dependency for faster startup in CI)

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | compose.yaml (volume mount) | ACS /probes/-ready- returns 200 |
| US-02 | WidgetEntityResource.java (readAll), webscript-context.xml | GET .../widgets returns 200 |
| US-03 | WidgetEntityResource.java (readById) | GET .../widgets/missing returns 404 |
