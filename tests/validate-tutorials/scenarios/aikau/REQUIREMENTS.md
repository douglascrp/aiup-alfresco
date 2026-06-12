# Requirements: Aikau Page

## 1. Business Purpose
Add a custom Aikau page to the legacy Share UI that composes existing Aikau widgets into a
simple list view, so users get a lightweight custom page without a full Surf component build.

## 2. Project Architecture
- **Extension type**: Share JAR
- **groupId**: com.someco
- **artifactId**: aikau
- **Share module**: aikau
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community, Share 26.1
- Java 17
- Maven 3.9+

## 4. User Stories
- As a Share user, I can open a custom Aikau page whose page model composes standard Aikau
  widgets into a list layout.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Aikau requirements
- Page id: `document-summary`
- Page web script descriptor + page-model JavaScript composing existing Aikau widgets
- No custom widget module required (composition only)

## 8. Deployment Requirements
- Share JAR with the Aikau page descriptor and page-model JS under `alfresco/site-webscripts/`.
- No Aikau files written under `alfresco/module/...`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | {page-id}.get.desc.xml, {page-id}.get.js (widgets model) | (structure validation) |
