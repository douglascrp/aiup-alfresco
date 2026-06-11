# Requirements: Custom Metadata Extractor

## 1. Business Purpose
Extract structured metadata from a bespoke contract file format and map it into custom content
model properties at upload time, so contracts are searchable by vendor and effective date
without manual data entry.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: metadata-extractor
- **Platform module**: metadata-extractor
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As a records manager, when I upload a contract file the `sc:vendor` and `sc:effectiveDate`
  properties are populated automatically from the file content.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:contract` extends `cm:content`
  - `sc:vendor` (d:text, optional)
  - `sc:effectiveDate` (d:date, optional)

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Metadata extraction requirements
- **Extractor name**: `Contract`
- **Source MIME type**: `application/x-someco-contract`
- Mapping: `vendor` → `sc:vendor`, `effectiveDate` → `sc:effectiveDate`
- Extends `AbstractMappingMetadataExtracter`; implements `extractRaw`
- Mapping declared in a colocated `ContractMetadataExtracter.properties` file
- Registered with `parent="baseMetadataExtracter"` and `metadataExtracterRegistry`

## 8. Deployment Requirements
- Platform JAR with the extractor bean registered and the mapping file on the classpath.
- `metadata-extractor-context.xml` imported from `module-context.xml`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | ContractMetadataExtracter.java, ContractMetadataExtracter.properties, metadata-extractor-context.xml | ContractMetadataExtracterTest.java |
