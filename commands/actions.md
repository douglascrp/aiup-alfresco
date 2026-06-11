---
description: "Scaffold Alfresco ActionExecuter classes with Spring bean registration. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /actions — Action Executor Generator

> **In-Process SDK only** — deploys inside the ACS JVM as a Platform JAR.

Generate Alfresco action classes.

## Input
Read `REQUIREMENTS.md` to identify action requirements and resolve the Platform JAR
project's `Root path` from Section 2 (Project Architecture).

- If Section 2 contains no `Platform JAR` project, stop and explain that `/actions`
  only applies to the in-process repository addon project.

## Output Files

### 1. Action Class
`{platform-project-root}/src/main/java/{package}/action/{Name}ActionExecuter.java`
- Extend `ActionExecuterAbstractBase`
- Implement `executeImpl()` method
- Define parameters via `addParameterDefinitions()`

### 2. Spring Bean Registration
Add to `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/service-context.xml`:
```xml
<bean id="{prefix}.{actionName}" class="{package}.action.{Name}ActionExecuter" parent="action-executer">
    <property name="nodeService" ref="NodeService"/>
    <!-- additional service references -->
</bean>
```

## Action Reference

### Synchronous vs asynchronous execution
Actions can run inline or in a background thread. Asynchronous actions run in their **own
transaction** after the current one commits.

```java
// Programmatic invocation
actionService.executeAction(action, nodeRef, checkConditions, executeAsynchronously);
```

- Set `executeAsynchronously=true` for long-running or external-integration work so the caller's
  transaction is not held open.
- An action can also declare a default by overriding `getAdhocPropertiesAllowed()` /
  setting the executer's `executeAsynchronously` bean property.

### Parameter constraints (dropdown-style values)
To constrain a parameter to a fixed set of values, reference a registered parameter constraint
in `getParameterDefinitions()`:

```java
paramList.add(new ParameterDefinitionImpl(
    PARAM_TARGET_STATUS, DataTypeDefinition.TEXT, true,
    getParamDisplayLabel(PARAM_TARGET_STATUS),
    false, "{prefix}-statusConstraint"));   // last arg = registered ParameterConstraint name
```

Register the constraint bean with `parent="action-constraint"` (or a `BaseParameterConstraint`
subclass) in `service-context.xml`.

### Composite actions
Chain several actions into one unit with `CompositeAction`:

```java
CompositeAction composite = actionService.createCompositeAction();
composite.addAction(actionService.createAction("{prefix}-first"));
composite.addAction(actionService.createAction("{prefix}-second"));
actionService.executeAction(composite, nodeRef);
```

### Sharing service-context.xml
Actions, rule conditions (`/rule-conditions`), and parameter constraints share
`service-context.xml`. If it already exists, append the bean — do not create a second file.

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID (e.g. `actions`), not the full `module.id` property value (e.g. `com.someco.actions`). Derive it as `{platform-artifactId}` from Section 2 of `REQUIREMENTS.md` or from `<artifactId>` in the platform `pom.xml`. **Never use `{groupId}.{artifactId}` as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Action name format: `{prefix}-{action-name}`
- Use parent `action-executer` bean
- Define compensation action if the operation is reversible
- Never generate action executers inside the Event Handler project

## Share UI / Rules Registration
Registering the bean makes the action available programmatically and via the Action REST API.
To surface it in the **Share Rules UI** (the action dropdown in a folder rule), a
`share-config-custom.xml` entry in a Share JAR is also needed — use `/share-config` for that.
