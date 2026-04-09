---
description: "Gather and structure requirements for an Alfresco extension as user stories with acceptance criteria."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[description of the extension]"
---

# /requirements — Requirements Gathering

You are helping the user define requirements for an Alfresco Content Services extension.

Given the user's description in "$ARGUMENTS", produce a structured requirements document.

## Architecture Decision (ask first)

Before writing any section, ask the following architecture questions if the description does
not make the answers obvious.  Record the answers — they determine the whole project
structure.

**Q1 — Synchronous or asynchronous reaction?**
> "Does this feature need to react *within the same transaction* as the user action
> (e.g. reject an upload, enforce a rule, return an immediate API response)?
> Or can it react *after* the fact, asynchronously (e.g. send a notification,
> trigger an integration, update an analytics system)?"

**Q2 — Does it expose a repository REST API or web script?**
> "Does the feature need to expose a custom REST endpoint served by the ACS
> JVM itself?"

**Q3 — Does it need a multi-step approval workflow?**
> "Does this feature need to route content or tasks through multiple human approval
> steps, with assignee groups, parallel reviews, outcome decisions (approve/reject),
> timer escalations, or similar process orchestration?"

**Q4 — Does it need to customize the legacy Share UI itself?**
> "Does this feature need Share-tier artefacts such as `share-config-custom.xml`,
> Share forms, Surf pages/components, Aikau pages/widgets, dashlets, or evaluators?"

**Q5 — Is the UI target really Share, or should it be treated as a modern external frontend?**
> "If a user interface is needed, is the target the legacy Share web tier specifically?
> Or should this be treated as ACA/ADF/custom frontend work that consumes ACS APIs
> without deploying Share addon artefacts?"

**Project-selection rules** (use to populate Section 2 — Project Architecture):

| Need | Add this project |
|------|------------------|
| Same-transaction repository logic, ACS-hosted REST/Web Script, or workflow | **Platform JAR** |
| Legacy Share-tier UI customization | **Share JAR** |
| Asynchronous event-driven processing | **Event Handler** |

> **Workflow note**: Workflows always deploy into the Platform JAR (in-process, ACS JVM). If Q3 is Yes, the project must include a **Platform JAR** component (Mode A or Mixed). Document workflow requirements in Section 7 under "Workflow requirements" — not as a separate project.
>
> **UI note**: If Q4 is Yes but Q5 says the target should be ACA/ADF/custom frontend instead of Share, do **not** add a Share project. Record that decision explicitly in the requirements and keep the UI outside this repository unless other requirements justify repository-side code.

**Important:** **Mixed** means **two or more separate projects/deployables** in the same repository:
- a Platform JAR / AMP loaded by ACS, when repository-side code is needed
- a Share JAR / AMP loaded by Share, when Share-tier UI customization is needed
- a standalone Spring Boot Event Handler service, when async processing is needed

It never means a single Maven module containing repository addon code, Share-tier code,
and event-listener code all mixed together.

---

## Output Format

Create a file called `REQUIREMENTS.md` in the project root with:

### 1. Overview
- Extension name
- Business purpose (1-2 sentences)
- Target ACS version (from AGENTS.md or default 26.1)

### 2. Project Architecture

Derived from the architecture decision above. Every subsequent section must
reference which project each requirement belongs to.

```
| Project | Type | SDK | Root path | Purpose |
|---------|------|-----|-----------|---------|
| `{name}-platform` | Platform JAR | alfresco-sdk-aggregator 4.15.0 | `{name}-platform/` (or `.` if only project) | Synchronous behaviours, web scripts, content model |
| `{name}-share`    | Share JAR    | Maven JAR (Share web-tier addon) | `{name}-share/` (or `.` if only project) | Share forms, Surf pages, Aikau, evaluators |
| `{name}-events`   | Event Handler | alfresco-java-sdk 7.2.0   | `{name}-events/`   (omit if not needed)     | Async event-driven processing |
```

Rules:
- Include only the projects the feature actually needs.
- When there is only one project, its root path is `.` (the repo root), not a subdirectory.
- When multiple projects exist, they are siblings under the repo root and built by a top-level aggregator POM.
- When multiple projects exist, they are deployed separately: the Platform JAR/AMP goes into ACS, the Share JAR/AMP goes into Share, and the Event Handler runs as an independent Spring Boot service.
- The `Root path` column is authoritative for all downstream commands; every generated file must be written under the matching project root, never under the other project's root.

### 3. User Stories
For each requirement, write a user story:
```
As a [role], I want to [action], so that [benefit].
```

### 4. Acceptance Criteria
For each user story, list testable acceptance criteria:
```
Given [context], when [action], then [expected result].
```

### 5. Content Model Requirements
*(Platform JAR only — omit section if no Platform JAR)*
- Custom types needed (with parent type)
- Custom aspects needed
- Properties for each type/aspect (name, data type, mandatory, constraints)
- Associations (if any)

### 6. API Requirements
*(Platform JAR only — omit section if no Platform JAR)*
- Web Scripts needed (method, URL pattern, request/response)

### 7. Behaviour Requirements
- **In-process behaviours** *(Platform JAR)*: Policies/behaviours to trigger on node events synchronously; actions to register
- **Share UI requirements** *(Share JAR)*:
  - Share forms and `share-config-custom.xml` needs
  - Surf pages/components/templates
  - Aikau pages/widgets/dashlets
  - Evaluators or visibility rules
- **Event handlers** *(Event Handler)*: Alfresco Java Event API event types to consume and the async action to take
- **Workflow requirements** *(Platform JAR — only when Q3 is Yes)*:
  - Process name and high-level flow description
  - User task names, assignee expressions (`${initiator.properties.userName}`) or candidate groups (`GROUP_{GroupName}`)
  - Decision outcomes per task (e.g. Approve/Reject) with LIST constraint values
  - Parallel vs. sequential task structure
  - Timer escalations (duration in ISO 8601, e.g. `PT5M`; escalation action)
  - Process variables needed (name → type → initial value)
  - Workflow content model namespace and prefix (convention: `{prefix}wf`)

### 8. Deployment Requirements
- Docker Compose services needed
- Environment-specific configuration

### 9. Traceability Matrix
| Requirement ID | Project | User Story | Content Model | API | Behaviour / Handler | Workflow | Test |
|---------------|---------|------------|---------------|-----|---------------------|----------|------|

Leave the Test column empty — it will be filled by `/test`.
Add a **Project** column so each row is clearly tied to a specific project.

---

## Instructions
- Ask the architecture questions before writing any section if the description is ambiguous
- Default to Platform JAR packaging; use AMP only when the extension must bundle third-party libraries not already on the Alfresco classpath
- Treat Share-tier UI work as a separate deployable when the request explicitly targets Share
- If the requirement is really a modern ACA/ADF/custom frontend, record that and do not invent a Share project
- Reference CLAUDE.md conventions for naming and structure
- The output must be complete enough for `/scaffold` through `/test` to consume
- A behaviour that must roll back a transaction is *always* in-process; a side-effect that can be retried is *always* out-of-process
