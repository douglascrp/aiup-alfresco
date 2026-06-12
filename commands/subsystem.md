---
description: "Scaffold a custom Alfresco subsystem (ChildApplicationContextFactory + default/instance properties) or, in authentication mode, configure a custom authentication chain / external IdP (LDAP, identity-service/OIDC, external). In-Process SDK (Maven) / config."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /subsystem — Custom Subsystem & Authentication Generator

> **In-Process SDK / configuration.** A subsystem is a self-contained, independently
> configurable child application context inside the ACS JVM. This command has two modes:
> - **Generic mode** — a custom subsystem (e.g. a pluggable integration service) declared via
>   `ChildApplicationContextFactory` with default and instance properties.
> - **Authentication mode** — configure ACS's `Authentication` subsystem chain (e.g. `ldap`,
>   `identity-service`/OIDC, `external`). A custom authentication chain **is** a subsystem, so it
>   shares the same mechanism. Authentication mode is config-oriented — it never commits secrets.

Generate a custom subsystem or an authentication-chain configuration from requirements.

## Input

Read `REQUIREMENTS.md` to identify subsystem requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/subsystem`
     only applies to the in-process Platform JAR project.

2. Read the "Subsystem requirements" sub-section (Section 8 Deployment Requirements or a
   dedicated section). Determine the **mode**:
   - **Authentication mode** if the requirement is about login/identity (LDAP sync, SSO/OIDC,
     SAML via identity-service, external auth).
   - **Generic mode** otherwise (a custom configurable service subsystem).
   - If no subsystem requirements are present, stop and ask the user to run `/requirements` first
     (or provide a description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from subsystem requirements:
   - **Generic mode**: `{Category}` (subsystem category, e.g. `Integrations`), `{type}` (type
     name, e.g. `myService`), `{instance}` (instance id, e.g. `default`), `{Service}` (managed
     bean PascalCase name)
   - **Authentication mode**: the chain entries (`{instance}:{type}`, e.g. `ldap1:ldap`,
     `keycloak:identity-service`, `ext:external`) in order, and the per-instance properties

---

## Output Files — Generic Mode

> **The subsystem context, the default properties, and the instance override are required.**
> Generate a managed service bean when the subsystem exposes custom logic.

### 1. Subsystem Context
`{platform-project-root}/src/main/resources/alfresco/subsystems/{Category}/{type}/{prefix}-subsystem-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!--
        Beans defined here live in the subsystem's CHILD application context.
        Properties are resolved from {prefix}-default.properties (overridable per instance).
        Do NOT redefine core repository beans here — the child context is isolated.
    -->
    <bean id="{prefix}.{service}" class="{package}.subsystem.{Service}Service">
        <property name="endpoint" value="${{prefix}.{type}.endpoint}"/>
        <property name="enabled"  value="${{prefix}.{type}.enabled}"/>
    </bean>

</beans>
```

### 2. Default Properties
`{platform-project-root}/src/main/resources/alfresco/subsystems/{Category}/{type}/{prefix}-default.properties`

```properties
# Default values for every property referenced in the subsystem context.
# These are the fallback; instance properties (below) override them.
{prefix}.{type}.enabled=false
{prefix}.{type}.endpoint=
```

### 3. ChildApplicationContextFactory Registration
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/subsystem-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- Declares the subsystem and its category/type so ACS can manage it -->
    <bean id="{prefix}.{type}" parent="abstractPropertyBackedBean">
        <property name="autoStart" value="true"/>
        <property name="category"  value="{Category}"/>
        <property name="typeName"  value="{type}"/>
        <property name="instancePath">
            <list><value>{type}</value></list>
        </property>
    </bean>

</beans>
```

Add the import to `module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/subsystem-context.xml"/>
```

### 4. Instance Override (deployer-supplied)
`{platform-project-root}/src/main/resources/alfresco/extension/subsystems/{Category}/{type}/{instance}/{instance}.properties`

```properties
# Per-instance overrides; placed on the extension classpath so deployers can change them
# without rebuilding. NEVER commit secrets here — inject via environment/encrypted properties.
{prefix}.{type}.enabled=true
{prefix}.{type}.endpoint=${{PREFIX}_{TYPE}_ENDPOINT:http://localhost:9000}
```

### 5. Managed Service Bean (optional)
`{platform-project-root}/src/main/java/{package}/subsystem/{Service}Service.java`

```java
package {package}.subsystem;

public class {Service}Service {

    private String endpoint;
    private boolean enabled;

    public void setEndpoint(String endpoint) { this.endpoint = endpoint; }
    public void setEnabled(boolean enabled)   { this.enabled = enabled; }

    public String getEndpoint() { return endpoint; }
    public boolean isEnabled()  { return enabled; }
}
```

Key rules for generic mode:
- The subsystem is declared by a bean with `parent="abstractPropertyBackedBean"` carrying
  `category`, `typeName`, and `instancePath`. ACS creates an isolated child application context
  from `alfresco/subsystems/{Category}/{type}/*-context.xml` with `*-default.properties`.
- The child context is **isolated** — never redefine core repository beans inside it.
- Every property used in the context must have a default in `{prefix}-default.properties`.
- Instance overrides live on the **extension classpath**
  (`alfresco/extension/subsystems/{Category}/{type}/{instance}/`) and must never contain secrets.

---

## Output Files — Authentication Mode

> Authentication mode is **configuration**, not Java. It composes ACS's built-in authentication
> subsystem types into a chain and supplies per-instance properties. Secrets come from the
> environment at deploy time — never from committed files.

### 1. Authentication Chain Property
Document for the deployer's `alfresco-global.properties` (or set via the ACS container's config):

```properties
# Ordered chain: {instanceName}:{type}. The first instance to authenticate wins.
# Keep the default alfrescoNtlm instance first unless a full replacement is intended.
authentication.chain=alfrescoNtlm1:alfrescoNtlm,ldap1:ldap,keycloak:identity-service
```

### 2. LDAP Instance Properties (when an `ldap` / `ldap-ad` instance is in the chain)
`{platform-project-root}/src/main/resources/alfresco/extension/subsystems/Authentication/ldap/ldap1/ldap1.properties`

```properties
ldap.authentication.active=true
ldap.authentication.userNameFormat=%s
ldap.authentication.java.naming.provider.url=${LDAP_URL:ldap://ldap:389}
ldap.synchronization.active=true
ldap.synchronization.userQuery=(objectclass=inetOrgPerson)
# Bind credentials come from the environment — NEVER commit them
ldap.synchronization.java.naming.security.principal=${LDAP_BIND_DN}
ldap.synchronization.java.naming.security.credentials=${LDAP_BIND_PASSWORD}
```

### 3. Identity Service (OIDC/Keycloak/SAML) Instance Properties
`{platform-project-root}/src/main/resources/alfresco/extension/subsystems/Authentication/identity-service/keycloak/keycloak.properties`

```properties
identity-service.auth-server-url=${IDENTITY_SERVICE_URL:http://keycloak:8080}
identity-service.realm=${IDENTITY_SERVICE_REALM:alfresco}
identity-service.resource=${IDENTITY_SERVICE_CLIENT:alfresco}
identity-service.authentication.enable-username-password-authentication=true
identity-service.authentication.validation.failure.silent=false
# Client secret comes from the environment — NEVER commit it
identity-service.credentials.secret=${IDENTITY_SERVICE_SECRET}
```

Key rules for authentication mode:
- `authentication.chain` is an ordered, comma-separated list of `{instanceName}:{type}`. Valid
  types include `alfrescoNtlm`, `ldap`, `ldap-ad`, `passthru`, `kerberos`, `external`, and
  `identity-service` (OIDC/Keycloak — the modern OAuth2/SAML path; preferred for new deployments).
- Per-instance properties live under
  `alfresco/extension/subsystems/Authentication/{type}/{instance}/{instance}.properties`.
- **Never commit secrets** (bind passwords, client secrets) — reference environment variables
  (`${LDAP_BIND_PASSWORD}`, `${IDENTITY_SERVICE_SECRET}`) resolved at deploy time.
- Prefer `identity-service` (OAuth2/OIDC via Keycloak) for new production deployments;
  `alfrescoNtlm`/ticket-based is the compatibility fallback.

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Subsystem context location: `alfresco/subsystems/{Category}/{type}/`; instance overrides:
  `alfresco/extension/subsystems/{Category}/{type}/{instance}/`
- Subsystem bean: `parent="abstractPropertyBackedBean"` with `category`/`typeName`/`instancePath`
- Every context property must have a default in `{prefix}-default.properties`
- **Never commit secrets** in any subsystem or authentication properties file
- Never redefine core repository beans inside a subsystem child context
- Never generate subsystems inside the Event Handler project
