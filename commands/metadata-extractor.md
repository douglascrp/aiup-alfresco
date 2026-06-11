---
description: "Scaffold a custom Alfresco metadata extractor/embedder (extending AbstractMappingMetadataExtracter) with a properties mapping file, Spring registration, and unit test. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /metadata-extractor — Metadata Extractor Generator

> **In-Process SDK only** — metadata extractors deploy inside the ACS JVM as part of the
> Platform JAR. They map values found in a file's content into node **properties** at upload
> time — distinct from renditions/transforms (`/transforms`), which convert content into other
> content.

Generate a custom metadata extractor (and optional embedder) from requirements.

## Input

Read `REQUIREMENTS.md` to identify metadata extraction requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that
     `/metadata-extractor` only applies to the in-process Platform JAR project.

2. Read the "Metadata extraction requirements" sub-section (Section 7 Behaviour Requirements or
   a dedicated section).
   - If none are present, stop and ask the user to run `/requirements` first (or provide a
     description as `$ARGUMENTS`).
   - **Check coverage first**: ACS routes extraction for common formats (Office, PDF, images,
     audio/video) through the Transform Service's Tika engine. Only scaffold a custom in-process
     extractor for a **bespoke format** or a **custom source→property mapping** that the
     standard extractors do not provide.

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{package-path}` — `{java-package}` with dots replaced by slashes (resource path)
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from extraction requirements:
   - `{Name}` — PascalCase extractor name (e.g. `Contract`, `Invoice`)
   - `{sourceMimetype}` — the MIME type(s) the extractor supports
   - The source→target mapping: each raw key in the file → a content-model property QName
     (e.g. `vendor` → `{prefix}:vendor`)

---

## Output Files

> **The extractor class, the mapping properties file, and the Spring registration are
> required.** Generate the unit test alongside them.

### 1. Extractor Class
`{platform-project-root}/src/main/java/{package}/metadata/{Name}MetadataExtracter.java`

```java
package {package}.metadata;

import org.alfresco.repo.content.MimetypeMap;
import org.alfresco.repo.content.metadata.AbstractMappingMetadataExtracter;
import org.alfresco.service.cmr.repository.ContentReader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class {Name}MetadataExtracter extends AbstractMappingMetadataExtracter {

    private static final Logger LOG = LoggerFactory.getLogger({Name}MetadataExtracter.class);

    // Raw keys this extractor produces — mapped to QNames in the .properties mapping file
    private static final String KEY_EXAMPLE = "example";

    public {Name}MetadataExtracter() {
        // Declare the MIME types this extractor supports
        super(Set.of("{sourceMimetype}"));
    }

    @Override
    protected Map<String, Serializable> extractRaw(ContentReader reader) throws Throwable {
        Map<String, Serializable> rawProperties = new HashMap<>();
        // Read from reader.getContentInputStream() and populate rawProperties
        // putRawValue(KEY_EXAMPLE, value, rawProperties);
        return rawProperties;
    }
}
```

Key rules for the extractor class:
- Extend `org.alfresco.repo.content.metadata.AbstractMappingMetadataExtracter` — it owns the
  mapping/overwrite lifecycle; you implement only `extractRaw(ContentReader)`.
- Declare supported MIME types via the `super(Set.of(...))` constructor (or the
  `supportedMimetypes` property in XML).
- `extractRaw` returns a `Map<String, Serializable>` of **raw keys** (not QNames). The base class
  applies the mapping file to translate raw keys into content-model properties.
- Read content from `reader.getContentInputStream()`; never touch the filesystem directly.
- The default mapping is loaded from a `.properties` file colocated with the class (see below);
  do not hardcode QNames in `extractRaw`.

### 2. Default Mapping Properties
`{platform-project-root}/src/main/resources/{package-path}/metadata/{Name}MetadataExtracter.properties`

```properties
# Namespace prefixes used in the mapping (must match the content model)
namespace.prefix.{prefix}=http://www.{company}.com/model/content/1.0
namespace.prefix.cm=http://www.alfresco.org/model/content/1.0

# rawKey=targetProperty[, additionalTargetProperty]
example={prefix}:exampleProperty
```

Key rules for the mapping file:
- It must be **colocated with the extractor class** (same package path under `resources/`) and
  named `{Name}MetadataExtracter.properties` — `AbstractMappingMetadataExtracter` loads it by
  class name automatically.
- Declare every namespace prefix used on the right-hand side via `namespace.prefix.{prefix}=URI`.
- Each `rawKey=targetQName` line maps a key returned by `extractRaw` to a content-model property.

### 3. Spring Registration
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/metadata-extractor-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <bean id="{prefix}.{name}MetadataExtracter"
          class="{package}.metadata.{Name}MetadataExtracter"
          parent="baseMetadataExtracter">
        <property name="registry" ref="metadataExtracterRegistry"/>
    </bean>

</beans>
```

Add the import to `module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/metadata-extractor-context.xml"/>
```

Key rules for registration:
- Use `parent="baseMetadataExtracter"` and inject `registry` ref `metadataExtracterRegistry` —
  the extractor self-registers with the registry on init.
- Bean ID: `{prefix}.{name}MetadataExtracter`.

### 4. Unit Test
`{platform-project-root}/src/test/java/{package}/metadata/{Name}MetadataExtracterTest.java`

```java
package {package}.metadata;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

class {Name}MetadataExtracterTest {

    private {Name}MetadataExtracter extracter;

    @BeforeEach
    void setUp() {
        extracter = new {Name}MetadataExtracter();
    }

    @Test
    void supportsConfiguredMimetype() {
        assertTrue(extracter.getSupportedMimetypes().contains("{sourceMimetype}"));
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Extractor class location: `src/main/java/{package}/metadata/`
- Mapping file: colocated with the class, named `{Name}MetadataExtracter.properties`
- Bean ID: `{prefix}.{name}MetadataExtracter`; bean parent `baseMetadataExtracter`; registry ref `metadataExtracterRegistry`
- Map raw keys to QNames in the `.properties` file — never hardcode QNames in `extractRaw`
- Never read the filesystem directly — read from `ContentReader.getContentInputStream()`
- Never generate metadata extractors inside the Event Handler project

## Extraction vs Transformation
Use `/metadata-extractor` to populate node **properties** from file content (content → metadata).
Use `/transforms` to produce a different **content** representation, e.g. a PDF preview or
thumbnail (content → content). The two are independent ACS subsystems.

## Embedders
An embedder writes node properties back into the file's content (the inverse direction). It is
also based on `AbstractMappingMetadataExtracter` with embedding enabled; scaffold it only when
the requirements explicitly call for writing metadata into the binary.
