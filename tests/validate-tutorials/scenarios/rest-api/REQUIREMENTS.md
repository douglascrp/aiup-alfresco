# Requirements: REST API (v1 Public API)

## 1. Business Purpose
Expose a modern, paged v1 Public REST API for managing vendor contracts held in the
repository, plus a nested sub-collection of the payments belonging to each contract. The API
must use the annotation-based framework (not classic Web Scripts) so clients get standard
paging and content negotiation.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: rest-api
- **Platform module**: rest-api
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an API client, I can `GET .../vendor-contracts` to retrieve a paged list of vendor contracts.
- As an API client, I can `GET .../vendor-contracts/{id}` to retrieve a single contract by id.
- As an API client, I can `GET .../vendor-contracts/{id}/payments` to retrieve the payments
  nested under a contract.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:vendorContract` extends `cm:content`
  - `sc:vendor` (d:text, mandatory)
  - `sc:expiryDate` (d:date, optional)

## 6. API Requirements
- **Entity resource — `VendorContract`**
  - Collection name: `vendor-contracts`
  - Operations: Read (list) and ReadById (single)
  - Returns paged collections via `CollectionWithPagingInfo`
- **Relationship resource — `payments`**
  - Nested under `vendor-contracts/{id}/payments`
  - Operation: Read (list)
- The model POJO must expose a `@UniqueId` identifier getter.
- Resources must be annotation-based (`@EntityResource` / `@RelationshipResource`) — not
  `DeclarativeWebScript`.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR with resource beans registered in `webscript-context.xml`.
- `webscript-context.xml` imported from `module-context.xml`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | VendorContractEntityResource.java (readAll), webscript-context.xml | VendorContractEntityResourceTest.java |
| US-02 | VendorContractEntityResource.java (readById), VendorContract.java | VendorContractEntityResourceTest.java |
| US-03 | VendorContractPaymentsRelationshipResource.java | VendorContractEntityResourceTest.java |
