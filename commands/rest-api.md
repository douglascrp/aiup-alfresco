---
description: "Generate a modern ACS v1 Public REST API resource (annotation-based @EntityResource / @RelationshipResource with @WebApiDescription) plus model POJO, Spring registration, and unit test. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /rest-api — v1 Public REST API Generator

> **In-Process SDK only** — v1 Public REST API resources deploy inside the ACS JVM as part of
> the Platform JAR. This is the **modern, annotation-based** framework
> (`org.alfresco.rest.framework`), distinct from classic declarative Web Scripts (`/web-scripts`).
> Use `/rest-api` for structured, paged, content-typed REST resources; use `/web-scripts` for
> server-side rendering, bulk/streaming responses, or non-REST endpoints.

Generate a v1 Public REST API entity (and optional relationship) resource from requirements.

## Input

Read `REQUIREMENTS.md` to identify REST API requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/rest-api`
     only applies to the in-process Platform JAR project.

2. Read Section 6 (API Requirements).
   - If no API requirements are present in Section 6, stop and ask the user to run
     `/requirements` first (or provide a description as `$ARGUMENTS`).
   - If the requirement describes server-side HTML rendering, a one-off bulk export, or a
     binary/streaming download, recommend `/web-scripts` instead — those are classic Web Script
     use cases, not v1 resources.

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from API requirements:
   - `{Entity}` — PascalCase entity model name (e.g. `VendorContract`)
   - `{entities}` — plural, kebab-case collection name (e.g. `vendor-contracts`)
   - `{relationship}` — plural, kebab-case relationship name when a sub-collection is needed
     (e.g. `payments`); omit the relationship resource if no nested collection is required
   - Which CRUD operations are in scope (Read / ReadById / Create / Update / Delete)
   - Which Alfresco services the resource needs (e.g. `ServiceRegistry`, `NodeService`,
     `SearchService`)

---

## Output Files

> **The model POJO, the entity resource, the Spring registration, and the unit test are
> required and must be generated together.** The relationship resource is optional — generate
> it only when the requirements describe a nested sub-collection.

### 1. Model POJO
`{platform-project-root}/src/main/java/{package}/rest/model/{Entity}.java`

```java
package {package}.rest.model;

import org.alfresco.rest.framework.resource.UniqueId;

public class {Entity} {

    private String id;
    private String name;

    public {Entity}() {
    }

    public {Entity}(String id, String name) {
        this.id = id;
        this.name = name;
    }

    @UniqueId
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

Key rules for the model POJO:
- Annotate the identifier getter with `@UniqueId` — the framework uses it to build the
  `readById` URL segment and to serialise the entity's `id` field. Exactly one getter must
  carry `@UniqueId`.
- The POJO is a plain JavaBean (public no-arg constructor + getters/setters). Jackson
  serialises it to JSON; do not add Alfresco service fields to it.
- Use `String`/`Date`/primitive-wrapper/`List` field types — keep it serialisable.

### 2. Entity Resource
`{platform-project-root}/src/main/java/{package}/rest/{Entity}EntityResource.java`

```java
package {package}.rest;

import org.alfresco.rest.framework.WebApiDescription;
import org.alfresco.rest.framework.WebApiParam;
import org.alfresco.rest.framework.resource.EntityResource;
import org.alfresco.rest.framework.resource.actions.interfaces.EntityResourceAction;
import org.alfresco.rest.framework.resource.parameters.CollectionWithPagingInfo;
import org.alfresco.rest.framework.resource.parameters.Paging;
import org.alfresco.rest.framework.resource.parameters.Parameters;
import org.alfresco.service.ServiceRegistry;
import {package}.rest.model.{Entity};
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@EntityResource(name = "{entities}", title = "{Entity} API")
public class {Entity}EntityResource implements
        EntityResourceAction.Read<{Entity}>,
        EntityResourceAction.ReadById<{Entity}> {

    private static final Logger LOG = LoggerFactory.getLogger({Entity}EntityResource.class);

    private ServiceRegistry serviceRegistry;

    @Override
    @WebApiDescription(title = "List {entities}", description = "Returns a paged list of {entities}")
    public CollectionWithPagingInfo<{Entity}> readAll(Parameters parameters) {
        Paging paging = parameters.getPaging();
        // Build the result list from the repository (use serviceRegistry.getSearchService(), etc.)
        List<{Entity}> results = List.of();
        return CollectionWithPagingInfo.asPaged(paging, results, false, results.size());
    }

    @Override
    @WebApiDescription(title = "Get a {Entity}", description = "Returns a single {Entity} by id")
    public {Entity} readById(
            @WebApiParam(name = "{entityId}", title = "The {Entity} id") String id,
            Parameters parameters) {
        // Look up and return the entity; throw EntityNotFoundException if absent
        return new {Entity}(id, null);
    }

    public void setServiceRegistry(ServiceRegistry serviceRegistry) {
        this.serviceRegistry = serviceRegistry;
    }
}
```

Key rules for the entity resource:
- Annotate the class with `@EntityResource(name = "{entities}", title = "...")`. The `name`
  becomes the collection path segment and **must be plural, kebab-case** (`vendor-contracts`),
  matching the Web Script API Paths convention.
- Implement only the action interfaces the requirements call for, from
  `EntityResourceAction`: `Read<T>` (`readAll`), `ReadById<T>` (`readById`), `Create<T>`
  (`create(List<T>, Parameters)`), `Update<T>` (`update(String, T, Parameters)`),
  `Delete` (`delete(String, Parameters)`). Do **not** implement interfaces you will not use.
- **Every** public action method must carry `@WebApiDescription` — without it the framework
  does not map the method and the operation silently returns `405 Method Not Allowed`.
- Return collections as `CollectionWithPagingInfo<T>` built with
  `CollectionWithPagingInfo.asPaged(paging, list, hasMore, totalItems)` — never a raw `List`
  (honours the paging envelope; see AGENTS.md "Paging (REST)").
- Read paging with `parameters.getPaging()` and query params with
  `parameters.getParameter("name")`; annotate path/query parameters with `@WebApiParam`.
- Throw `org.alfresco.rest.framework.core.exceptions.EntityNotFoundException` for a missing id
  and `InvalidArgumentException` for bad input — the framework maps these to 404/400.
- Use **setter injection only** — no `@Autowired`. Do **not** extend `DeclarativeWebScript`
  (that is the classic framework).

### 3. Relationship Resource (optional)
`{platform-project-root}/src/main/java/{package}/rest/{Entity}{Relationship}RelationshipResource.java`

```java
package {package}.rest;

import org.alfresco.rest.framework.WebApiDescription;
import org.alfresco.rest.framework.resource.RelationshipResource;
import org.alfresco.rest.framework.resource.actions.interfaces.RelationshipResourceAction;
import org.alfresco.rest.framework.resource.parameters.CollectionWithPagingInfo;
import org.alfresco.rest.framework.resource.parameters.Paging;
import org.alfresco.rest.framework.resource.parameters.Parameters;
import {package}.rest.model.{Entity};

import java.util.List;

@RelationshipResource(name = "{relationship}", entityResource = {Entity}EntityResource.class, title = "{Entity} {relationship}")
public class {Entity}{Relationship}RelationshipResource implements
        RelationshipResourceAction.Read<{Entity}> {

    @Override
    @WebApiDescription(title = "List {relationship} for a {Entity}")
    public CollectionWithPagingInfo<{Entity}> readAll(String entityResourceId, Parameters parameters) {
        Paging paging = parameters.getPaging();
        List<{Entity}> results = List.of();
        return CollectionWithPagingInfo.asPaged(paging, results, false, results.size());
    }
}
```

Key rules for the relationship resource:
- Annotate with `@RelationshipResource(name = "{relationship}", entityResource = {Entity}EntityResource.class, title = "...")`.
  The `entityResource` **must** point at the entity resource class above — this nests the
  collection under `.../{entities}/{entityId}/{relationship}`.
- The `readAll` signature is `(String entityResourceId, Parameters)` — the first argument is the
  parent entity id; the relationship `name` is plural, kebab-case.

### 4. Spring Bean Registration
Add to `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/webscript-context.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- v1 Public REST API resources are discovered by the framework's
         ResourceLookupDictionary by scanning the context for @EntityResource /
         @RelationshipResource annotated beans. A plain bean definition is enough. -->
    <bean id="{prefix}.{entity}EntityResource"
          class="{package}.rest.{Entity}EntityResource">
        <property name="serviceRegistry" ref="ServiceRegistry"/>
    </bean>

    <!-- Relationship resource (omit if not generated) -->
    <bean id="{prefix}.{entity}{Relationship}RelationshipResource"
          class="{package}.rest.{Entity}{Relationship}RelationshipResource"/>

</beans>
```

If `webscript-context.xml` already exists (created by `/web-scripts`): append the bean
definitions to it. Do **not** create a second `webscript-context.xml`.

If `webscript-context.xml` does not yet exist: create it and add the import to
`module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/webscript-context.xml"/>
```

### 5. Unit Test
`{platform-project-root}/src/test/java/{package}/rest/{Entity}EntityResourceTest.java`

```java
package {package}.rest;

import org.alfresco.rest.framework.resource.parameters.CollectionWithPagingInfo;
import org.alfresco.rest.framework.resource.parameters.Paging;
import org.alfresco.rest.framework.resource.parameters.Parameters;
import org.alfresco.service.ServiceRegistry;
import {package}.rest.model.{Entity};
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class {Entity}EntityResourceTest {

    @Mock ServiceRegistry serviceRegistry;
    @Mock Parameters parameters;

    private {Entity}EntityResource resource;

    @BeforeEach
    void setUp() {
        resource = new {Entity}EntityResource();
        resource.setServiceRegistry(serviceRegistry);
    }

    @Test
    void readAll_returnsPagedCollection() {
        when(parameters.getPaging()).thenReturn(Paging.DEFAULT);

        CollectionWithPagingInfo<{Entity}> result = resource.readAll(parameters);

        assertNotNull(result);
    }

    @Test
    void readById_returnsEntityWithId() {
        {Entity} entity = resource.readById("node-123", parameters);

        assertNotNull(entity);
        assertEquals("node-123", entity.getId());
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Class location: `src/main/java/{package}/rest/` (resources) and `.../rest/model/` (POJOs)
- Entity collection `name`: plural, kebab-case (`vendor-contracts`); no verbs in the name
- Bean ID format: `{prefix}.{entity}EntityResource`, `{prefix}.{entity}{Relationship}RelationshipResource`
- URL path (ACS 26.1): custom resources join the core public API scope and are served at
  `/alfresco/api/-default-/public/alfresco/versions/1/{entities}` — and
  `.../{entities}/{id}/{relationship}` for relationships
- Resource beans need **no parent bean** — `ResourceLookupDictionary` discovers them by
  scanning the application context for the `@EntityResource` / `@RelationshipResource` annotations
- Never extend `DeclarativeWebScript`, never use `@Autowired`, and never omit `@WebApiDescription`
- Never generate REST API resources inside the Event Handler project
- After generating files, invoke the `rest-api-validator` skill

## Classic Web Script vs v1 REST API
| Use `/rest-api` (this command) | Use `/web-scripts` |
|--------------------------------|--------------------|
| Structured CRUD over an entity, JSON in/out | Server-side HTML/FreeMarker rendering |
| Paged collections, content negotiation handled by the framework | Custom binary/streaming downloads, multipart uploads |
| Stable public-style API under `/alfresco/api/.../public/...` | Ad-hoc endpoints under `/alfresco/s/api/{prefix}/...` |
