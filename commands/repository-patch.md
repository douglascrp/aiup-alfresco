---
description: "Generate an AbstractPatch repository patch that migrates existing data or structure between module versions, runs exactly once per repository, and is recorded in alf_applied_patch. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /repository-patch — Repository Patch Generator

> **In-Process SDK only** — repository patches deploy inside the ACS JVM as part of the Platform JAR.
> They differ from bootstrap loaders (`/bootstrap-loader`): a patch migrates **existing** data between
> module versions; a bootstrap loader creates **initial** data on first install.

Generate an Alfresco repository patch that migrates data or structure exactly once per repository,
recorded permanently in `alf_applied_patch`.

## Input

Read `REQUIREMENTS.md` to identify patch requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/repository-patch`
     only applies to the in-process Platform JAR project.

2. Read Section 7 (Behaviour Requirements) sub-section "Repository patch requirements".
   - If no patch requirements are present in Section 7, stop and ask the user to run
     `/requirements` first (or provide a description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from patch requirements:
   - `{PatchName}` — PascalCase patch name (e.g. `AddWebableAspect`, `RenameArchiveFolder`)
   - `{patch-id}` — globally unique dot-notation patch ID: `patch.{module-id}.{camelCaseName}`
     (e.g. `patch.my-extension.addWebableAspect`)
   - `{fixesFromSchema}` — the ACS DB schema version from which this patch applies (inclusive)
   - `{fixesToSchema}` — the ACS DB schema version up to which this patch applies (inclusive)
   - `{targetSchema}` — the ACS DB schema version after which this patch is recorded as applied;
     for ACS 26.1 use `5026`
   - Which Alfresco services the patch needs beyond the default set (nodeService, searchService,
     transactionService, namespaceService are injected by `basePatch` automatically)

---

## Output Files

> **All three artefacts below are required and must be generated together in a single run:**
> the patch class, the patch context XML, and the unit test.

### 1. Patch Class
`{platform-project-root}/src/main/java/{package}/patch/{PatchName}Patch.java`

```java
package {package}.patch;

import org.alfresco.repo.admin.patch.AbstractPatch;
import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
import org.alfresco.service.cmr.repository.StoreRef;
import org.alfresco.service.cmr.search.ResultSet;
import org.alfresco.service.cmr.search.SearchParameters;
import org.alfresco.service.cmr.search.SearchService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Repository patch: {PatchName}
 *
 * Migrates existing data — runs exactly once per repository, recorded in alf_applied_patch.
 * Applies to ACS schema versions {fixesFromSchema}–{fixesToSchema}.
 */
public class {PatchName}Patch extends AbstractPatch {

    private static final Logger LOG = LoggerFactory.getLogger({PatchName}Patch.class);

    private static final String MSG_SUCCESS = "{PatchName}Patch applied successfully: {0} nodes processed";

    @Override
    protected String applyInternal() throws Exception {
        LOG.info("{PatchName}Patch: starting");

        // nodeService, searchService, transactionService, namespaceService
        // are available as protected fields inherited from AbstractPatch.

        int count = 0;

        // Patch logic — query and migrate existing data
        // Example: find all nodes missing an aspect and apply it
        SearchParameters sp = new SearchParameters();
        sp.addStore(StoreRef.STORE_REF_WORKSPACE_SPACESSTORE);
        sp.setLanguage(SearchService.LANGUAGE_FTS_ALFRESCO);
        sp.setQuery("TYPE:\"cm:content\" AND NOT ASPECT:\"{prefix}:webable\"");
        sp.setMaxItems(Integer.MAX_VALUE);

        ResultSet results = null;
        try {
            results = searchService.query(sp);
            for (NodeRef nodeRef : results.getNodeRefs()) {
                if (nodeService.exists(nodeRef)) {
                    // perform migration on each node
                    count++;
                }
            }
        } finally {
            if (results != null) {
                results.close();
            }
        }

        String report = MSG_SUCCESS.replace("{0}", String.valueOf(count));
        LOG.info("{PatchName}Patch: completed — {}", report);
        return report;
    }
}
```

Key rules for the patch class:
- Always extend `AbstractPatch` — never implement `Patch` directly.
- Override `protected String applyInternal() throws Exception` — this is the only method to
  implement. Return a human-readable summary string that describes what was done.
- `nodeService`, `searchService`, `transactionService`, and `namespaceService` are already injected
  via `basePatch`; do **not** declare them as fields — use the `protected` inherited fields directly.
- Always close `ResultSet` in a `finally` block to prevent memory leaks.
- Always check `nodeService.exists(nodeRef)` before acting on a node — concurrent deletes can
  invalidate nodes between query and access.
- Use `SearchService.LANGUAGE_FTS_ALFRESCO` — never `LANGUAGE_LUCENE` (deprecated, incompatible
  with Search Enterprise).
- Do **not** add `@Transactional` — `AbstractPatch` manages the transaction boundary.
- Do **not** use `retryingTransactionHelper` inside `applyInternal()` — already transactional.
- Authenticate as system if node operations require elevated access:
  `AuthenticationUtil.runAsSystem(() -> { ... return null; })` — but only when necessary.
- The patch runs exactly once: the framework records it in `alf_applied_patch` keyed by `id`.
  To re-run in development, increment the `id` or delete the row from the table.

### 2. Patch Context XML
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/patch-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!--
        {PatchName}Patch — migrates existing data between module versions.
        Runs exactly once per repository; recorded in alf_applied_patch.

        fixesFromSchema / fixesToSchema: ACS DB schema range this patch targets.
        targetSchema: schema version at which the patch is recorded as applied.
        For ACS 26.1 use targetSchema=5026.
    -->
    <bean id="{patch-id}"
          class="{package}.patch.{PatchName}Patch"
          parent="basePatch">
        <property name="id"              value="{patch-id}"/>
        <property name="description"     value="{patch description — what this patch does}"/>
        <property name="fixesFromSchema" value="{fixesFromSchema}"/>
        <property name="fixesToSchema"   value="{fixesToSchema}"/>
        <property name="targetSchema"    value="{targetSchema}"/>
    </bean>

</beans>
```

**Immediately after writing patch-context.xml**, add this import to `module-context.xml`
(create module-context.xml if it does not exist):
```xml
<import resource="classpath:alfresco/module/{module-id}/context/patch-context.xml"/>
```
This step is mandatory — without it, ACS never loads the patch bean and the patch never runs.

**Schema version guidance:**

| Situation | Values to use |
|-----------|--------------|
| Patch must apply on every ACS 26.1 install for the first time | `fixesFromSchema=0`, `fixesToSchema=5026`, `targetSchema=5027` |
| Patch targets only repositories upgrading from a previous version | Set `fixesFromSchema` to the schema of the previous version and `fixesToSchema`/`targetSchema` accordingly |
| Patch depends on another patch running first | Add `<property name="dependsOn"><list><ref bean="{other-patch-id}"/></list></property>` |

### 3. Unit Test
`{platform-project-root}/src/test/java/{package}/patch/{PatchName}PatchTest.java`

```java
package {package}.patch;

import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
import org.alfresco.service.cmr.repository.StoreRef;
import org.alfresco.service.cmr.search.ResultSet;
import org.alfresco.service.cmr.search.SearchParameters;
import org.alfresco.service.cmr.search.SearchService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class {PatchName}PatchTest {

    @Mock NodeService nodeService;
    @Mock SearchService searchService;
    @Mock ResultSet resultSet;

    private {PatchName}Patch patch;

    @BeforeEach
    void setUp() {
        patch = new {PatchName}Patch();
        patch.setNodeService(nodeService);
        patch.setSearchService(searchService);
    }

    @Test
    void applyInternal_returnsSuccessMessage_whenNoNodesFound() throws Exception {
        when(searchService.query(any(SearchParameters.class))).thenReturn(resultSet);
        when(resultSet.getNodeRefs()).thenReturn(Collections.emptyList());

        String result = patch.applyInternal();

        assertNotNull(result);
        verify(resultSet).close();
    }

    @Test
    void applyInternal_processesNodes_whenNodesExist() throws Exception {
        NodeRef nodeRef = new NodeRef(StoreRef.STORE_REF_WORKSPACE_SPACESSTORE, "test-id");
        when(searchService.query(any(SearchParameters.class))).thenReturn(resultSet);
        when(resultSet.getNodeRefs()).thenReturn(Collections.singletonList(nodeRef));
        when(nodeService.exists(nodeRef)).thenReturn(true);

        String result = patch.applyInternal();

        assertNotNull(result);
        verify(nodeService).exists(nodeRef);
        verify(resultSet).close();
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Class naming: `{PatchName}Patch.java` in package `{package}.patch`
- Patch ID format: `patch.{module-id}.{camelCaseName}` — must be globally unique across all modules
- Context file: `patch-context.xml` (separate from `bootstrap-context.xml` and `service-context.xml`)
- `targetSchema` for ACS 26.1: `5026` (verified from ACS `alfresco-repository` schema descriptor)
- `fixesFromSchema=0` and `fixesToSchema={targetSchema}` applies the patch to every repository
  regardless of its previous state — use this for patches that are safe to run on any install
- Never generate patch classes inside the Event Handler project
