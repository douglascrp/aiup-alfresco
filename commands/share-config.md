---
description: "Generate Share form configuration and related web-extension files for legacy Share UI customizations."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /share-config — Share Form Configuration Generator

> **Share JAR only** — deploys into the Share web tier, not into the ACS repository tier.

Generate `share-config-custom.xml` and related Share form resources from requirements.

## Input

Read `REQUIREMENTS.md` and identify Share-tier UI requirements suitable for Share form configuration.

Resolve:

- the **Share JAR** project's `Root path` from Section 2 (Project Architecture)
- the **Platform JAR** project's `Root path`, if one exists, so custom type/aspect names can be reused from the repository model

If Section 2 contains no `Share JAR` project, stop and explain that `/share-config` only applies to Share-tier addon projects.

If the requirement is clearly for ACA/ADF/custom frontend work instead of Share, stop and explain that `/share-config` is the wrong generator.

## Output Files

### 1. Main Share configuration

`{share-project-root}/src/main/resources/alfresco/web-extension/share-config-custom.xml`

Generate or update a single `share-config-custom.xml` root file:

```xml
<alfresco-config>

    <config evaluator="node-type" condition="{prefix}:{type}">
        <forms>
            <form>
                <field-visibility>
                    <show id="{prefix}:{propOne}"/>
                    <show id="{prefix}:{propTwo}"/>
                </field-visibility>
                <appearance>
                    <set id="general" appearance="bordered-panel" label-id="{prefix}.set.general"/>
                    <field id="{prefix}:{propOne}" set="general" label-id="{prefix}.{propOne}"/>
                    <field id="{prefix}:{propTwo}" set="general" label-id="{prefix}.{propTwo}"/>
                </appearance>
            </form>

            <form id="doclib-simple-metadata">
                <field-visibility>
                    <show id="{prefix}:{propOne}"/>
                </field-visibility>
                <appearance>
                    <field id="{prefix}:{propOne}" label-id="{prefix}.{propOne}"/>
                </appearance>
            </form>
        </forms>
    </config>

    <config evaluator="aspect" condition="{prefix}:{aspect}">
        <forms>
            <form>
                <field-visibility>
                    <show id="{prefix}:{aspectProp}"/>
                </field-visibility>
                <appearance>
                    <set id="aspect" appearance="bordered-panel" label-id="{prefix}.set.aspect"/>
                    <field id="{prefix}:{aspectProp}" set="aspect" label-id="{prefix}.{aspectProp}"/>
                </appearance>
            </form>
        </forms>
    </config>

</alfresco-config>
```

### 2. Share message bundle

`{share-project-root}/src/main/resources/alfresco/web-extension/messages/{module-id}-share.properties`

Generate labels referenced from `label-id` keys in `share-config-custom.xml`:

```properties
{prefix}.set.general=General
{prefix}.set.aspect=Additional Metadata
{prefix}.{propOne}=Property One
{prefix}.{aspectProp}=Aspect Property
```

### 3. Optional Share evaluator class

Generate only when the requirements explicitly call for conditional visibility that cannot be expressed with built-in Share evaluators.

`{share-project-root}/src/main/java/{java-package}/share/{Name}Evaluator.java`

## Rules

### Rule 1 — Reuse repository model names exactly

- If a Platform JAR project exists, reuse the type/aspect/property QNames already defined by `/content-model`
- Never invent parallel Share-only model names
- If the Share requirement refers to custom metadata but no matching repository model exists, call that out instead of fabricating a QName

### Rule 2 — Make form intent explicit

- Always generate a full `<form>` block for the type/aspect
- Generate `doclib-simple-metadata` blocks when the metadata should appear in document-library editing
- If requirements differentiate create/edit/view behaviour, reflect that explicitly in visibility, appearance, or dedicated form blocks rather than silently collapsing everything into one generic layout

### Rule 3 — Group fields intentionally

- Use named `<set>` groups when more than two fields are shown
- Keep grouped fields coherent by business purpose
- Do not dump every field into a flat list unless the requirement is truly trivial

### Rule 4 — Prefer built-in Share evaluators first

- Use built-in evaluator patterns where they satisfy the requirement
- Only generate a Java evaluator when the visibility rule depends on custom logic that Share config alone cannot express clearly
- If a custom evaluator is generated, place it in the Share project, never in the Platform JAR

### Rule 5 — Do not assume Share is the only client

- Share config is a UI layer, not the source of truth for the model
- Do not encode repository business rules only in Share visibility or layout rules
- Keep Share config aligned with the repository model, but do not treat it as the replacement for REST or repository-side validation

### Rule 6 — Merge, do not overwrite blindly

- If `share-config-custom.xml` already exists, append or update the relevant `<config>` blocks instead of replacing unrelated customizations
- Do not create duplicate `<config>` blocks for the same type/aspect and same purpose

## Conventions

- `{share-project-root}` is `.` for Share-only mode, or `{name}-share/` for mixed layouts
- Primary file root: `src/main/resources/alfresco/web-extension/`
- Use `node-type` evaluator for types and `aspect` evaluator for aspects unless a stronger requirement says otherwise
- Label keys should be short, stable, and project-prefixed
- Keep Share-only artefacts out of the Platform JAR and Event Handler projects

## Validation

After generating files, verify at least the following:

- `share-config-custom.xml` is well-formed XML
- referenced QNames match the repository content model when a Platform JAR project exists
- every `label-id` key exists in the generated Share message bundle
- no Share files were written under `alfresco/module/...`
