# Requirements: Repository Patch

## 1. Business Purpose
When upgrading from a previous version, apply the `sc:webable` aspect to all existing
`sc:doc` documents that do not yet have it, so that the new web-publishing rules work
correctly on pre-existing content. This is a one-time data migration.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: repository-patch
- **Platform module**: repository-patch
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an administrator, when upgrading from a previous version, all existing `sc:doc`
  documents automatically receive the `sc:webable` aspect without manual intervention.
- As an administrator, the patch runs exactly once and is recorded so it never repeats.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:doc` extends `cm:content`
  - `sc:isActive` (d:boolean, optional)

### Aspects
- `sc:webable`
  - `sc:published` (d:boolean, mandatory)
  - `sc:publishedTime` (d:datetime, optional)

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Repository patch requirements
- **Patch name**: `AddWebableAspect`
- **Patch ID**: `patch.repository-patch.addWebableAspect`
- **fixesFromSchema**: `0`
- **fixesToSchema**: `5026`
- **targetSchema**: `5026`
- **Logic**: query for all `sc:doc` nodes without `sc:webable` aspect; apply the aspect
  with default values (`sc:published=false`); return summary count.
- Must extend `AbstractPatch`
- Must override `applyInternal()` and return a descriptive string
- Must use inherited `nodeService` and `searchService` fields (not re-declared)
- Must close ResultSet in finally block
- Must check `nodeService.exists()` before acting
- Must use `LANGUAGE_FTS_ALFRESCO` — not `LANGUAGE_LUCENE`
- Must not use `@Transactional` or `RetryingTransactionHelper`

## 8. Deployment Requirements
- Platform JAR with patch bean registered in `patch-context.xml`.
- `patch-context.xml` imported from `module-context.xml`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | AddWebableAspectPatch.java, patch-context.xml | AddWebableAspectPatchTest.java |
| US-02 | patch-context.xml (basePatch parent) | |
