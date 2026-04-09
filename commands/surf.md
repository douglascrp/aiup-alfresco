---
description: "Generate Share Surf extension artefacts for legacy Share pages, components, templates, and extension metadata."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /surf — Share Surf Extension Generator

> **Share JAR only** — deploys into the Share web tier, not into the ACS repository tier.

Generate classic Share Surf artefacts from requirements.

## Input

Read `REQUIREMENTS.md` and identify Share-tier UI requirements that need Surf pages, Surf components, extension modules, or Share web-tier web scripts.

Resolve:

- the **Share JAR** project's `Root path` from Section 2 (Project Architecture)
- the **Platform JAR** project's `Root path`, if one exists, so page/component logic can align with repository-side APIs or model names

If Section 2 contains no `Share JAR` project, stop and explain that `/surf` only applies to Share-tier addon projects.

If the request is really for modern ACA/ADF/custom frontend work instead of Surf-based Share customization, stop and explain that `/surf` is the wrong generator.

## Output Files

### 1. Surf extension metadata

`{share-project-root}/src/main/resources/alfresco/web-extension/site-data/extensions/{extension-name}.xml`

Use this file to register extension modules, evaluators, component overrides, or page wiring:

```xml
<extension>
    <modules>
        <module>
            <id>{prefix}-{page-id}-module</id>
            <version>1.0</version>
            <auto-deploy>true</auto-deploy>
            <components>
                <component>
                    <region-id>{regionId}</region-id>
                    <source-id>{pageId}</source-id>
                    <scope>page</scope>
                    <url>/components/{extension-name}/{component-name}</url>
                </component>
            </components>
        </module>
    </modules>
</extension>
```

### 2. Page web script descriptor

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

### 3. Page or component controller/config

Generate as required by the requested Surf pattern:

- page config XML:
  `{share-project-root}/src/main/resources/alfresco/site-webscripts/{path}/{page-id}.get.config.xml`
- page or component FreeMarker:
  `{share-project-root}/src/main/resources/alfresco/site-webscripts/{path}/{page-id}.get.html.ftl`
- component web script descriptor/controller/template under:
  `{share-project-root}/src/main/resources/alfresco/site-webscripts/components/{extension-name}/{component-name}.*`

### 4. Optional Share message bundle

`{share-project-root}/src/main/resources/alfresco/web-extension/messages/{extension-name}.properties`

Generate when the page/component references labels or titles by message key.

### 5. Optional Java evaluator/helper

Generate only when the requested Surf customization requires custom Java-side visibility logic.

`{share-project-root}/src/main/java/{java-package}/share/{Name}Evaluator.java`

## Rules

### Rule 1 — Keep Surf artefacts in the Share tier

- All Surf pages, components, and extension metadata must live in the Share project
- Never emit Surf artefacts under `alfresco/module/...`
- Never emit repository Spring contexts, repo Web Scripts, behaviours, or actions as part of `/surf`

### Rule 2 — Generate coherent page/component IDs

- Page IDs, component IDs, extension module IDs, and URLs must align
- Prefer stable, lowercase, project-prefixed identifiers
- Do not generate one-off IDs that differ across the extension metadata, web script descriptors, and file names

### Rule 3 — Prefer extension modules over blind overrides

- Use extension modules for page/component insertion where possible
- Only override existing Share components/pages directly when the requirement explicitly calls for replacement behavior
- Make the override intent explicit in comments or descriptor names

### Rule 4 — Separate page shell from component logic

- Use a page web script to declare the page entry point
- Use separate component web scripts for reusable page regions when the layout has more than one functional block
- Do not collapse an entire non-trivial page into one giant FreeMarker file when the requirement implies reusable components

### Rule 5 — Reuse repository APIs rather than duplicating business logic

- If the page needs repository data, prefer consuming existing repository endpoints or metadata conventions already generated elsewhere
- Do not reimplement repository business rules in Surf templates
- If a repository-side endpoint is missing, call that out as a dependency rather than inventing server-side Share logic that belongs in the Platform JAR

### Rule 6 — Merge extension metadata carefully

- If `site-data/extensions/{extension-name}.xml` already exists, merge relevant modules/components instead of discarding unrelated configuration
- Do not create duplicate module IDs, component entries, or page registrations for the same feature

## Conventions

- `{share-project-root}` is `.` for Share-only mode, or `{name}-share/` for mixed layouts
- Share extension metadata root: `src/main/resources/alfresco/web-extension/site-data/extensions/`
- Share web-tier web scripts root: `src/main/resources/alfresco/site-webscripts/`
- Use message bundles for user-facing labels instead of hardcoding every title inline when the page has more than trivial text
- Keep Java evaluators/helpers under `{java-package}.share`

## Validation

After generating files, verify at least the following:

- extension metadata XML is well-formed
- page/component IDs are consistent across metadata and web script files
- no Surf artefacts were written under `alfresco/module/...`
- any message keys referenced by descriptors/templates exist in the generated bundle
- generated page/component URLs are stable and deterministic
