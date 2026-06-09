---
name: content-model-validator
description: Validates Alfresco content model XML files for correct namespace URI format, mandatory type/aspect declarations, valid property data types, and absence of reserved prefixes (sys:, cm:, app:). Trigger automatically when generating or editing *-model*.xml or *-context.xml files.
---


# Content Model Validator

Validate the given Alfresco content model XML against these rules:

## Namespace Validation
- Namespace URI must follow the pattern `http://www.{company}.com/model/{prefix}/{version}`
- Namespace prefix must not collide with reserved Alfresco prefixes: `sys`, `cm`, `app`, `usr`, `act`, `wcm`, `wca`, `lnk`, `fm`, `dl`, `ia`, `smf`, `imap`, `emailserver`, `bpm`, `wcmwf`, `trx`, `stcp`
- Prefix must be lowercase alphanumeric, 2-6 characters

## Structure Validation
- Root element must be `<model>` with `name` attribute in format `{prefix}:modelName`
- Must contain `<namespaces>` with at least one `<namespace>` declaration
- If types are declared, they must be inside `<types>` element
- If aspects are declared, they must be inside `<aspects>` element

## Type and Aspect Validation
- Every `<type>` must have a `name` attribute in format `{prefix}:typeName`
- Every `<type>` should declare a `<parent>` (default: `cm:content` or `cm:folder`)
- Property names must use the model prefix: `{prefix}:propertyName`
- Property `<type>` must be a valid Alfresco data type: `d:text`, `d:mltext`, `d:int`, `d:long`, `d:float`, `d:double`, `d:date`, `d:datetime`, `d:boolean`, `d:noderef`, `d:content`, `d:any`, `d:category`, `d:qname`, `d:locale`, `d:period`

## Mandatory Property Enforcement
- **FLAG as ERROR** any property that uses `<mandatory enforced="true">true</mandatory>`.
  - **Why it breaks**: `enforced="true"` makes ACS fire the `IntegrityChecker` immediately
    inside `OnAddAspectPolicy`, which runs *before* `NodeServiceImpl.addAspect()` has written
    the properties map to the database.  The result is a spurious `IntegrityException:
    Mandatory property not set` even when the caller passes a fully-populated properties map.
  - **Fix**: Use `<mandatory>true</mandatory>` (no `enforced` attribute).  The integrity check
    is then deferred to `beforeCommit`, by which time `addAspect()` has written both the aspect
    and its properties.
  - **Exception**: `enforced="true"` is safe only on properties belonging to **types** (not
    aspects), where the property must be supplied at node creation time via the REST API and
    is never set programmatically after the fact.

## Spring Context Validation
- If a companion `*-context.xml` exists, verify it registers the model via `<bean class="org.alfresco.repo.dictionary.DictionaryBootstrap">` or equivalent
- The `models` property must reference the correct model XML path

## Output
Report all violations with file path, line number, rule violated, and suggested fix. If no violations found, confirm the model is valid.
