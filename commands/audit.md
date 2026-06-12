---
description: "Generate a custom Alfresco audit application (audit XML + data extractors/generators + enable properties) and optional query Web Script. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /audit — Custom Audit Application Generator

> **In-Process SDK only** — audit applications deploy inside the ACS JVM as part of the
> Platform JAR. They record audit data driven by repository actions and audit-producing
> services (e.g. the `alfresco-access` data producer).

Generate a custom audit application, its data extractors/generators, and the properties that
enable it, from requirements.

## Input

Read `REQUIREMENTS.md` to identify audit requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/audit`
     only applies to the in-process Platform JAR project.

2. Read the "Audit requirements" sub-section (Section 7 Behaviour Requirements or a dedicated
   audit section).
   - If no audit requirements are present, stop and ask the user to run `/requirements` first
     (or provide a description as `$ARGUMENTS`).
   - Identify which **audit data producer** drives the application (commonly `alfresco-access`
     for node CRUD; or a custom audit call), and which values must be recorded.

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from audit requirements:
   - `{App}` — PascalCase audit application name (e.g. `DocumentAccess`)
   - `{app-key}` — the application key, conventionally `{prefix}` or `{prefix}-{app}` (lowercase)
   - The audit paths/values to record (e.g. node ref, user, action, a custom property)
   - Whether a **custom data extractor** is needed (to derive a recorded value from the audit
     data map) and/or a **data generator** (to inject a value not present in the source data)

---

## Output Files

> **The audit application XML, the context registration, and the enable properties are
> required.** Generate a data extractor/generator + its unit test only when the requirements
> need a value that the standard extractors (`simpleValue`, `nullValue`) cannot provide.

### 1. Audit Application XML
`{platform-project-root}/src/main/resources/alfresco/extension/audit/{prefix}-audit.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Audit xmlns="http://www.alfresco.org/repo/audit/model/3.2"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.alfresco.org/repo/audit/model/3.2 alfresco-audit-3.2.xsd">

    <DataExtractors>
        <!-- Built-in simpleValue extractor; add custom extractors as registered beans -->
        <DataExtractor name="simpleValue"
                       registeredName="auditModel.extractor.simpleValue"/>
        <DataExtractor name="{name}Extractor"
                       registeredName="{prefix}.{name}DataExtractor"/>
    </DataExtractors>

    <DataGenerators>
        <!-- Optional: generators inject values not present in the source data map -->
    </DataGenerators>

    <PathMappings>
        <!-- Map a data producer's root path into this application's namespace -->
        <PathMap source="/alfresco-access/transaction" target="/{app-key}/transaction"/>
    </PathMappings>

    <Application name="{App}" key="{app-key}">
        <AuditPath key="transaction">
            <RecordValue key="user"   dataExtractor="simpleValue" dataSource="/{app-key}/transaction/user"/>
            <RecordValue key="action" dataExtractor="simpleValue" dataSource="/{app-key}/transaction/action"/>
            <RecordValue key="custom" dataExtractor="{name}Extractor" dataSource="/{app-key}/transaction/path"/>
        </AuditPath>
    </Application>

</Audit>
```

Key rules for the audit application XML:
- The root `<Audit>` element must declare the audit model namespace
  `http://www.alfresco.org/repo/audit/model/3.2`.
- `<Application name="{App}" key="{app-key}">` — the `key` is the storage key and the first
  path segment; it must be lowercase and prefix-scoped, and it must match the `audit.{app-key}`
  property used to enable the application.
- Every `<RecordValue>` `dataExtractor` must reference a `<DataExtractor>` declared above (by
  its `name`), whose `registeredName` matches a Spring bean's registered name.
- `<PathMappings>` map a data producer's emitted path (e.g. `/alfresco-access/transaction`)
  into this application's namespace so `dataSource` paths resolve.

### 2. Data Extractor Class (optional)
`{platform-project-root}/src/main/java/{package}/audit/extractor/{Name}DataExtractor.java`

```java
package {package}.audit.extractor;

import org.alfresco.repo.audit.extractor.AbstractDataExtractor;

import java.io.Serializable;

public class {Name}DataExtractor extends AbstractDataExtractor {

    @Override
    public boolean isSupported(Serializable data) {
        // Return true for the data shapes this extractor can handle
        return data != null;
    }

    @Override
    public Serializable extractData(Serializable in) throws Throwable {
        // Derive and return the value to record from the source audit data
        return in;
    }
}
```

Key rules for the data extractor:
- Extend `org.alfresco.repo.audit.extractor.AbstractDataExtractor` — it registers itself with
  the `auditModelRegistry` via its `registeredName` when wired with `parent="auditModelExtractorBase"`.
- `isSupported(Serializable)` gates whether `extractData` is called for a given value.
- `extractData(Serializable)` returns the value actually stored in the audit entry.

### 3. Context Registration
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/audit-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- Register the audit application model so the auditModelRegistry loads it -->
    <bean id="{prefix}.auditModel"
          class="org.alfresco.repo.audit.model.AuditModelRegistrationBean"
          init-method="registerModel">
        <property name="auditModelRegistry" ref="auditModel.modelRegistry"/>
        <property name="auditModelUrl"
                  value="classpath:alfresco/extension/audit/{prefix}-audit.xml"/>
    </bean>

    <!-- Register the custom data extractor (only if generated) -->
    <bean id="{prefix}.{name}DataExtractor"
          class="{package}.audit.extractor.{Name}DataExtractor"
          parent="auditModelExtractorBase">
        <property name="registeredName" value="{prefix}.{name}DataExtractor"/>
    </bean>

</beans>
```

Also add the import to `module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/audit-context.xml"/>
```

Key rules for registration:
- Register the application XML via `AuditModelRegistrationBean` with `init-method="registerModel"`,
  pointing `auditModelUrl` at the audit XML on the classpath.
- A custom extractor bean uses `parent="auditModelExtractorBase"` and sets `registeredName` to
  the value referenced from the audit XML `<DataExtractor registeredName="...">`.

### 4. Enable Properties
Add to `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/alfresco-global.properties`
(or document for the deployer's `alfresco-global.properties`):

```properties
# Auditing must be globally enabled, then the specific application enabled by key
audit.enabled=true
audit.{app-key}.enabled=true
# The alfresco-access producer must be enabled if this app maps its data
audit.alfresco-access.enabled=true
```

Key rules:
- `audit.enabled=true` is the master switch; without it no application records anything.
- `audit.{app-key}.enabled=true` enables this specific application — the `{app-key}` must match
  the `<Application key="...">` value exactly.

### 5. Unit Test (optional — only when a data extractor is generated)
`{platform-project-root}/src/test/java/{package}/audit/extractor/{Name}DataExtractorTest.java`

```java
package {package}.audit.extractor;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class {Name}DataExtractorTest {

    private {Name}DataExtractor extractor;

    @BeforeEach
    void setUp() {
        extractor = new {Name}DataExtractor();
    }

    @Test
    void isSupported_returnsTrueForNonNull() {
        assertTrue(extractor.isSupported("value"));
    }

    @Test
    void extractData_returnsExpectedValue() throws Throwable {
        assertEquals("value", extractor.extractData("value"));
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Audit XML location: `alfresco/extension/audit/{prefix}-audit.xml`
- Application `key`: lowercase, prefix-scoped; must match `audit.{app-key}.enabled`
- Extractor bean ID and `registeredName`: `{prefix}.{name}DataExtractor`; bean parent `auditModelExtractorBase`
- Never generate audit applications inside the Event Handler project
- After generating files, invoke the `audit-config-validator` skill

## Querying Audit Data
Recorded audit entries are queryable via the Audit REST API
(`/alfresco/s/api/audit/query/{app-key}`, admin auth) and via `AuditService`. To expose a
tailored audit query endpoint, generate a Web Script with `/web-scripts` or a v1 resource with
`/rest-api`.
