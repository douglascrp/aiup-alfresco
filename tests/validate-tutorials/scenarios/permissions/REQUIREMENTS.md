# Requirements: Custom Permissions

## 1. Business Purpose
Define a custom permission model for controlled documents: a `Publisher` permission group that
can `Publish` and `Withdraw` documents of type `sc:controlledDoc`, plus a dynamic authority that
grants the assigned reviewer publish rights on the documents they own.

## 2. Project Architecture
- **Extension type**: Platform JAR (in-process)
- **groupId**: com.someco
- **artifactId**: permissions
- **Platform module**: permissions
- **ACS version**: 26.1

## 3. Target Environment
- ACS 26.1.0 Community
- Java 17
- Maven 3.9+

## 4. User Stories
- As an administrator, I can grant the `Publisher` permission group on a `sc:controlledDoc`,
  which composes core `Read` with custom `Publish` and `Withdraw` permissions.
- As the assigned reviewer of a document, I am dynamically granted publish rights on that
  document without an explicit ACL entry.

## 5. Content Model Requirements
- **Namespace URI**: `http://www.someco.com/model/content/1.0`
- **Prefix**: `sc`

### Types
- `sc:controlledDoc` extends `cm:content`
  - `sc:reviewer` (d:text, optional) — username of the assigned reviewer

### Permission requirements
- **Permission set** bound to `sc:controlledDoc`
- **Permission group `Publisher`** (expose=true): includes core `Read` + custom `Publish` + `Withdraw`
- **Permissions `Publish`, `Withdraw`** (expose=true), each backed by its own group
- **Dynamic authority `Reviewer`**: grants publish rights to the user named in `sc:reviewer`
- Permission group/permission names must be project-scoped — never reuse built-in names

## 6. API Requirements
None.

## 7. Behaviour Requirements
None.

## 8. Deployment Requirements
- Platform JAR with the extension permission model registered (parent `permissionModelBootstrap`).
- `permissions-context.xml` imported from `module-context.xml`.
- Dynamic authority bean added to the global `dynamicAuthorities` list.

## 9. Traceability Matrix
| Requirement | Artefact | Test |
|-------------|---------|------|
| US-01 | sc-permissionDefinitions.xml, permissions-context.xml | (XML validation) |
| US-02 | ReviewerDynamicAuthority.java, permissions-context.xml | ReviewerDynamicAuthorityTest.java |
