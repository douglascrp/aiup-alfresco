# Requirements: Custom Content Store

## 1. Business Purpose
Provide a custom content store that writes binaries to a configurable backing location,
activated as the repository's content store. The store must route all I/O through Alfresco's
reader/writer abstractions so renditions, eventing, and caching continue to work.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: content-store
- **Platform module**: content-store
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an administrator, the repository writes content to my custom backing store at a
  configurable root location.
- As a developer, the store integrates transparently — content is read and written through
  `ContentReader`/`ContentWriter`, not the filesystem directly.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
### Content store requirements
- **Store name**: `Tiered`
- **Shape**: standalone backing store extending `AbstractContentStore`
- **Root location property**: `dir.contentstore.sc` (default `${dir.contentstore}`)
- Activated as the `fileContentStore` bean via an `alfresco/extension/` context file
- Reader/writer extend `AbstractContentReader` / `AbstractContentWriter`
- No filesystem access outside the reader/writer channels; no hardcoded paths/credentials

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | TieredContentStore.java, sc-content-store-context.xml | TieredContentStoreTest.java |
| US-02 | TieredContentReader.java, TieredContentWriter.java | TieredContentStoreTest.java |
