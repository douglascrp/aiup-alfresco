---
description: "Generate Share Aikau page and dashlet artefacts for legacy Share UI customizations."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /aikau — Share Aikau Generator

> **Share JAR only** — deploys into the Share web tier, not into the ACS repository tier.

Generate Aikau-era Share page and dashlet artefacts from requirements.

## Input

Read `REQUIREMENTS.md` and identify Share-tier UI requirements that call for Aikau pages, widget models, dashlets, or Aikau-backed Surf pages.

Resolve:

- the **Share JAR** project's `Root path` from Section 2 (Project Architecture)
- the **Platform JAR** project's `Root path`, if one exists, so widgets can reference existing repository-side APIs or model terms

If Section 2 contains no `Share JAR` project, stop and explain that `/aikau` only applies to Share-tier addon projects.

If the request is really for modern ACA/ADF/custom frontend work instead of Aikau-based Share customization, stop and explain that `/aikau` is the wrong generator.

## Output Files

### 1. Aikau page web script descriptor

`{share-project-root}/src/main/resources/alfresco/site-webscripts/{path}/{page-id}.get.desc.xml`

```xml
<webscript>
    <shortname>{Page Title}</shortname>
    <description>{Page purpose}</description>
    <url>/page/{page-id}</url>
    <family>Share</family>
    <authentication>user</authentication>
    <transaction>none</transaction>
</webscript>
```

### 2. Aikau page model JavaScript

`{share-project-root}/src/main/resources/alfresco/site-webscripts/{path}/{page-id}.get.js`

Use an AMD-style page model script that constructs widgets explicitly:

```javascript
model.jsonModel = {
    services: [
        "alfresco/services/NavigationService",
        "alfresco/services/DocumentService"
    ],
    widgets: [
        {
            id: "{prefix}-{page-id}",
            name: "alfresco/layout/VerticalWidgets",
            config: {
                widgets: [
                    {
                        id: "{prefix}-{widget-id}",
                        name: "{widgetModule}",
                        config: {
                            title: msg.get("{message.key}")
                        }
                    }
                ]
            }
        }
    ]
};
```

### 3. Optional page template

`{share-project-root}/src/main/resources/alfresco/site-webscripts/{path}/{page-id}.get.html.ftl`

Generate only when the chosen pattern requires an explicit HTML shell for the page.

### 4. Optional widget module JavaScript

`{share-project-root}/src/main/resources/META-INF/resources/{widget-path}/{WidgetName}.js`

Generate when the request calls for a custom client-side widget rather than only composing existing Aikau widgets.

### 5. Optional message bundle

`{share-project-root}/src/main/resources/alfresco/web-extension/messages/{page-id}.properties`

Generate when widget titles, descriptions, button labels, or empty-state messages use message keys.

## Rules

### Rule 1 — Keep Aikau in the Share tier

- Aikau page scripts, widget modules, and related resources belong in the Share project
- Never write Aikau assets under `alfresco/module/...`
- Never generate repository behaviours, actions, or repo Web Scripts as part of `/aikau`

### Rule 2 — Prefer composition before custom widgets

- Use built-in Aikau widgets when the requirement can be satisfied through composition
- Generate custom widget modules only when the requirement clearly needs bespoke client-side behavior or rendering
- Do not create unnecessary custom JavaScript modules when layout and service wiring are enough

### Rule 3 — Keep page IDs, widget IDs, and message keys stable

- Page IDs, widget IDs, JS module names, and message keys must follow a consistent project-prefixed naming scheme
- Do not generate throwaway IDs that differ across descriptor, page model, and widget config

### Rule 4 — Use repository APIs rather than embedding business logic in the browser

- If the Aikau page needs data, prefer existing repository endpoints or explicit API dependencies
- Do not encode repository business rules in widget JavaScript when they belong in the Platform JAR
- If the required API does not exist yet, call it out as a dependency rather than inventing a UI-only workaround

### Rule 5 — Distinguish dashlets from full pages

- For a dashboard widget or dashlet, generate a focused widget model and only the minimum page wiring required
- For a full page, generate a page-level descriptor and model with explicit layout structure
- Do not force every Aikau request into a full custom page when a dashlet-style widget is the real requirement

### Rule 6 — Merge existing resources carefully

- If a page descriptor, page model, or message bundle already exists, merge targeted additions rather than overwriting unrelated customizations
- Do not create duplicate page IDs, duplicate widget IDs in the same model, or conflicting JS module paths

## Conventions

- `{share-project-root}` is `.` for Share-only mode, or `{name}-share/` for mixed layouts
- Aikau page descriptors and model scripts live under `src/main/resources/alfresco/site-webscripts/`
- Custom widget JavaScript modules live under `src/main/resources/META-INF/resources/`
- Use message bundles for user-facing labels instead of hardcoding repeated strings in page models
- Keep Aikau support explicitly positioned as legacy Share parity, not as the preferred modern UI path

## Validation

After generating files, verify at least the following:

- page descriptor XML is well-formed
- page IDs and widget IDs are consistent across descriptor and JS model
- any custom widget module path referenced by the page model exists
- any message keys referenced by the JS model exist in the generated bundle
- no Aikau artefacts were written under `alfresco/module/...`
