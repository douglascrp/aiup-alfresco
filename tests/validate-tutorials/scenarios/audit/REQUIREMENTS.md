# Requirements: Custom Audit Application

## 1. Business Purpose
Record an audit trail of access to controlled documents: for every node access transaction,
capture the user, the action, and a derived "document classification" value extracted from the
audit data. The audit application is driven by the `alfresco-access` data producer.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: audit
- **Platform module**: audit
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a compliance officer, every access to a document is recorded with the acting user and action.
- As a compliance officer, a derived classification value is recorded for each entry via a
  custom data extractor.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:controlledDoc` extends `cm:content`

### Audit requirements
- **Audit application** `DocumentAccess`, key `sc` (must match `audit.sc.enabled`)
- Driven by the `alfresco-access` producer (`/alfresco-access/transaction` mapped to `/sc/transaction`)
- Record values: `user`, `action` (simpleValue), and `classification` via a custom extractor
- **Custom data extractor** `Classification` deriving the recorded classification value
- Enable properties: `audit.enabled=true`, `audit.sc.enabled=true`, `audit.alfresco-access.enabled=true`

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR with the audit application registered via `AuditModelRegistrationBean`.
- `audit-context.xml` imported from `module-context.xml`.
- Enable properties present in the project's `alfresco-global.properties`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | sc-audit.xml (user/action RecordValue), audit-context.xml | (XML validation) |
| US-02 | ClassificationDataExtractor.java, sc-audit.xml | ClassificationDataExtractorTest.java |
