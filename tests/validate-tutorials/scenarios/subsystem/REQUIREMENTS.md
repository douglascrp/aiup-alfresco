# Requirements: Custom Subsystem

## 1. Business Purpose
Provide a custom, independently-configurable integration subsystem that connects the repository
to an external notification service. The subsystem must expose a configurable endpoint and an
enabled flag, with safe defaults and per-instance overrides on the extension classpath, and must
never hold secrets in committed files.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: subsystem
- **Platform module**: subsystem
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an administrator, I can enable/disable the integration and set its endpoint via subsystem
  properties without rebuilding the JAR.
- As a developer, the subsystem runs in an isolated child application context managed by ACS.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
### Subsystem requirements
- **Mode**: generic
- **Category**: `Integrations`
- **Type**: `notifier`
- **Instance**: `default`
- **Managed service**: `Notifier` with `endpoint` and `enabled` properties
- Declared via `ChildApplicationContextFactory` (`parent="abstractPropertyBackedBean"`)
- Defaults in `sc-default.properties`; instance override under
  `alfresco/extension/subsystems/Integrations/notifier/default/`
- No secrets in any committed properties file (use environment variables)

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | sc-default.properties, default.properties (instance override) | (properties validation) |
| US-02 | sc-subsystem-context.xml, subsystem-context.xml (factory), NotifierService.java | (XML validation) |
