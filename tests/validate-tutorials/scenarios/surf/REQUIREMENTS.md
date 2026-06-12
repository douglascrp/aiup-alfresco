# Requirements: Surf Extension

## 1. Business Purpose
Add a custom Surf page and component to the legacy Share UI via a Surf extension module, so a
new "Compliance Dashboard" page is available under Share with its own server-side web script.

## 2. Project Architecture
- **Extension type**: Share JAR
- **groupId**: com.someco
- **artifactId**: surf
- **Share module**: surf
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community, Share 26.1
- Java 17
- Maven 3.9+

## 4. User Stories
- As a Share user, I can open a custom "Compliance Dashboard" page served by a Surf page web
  script registered through a Surf extension module.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

## 6. API Requirements
None.

## 7. Behaviour Requirements
### Surf requirements
- Surf extension module registering one page component
- Page id: `compliance-dashboard`
- Page web script descriptor + controller config + template under `site-webscripts/`

## 8. Deployment Requirements
- Share JAR with the Surf extension metadata under
  `alfresco/web-extension/site-data/extensions/`.
- Page web script artefacts under `alfresco/site-webscripts/`.
- No Surf files written under `alfresco/module/...`.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | extensions/{name}.xml (module), {page-id}.get.desc.xml | (structure validation) |
