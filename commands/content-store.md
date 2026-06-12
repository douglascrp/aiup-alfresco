---
description: "Scaffold a custom Alfresco ContentStore connector (extending AbstractContentStore, optionally wrapping a caching or encrypting store) with its reader/writer, Spring wiring, and unit test. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /content-store — Custom Content Store Generator

> **In-Process SDK only** — content stores deploy inside the ACS JVM as part of the Platform
> JAR. The repository reads/writes all binaries through the `ContentService`, which delegates
> to the configured content store. **Never** read or write files on the local filesystem
> directly — go through the store's `ContentReader`/`ContentWriter`.

Generate a custom content store connector from requirements.

## Input

Read `REQUIREMENTS.md` to identify content store requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/content-store`
     only applies to the in-process Platform JAR project.

2. Read the "Content store requirements" sub-section (Section 8 Deployment Requirements or a
   dedicated storage section).
   - If none are present, stop and ask the user to run `/requirements` first (or provide a
     description as `$ARGUMENTS`).
   - Identify the store **shape**: a brand-new backing store (extends `AbstractContentStore`),
     or a **wrapper** over the default store (caching / encrypting / aggregating).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from content store requirements:
   - `{Store}` — PascalCase store name (e.g. `S3`, `Encrypted`, `Tiered`)
   - `{store-root-property}` — the configurable root location property (e.g. `dir.contentstore.{prefix}`)
   - Whether the store wraps another store (composition) or is a standalone backing store

---

## Output Files

> **The content store class and its Spring wiring are required.** Generate dedicated
> reader/writer classes only for a standalone backing store; a wrapper store delegates to the
> wrapped store's reader/writer.

### 1. Content Store Class
`{platform-project-root}/src/main/java/{package}/content/{Store}ContentStore.java`

```java
package {package}.content;

import org.alfresco.repo.content.AbstractContentStore;
import org.alfresco.service.cmr.repository.ContentReader;
import org.alfresco.service.cmr.repository.ContentWriter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class {Store}ContentStore extends AbstractContentStore {

    private static final Logger LOG = LoggerFactory.getLogger({Store}ContentStore.class);

    private String rootLocation;

    @Override
    public boolean isWriteSupported() {
        return true;
    }

    @Override
    public ContentReader getReader(String contentUrl) {
        // Resolve contentUrl to a backing object and return a reader over it
        return new {Store}ContentReader(contentUrl, rootLocation);
    }

    @Override
    public ContentWriter getWriterInternal(ContentReader existingContentReader, String newContentUrl) {
        // newContentUrl may be null — generate one with createNewUrl()/newContentUrl if so
        String url = (newContentUrl != null) ? newContentUrl : createNewUrl();
        return new {Store}ContentWriter(url, rootLocation, existingContentReader);
    }

    @Override
    public String getRootLocation() {
        return rootLocation;
    }

    public void setRootLocation(String rootLocation) {
        this.rootLocation = rootLocation;
    }
}
```

Key rules for the content store class:
- Extend `org.alfresco.repo.content.AbstractContentStore` — it provides URL handling and the
  `getWriter(...)` template method that calls your `getWriterInternal(...)`.
- Implement `isWriteSupported()`, `getReader(String)`, `getWriterInternal(ContentReader, String)`,
  and `getRootLocation()`.
- Content URLs follow the `protocol://path` form (e.g. `store://...`); use the inherited helpers
  (`createNewUrl()`) to mint new URLs rather than hand-building them.
- A store is a singleton-scoped Spring bean — keep it thread-safe and stateless beyond config.

### 2. Content Reader (standalone backing store only)
`{platform-project-root}/src/main/java/{package}/content/{Store}ContentReader.java`

```java
package {package}.content;

import org.alfresco.repo.content.AbstractContentReader;
import org.alfresco.service.cmr.repository.ContentReader;

import java.nio.channels.ReadableByteChannel;

public class {Store}ContentReader extends AbstractContentReader {

    private final String rootLocation;

    protected {Store}ContentReader(String contentUrl, String rootLocation) {
        super(contentUrl);
        this.rootLocation = rootLocation;
    }

    @Override
    public boolean exists() {
        // Return true if the backing object for getContentUrl() exists
        return false;
    }

    @Override
    public long getLastModified() {
        return 0L;
    }

    @Override
    public long getSize() {
        return 0L;
    }

    @Override
    protected ContentReader createReader() {
        return new {Store}ContentReader(getContentUrl(), rootLocation);
    }

    @Override
    protected ReadableByteChannel getDirectReadableChannel() {
        // Open and return a channel over the backing object
        throw new UnsupportedOperationException("Implement backing read channel");
    }
}
```

### 3. Content Writer (standalone backing store only)
`{platform-project-root}/src/main/java/{package}/content/{Store}ContentWriter.java`

```java
package {package}.content;

import org.alfresco.repo.content.AbstractContentWriter;
import org.alfresco.service.cmr.repository.ContentReader;

import java.nio.channels.WritableByteChannel;

public class {Store}ContentWriter extends AbstractContentWriter {

    private final String rootLocation;

    protected {Store}ContentWriter(String contentUrl, String rootLocation, ContentReader existingContentReader) {
        super(contentUrl, existingContentReader);
        this.rootLocation = rootLocation;
    }

    @Override
    public long getSize() {
        return 0L;
    }

    @Override
    protected ContentReader createReader() {
        return new {Store}ContentReader(getContentUrl(), rootLocation);
    }

    @Override
    protected WritableByteChannel getDirectWritableChannel() {
        // Open and return a channel that writes to the backing object
        throw new UnsupportedOperationException("Implement backing write channel");
    }
}
```

### 4. Spring Wiring
`{platform-project-root}/src/main/resources/alfresco/extension/{prefix}-content-store-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- The custom store. Its root location is property-configurable. -->
    <bean id="{prefix}.{store}ContentStore"
          class="{package}.content.{Store}ContentStore">
        <property name="rootLocation" value="${dir.contentstore.{prefix}:${dir.contentstore}}"/>
    </bean>

    <!--
        Make the custom store the active store. ACS resolves binaries through the bean named
        'fileContentStore'. Overriding that bean id points the repository at the custom store.
        For a WRAPPER (caching/encrypting), inject the real fileContentStore as the delegate
        instead of replacing it outright.
    -->
    <bean id="fileContentStore"
          class="{package}.content.{Store}ContentStore">
        <property name="rootLocation" value="${dir.contentstore.{prefix}:${dir.contentstore}}"/>
    </bean>

</beans>
```

> Use an **`alfresco/extension/`** context file (auto-discovered) so the store override loads
> after the core content services are defined. Do not place it under `alfresco/module/.../context/`
> if it overrides `fileContentStore` — the extension classpath is the correct override location.

Key rules for wiring:
- The active content store is the bean named `fileContentStore`. Overriding that id swaps in the
  custom store; for a caching/encrypting wrapper, set the wrapped store as a delegate property
  rather than discarding the default.
- Make the root location property-configurable with a sensible default
  (`${dir.contentstore.{prefix}:${dir.contentstore}}`).
- Never hardcode absolute paths or credentials — read them from properties / environment.

### 5. Unit Test
`{platform-project-root}/src/test/java/{package}/content/{Store}ContentStoreTest.java`

```java
package {package}.content;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class {Store}ContentStoreTest {

    private {Store}ContentStore store;

    @BeforeEach
    void setUp() {
        store = new {Store}ContentStore();
        store.setRootLocation("test-root");
    }

    @Test
    void isWriteSupported_returnsTrue() {
        assertTrue(store.isWriteSupported());
    }

    @Test
    void getRootLocation_returnsConfiguredValue() {
        assertEquals("test-root", store.getRootLocation());
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Store class location: `src/main/java/{package}/content/`
- Bean ID: `{prefix}.{store}ContentStore`; the active store is the bean named `fileContentStore`
- Root location property: `dir.contentstore.{prefix}` with a default of `${dir.contentstore}`
- Reader/writer extend `AbstractContentReader` / `AbstractContentWriter`
- Never read/write the filesystem directly — always go through `ContentReader`/`ContentWriter`
- Never hardcode credentials or absolute paths — use properties/environment
- Never generate content stores inside the Event Handler project

## Caching & Encrypting Wrappers
ACS ships `org.alfresco.repo.content.caching.CachingContentStore` (wraps a slow/remote backing
store with a local cache) and an encrypting content store. For a wrapper, set the backing store
as a delegate property on the wrapper bean and make the **wrapper** the `fileContentStore` —
the backing store remains a separate bean it delegates to.
