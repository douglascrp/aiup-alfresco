---
description: "Generate Alfresco Web Script descriptors, controllers, and FreeMarker templates. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /web-scripts — Web Script Generator

> **In-Process SDK only** — deploys inside the ACS JVM as a Platform JAR.

> **For a modern, structured REST API use `/rest-api`** (annotation-based v1 Public REST API
> with paging and content negotiation). This command generates **classic declarative Web
> Scripts** — still the right tool for server-side HTML/FreeMarker rendering, custom
> binary/streaming downloads, multipart uploads, and ad-hoc endpoints under
> `/alfresco/s/api/{prefix}/...`.

Generate Web Script files from requirements.

## Input
Read `REQUIREMENTS.md` to identify API requirements suitable for Web Scripts and resolve the
Platform JAR project's `Root path` from Section 2 (Project Architecture).

- If Section 2 contains no `Platform JAR` project, stop and explain that `/web-scripts`
  only applies to the in-process repository addon project.

## Output Files (per Web Script)

### 1. Descriptor
`{platform-project-root}/src/main/resources/alfresco/extension/templates/webscripts/{path}/{name}.{method}.desc.xml`

### 2. Controller (Java or JavaScript)
- Java: `{platform-project-root}/src/main/java/{package}/{Name}WebScript.java` extending `DeclarativeWebScript`
- JavaScript: `{platform-project-root}/src/main/resources/alfresco/extension/templates/webscripts/{path}/{name}.{method}.js`

### 3. Response Template
`{platform-project-root}/src/main/resources/alfresco/extension/templates/webscripts/{path}/{name}.{method}.json.ftl`

## Conventions
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- URL pattern: `/api/{extension-prefix}/{resource}`
- Authentication: `user` (default) or `admin` where specified
- Format: `json` (default)
- Transaction: `required` for write operations, `none` for read-only
- Follow CLAUDE.md REST path conventions
- Never generate Web Scripts inside the Event Handler project

## SearchService Query Rules

All `SearchService` calls in Web Script controllers must follow these rules — they apply equally to behaviours (see `/behaviours`).

### Rule 1 — Always use AFTS; never use Lucene query language

```java
// CORRECT
SearchParameters sp = new SearchParameters();
sp.addStore(StoreRef.STORE_REF_WORKSPACE_SPACESSTORE);
sp.setLanguage(SearchService.LANGUAGE_FTS_ALFRESCO);   // ← always this constant
sp.setQuery("TYPE:\"vc:vendorContract\" AND vc:expiryDate:[NOW TO NOW+30DAY]");

// WRONG — old Lucene query language, forbidden in ACS 6.x+
sp.setLanguage(SearchService.LANGUAGE_LUCENE);
sp.setQuery("@vc\\:expiryDate:[MIN TO NOW]");          // @variable notation — forbidden
sp.setQuery("@{http://…}expiryDate:[MIN TO NOW]");     // namespace-qualified — forbidden
```

`SearchService.LANGUAGE_LUCENE` and the `@variable` property prefix are deprecated since
ACS 6.x and incompatible with Search Enterprise. Always use `LANGUAGE_FTS_ALFRESCO` and
reference properties by their AFTS prefixed name (e.g. `vc:expiryDate`, not `@vc\:expiryDate`).

### Rule 2 — Use the `=` prefix for exact-match property filters

When filtering on a specific property value (not a range), prefix the property with `=` to
force IDENTIFIER analysis mode. This is required for correctness with the DB query engine
and good practice with Solr:

```java
// CORRECT — exact match
"TYPE:\"vc:vendorContract\" AND =vc:responsibleDepartment:\"IT\""

// ALSO CORRECT — date range (no = needed for range queries)
"TYPE:\"vc:vendorContract\" AND vc:expiryDate:[2026-01-01T00:00:00 TO 2026-12-31T23:59:59]"
```

### Rule 3 — Always close ResultSet in a finally block

```java
ResultSet rs = null;
try {
    rs = searchService.query(sp);
    for (NodeRef nodeRef : rs.getNodeRefs()) { … }
} finally {
    if (rs != null) { rs.close(); }   // releases Solr cursor / DB resources
}
```

## Multipart Uploads & Streaming Responses

These two patterns are the main reason to choose a classic Web Script over `/rest-api`.

### Multipart / file upload

For `multipart/form-data` POSTs, extend `AbstractWebScript` (not `DeclarativeWebScript`) and
read the parsed form from the request. Each uploaded file arrives as a `FormField` whose
content is exposed as an InputStream.

```java
public class UploadWebScript extends AbstractWebScript {
    @Override
    public void execute(WebScriptRequest req, WebScriptResponse res) throws IOException {
        FormData form = (FormData) req.parseContent();          // org.springframework.extensions.webscripts.servlet.FormData
        for (FormData.FormField field : form.getFields()) {
            if (field.getIsFile()) {
                try (InputStream in = field.getInputStream()) {
                    // write to a ContentWriter via ContentService — never to the local filesystem
                }
            }
        }
        res.setStatus(200);
    }
}
```

- The descriptor must declare `<transaction>required</transaction>` and the controller must
  write bytes through `ContentService.getWriter(...)`, never to a local path.
- Guard total upload size and validate the declared mimetype before streaming.

### Streaming / binary responses

For large or binary payloads, bypass the FreeMarker template and write directly to the
response output stream — this avoids buffering the whole payload in memory.

```java
public class DownloadWebScript extends AbstractWebScript {
    @Override
    public void execute(WebScriptRequest req, WebScriptResponse res) throws IOException {
        res.setContentType("application/octet-stream");
        res.setHeader("Content-Disposition", "attachment; filename=\"export.bin\"");
        try (OutputStream out = res.getOutputStream()) {
            // stream from a ContentReader: contentService.getReader(nodeRef, ContentModel.PROP_CONTENT).getContentInputStream()
        }
    }
}
```

- A streaming/binary script has **no** `.json.ftl` template — `AbstractWebScript.execute()`
  owns the full response.
- Set `Content-Type` and `Content-Disposition` explicitly; set `<format default="any"/>` in
  the descriptor so callers are not forced to negotiate a format.
