---
description: "Generate custom Alfresco permission groups and permissions (permissionDefinitions.xml extension) plus optional dynamic authorities, Spring registration, and unit test. In-Process SDK (Maven) only."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /permissions — Custom Permission Model Generator

> **In-Process SDK only** — custom permissions deploy inside the ACS JVM as part of the
> Platform JAR. They extend the global permission model; they are **not** a Share-tier concern.

Generate a custom permission model (permission groups + permissions) and optional dynamic
authorities from requirements.

## Input

Read `REQUIREMENTS.md` to identify permission requirements:

1. Resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).
   - If Section 2 contains no `Platform JAR` project, stop and explain that `/permissions`
     only applies to the in-process Platform JAR project.

2. Read Section 5 (Content Model Requirements) and any "Permission requirements" sub-section.
   - Custom permissions are granted on a **type or aspect** — identify which custom type/aspect
     (from `/content-model`) the permission set applies to. If none is declared, ask the user to
     run `/requirements` first (or provide a description as `$ARGUMENTS`).

3. From Section 2, derive:
   - `{platform-project-root}` — `.` for Platform JAR only mode; `{name}-platform/` for Mixed mode
   - `{module-id}` — the Platform JAR **artifactId** (bare artifact ID, e.g. `my-extension`).
     Read from `<artifactId>` in the platform `pom.xml` or derive as `{platform-artifactId}` from
     Section 2. **Never use the full `module.id` property value as the directory name.**
   - `{java-package}` — the Java package declared in Section 2
   - `{prefix}` — the namespace prefix declared in Section 5 (Content Model Requirements)

4. Derive from permission requirements:
   - `{TypeOrAspect}` — the qualified name the permission set is bound to (e.g. `sc:document`)
   - `{PermissionGroup}` — PascalCase permission group name (e.g. `Publisher`, `Reviewer`)
   - `{Permission}` — individual permission names (e.g. `Publish`, `Withdraw`)
   - Whether a **dynamic authority** is needed (a programmatic authority such as
     "the document's assigned reviewer") — generate one only if requirements call for it

---

## Output Files

> **The permission model XML and the Spring registration are required.** Generate a dynamic
> authority class + its unit test only when the requirements describe a programmatic authority.

### 1. Permission Model XML
`{platform-project-root}/src/main/resources/alfresco/extension/{prefix}-permissionDefinitions.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE permissions PUBLIC "-//ALFRESCO//DTD Permissions//EN" "permissionSchema.dtd">
<permissions>

    <permissionSet type="{prefix}:{typeOrAspect}" expose="selected">

        <!-- A composite permission group exposed in the UI -->
        <permissionGroup name="{PermissionGroup}" requiresType="true" expose="true">
            <includePermissionGroup permissionGroup="Read" type="cm:cmobject"/>
            <includePermissionGroup permissionGroup="{Permission}Group" type="{prefix}:{typeOrAspect}"/>
        </permissionGroup>

        <!-- A single permission backed by its own group -->
        <permission name="{Permission}" expose="true" requiresType="false">
            <grantedToGroup permissionGroup="{Permission}Group"/>
        </permission>

        <permissionGroup name="{Permission}Group" requiresType="true" expose="false"/>

    </permissionSet>

</permissions>
```

Key rules for the permission model XML:
- The root element is `<permissions>` with the Alfresco Permissions DTD.
- Bind the `<permissionSet>` to a **custom** type or aspect (`type="{prefix}:..."`). Never
  redefine a `<permissionSet>` for a built-in type in a way that removes core groups.
- **Never reuse built-in permission group names** (`Read`, `Write`, `Delete`, `Consumer`,
  `Contributor`, `Editor`, `Collaborator`, `Coordinator`, `SiteManager`, …). Use project-scoped
  names like `{PermissionGroup}`. You may `includePermissionGroup` a built-in group inside a
  custom group — that is the correct way to compose on top of core permissions.
- Set `expose="true"` on groups/permissions that should appear in permission-management UIs;
  `expose="false"` hides an implementation-only group.
- Use `requiresType="true"` when the permission only makes sense on nodes of the bound type.

### 2. Spring Registration
`{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/permissions-context.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- Register the extension permission model so the permissionsModelDAO loads it -->
    <bean id="{prefix}.permissionModelBootstrap"
          parent="permissionModelBootstrap">
        <property name="model" value="alfresco/extension/{prefix}-permissionDefinitions.xml"/>
    </bean>

    <!-- Optional: register the dynamic authority (only if generated) -->
    <bean id="{prefix}.{name}DynamicAuthority"
          class="{package}.security.{Name}DynamicAuthority">
        <property name="nodeService" ref="NodeService"/>
    </bean>

    <!-- Add the dynamic authority to the global list (only if generated) -->
    <bean id="{prefix}.dynamicAuthorityRegistration"
          class="org.springframework.beans.factory.config.MethodInvokingFactoryBean">
        <property name="targetObject" ref="dynamicAuthorities"/>
        <property name="targetMethod" value="add"/>
        <property name="arguments">
            <list><ref bean="{prefix}.{name}DynamicAuthority"/></list>
        </property>
    </bean>

</beans>
```

Also add the import to `module-context.xml`:
```xml
<import resource="classpath:alfresco/module/{module-id}/context/permissions-context.xml"/>
```

Key rules for registration:
- Register the model with a bean whose `parent="permissionModelBootstrap"` and a `model`
  property pointing at the extension `permissionDefinitions.xml`. This **adds** to the global
  permission model — it does not replace the core `permissionDefinitions.xml`.
- Register a dynamic authority only when one is generated; otherwise omit the last two beans.

### 3. Dynamic Authority Class (optional)
`{platform-project-root}/src/main/java/{package}/security/{Name}DynamicAuthority.java`

```java
package {package}.security;

import org.alfresco.repo.security.permissions.DynamicAuthority;
import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
import org.alfresco.service.cmr.security.PermissionService;

import java.util.Set;

public class {Name}DynamicAuthority implements DynamicAuthority {

    public static final String AUTHORITY = "{prefix}_{name}";

    private NodeService nodeService;

    @Override
    public boolean hasAuthority(NodeRef nodeRef, String userName) {
        if (!nodeService.exists(nodeRef)) {
            return false;
        }
        // Return true when userName should be granted this dynamic authority on nodeRef.
        return false; // replace with actual logic
    }

    @Override
    public String getAuthority() {
        return AUTHORITY;
    }

    @Override
    public Set<PermissionReference> requiredFor() {
        // Return null to apply to all permissions, or a specific set of PermissionReference.
        return null;
    }

    public void setNodeService(NodeService nodeService) {
        this.nodeService = nodeService;
    }
}
```

Key rules for the dynamic authority:
- Implement `org.alfresco.repo.security.permissions.DynamicAuthority` directly.
- `getAuthority()` returns the pseudo-authority string (e.g. `{prefix}_{name}`); reference it in
  the permission model with `<grantedToGroup>`/`<requiredPermission>` if the authority should
  carry a permission.
- `hasAuthority(NodeRef, userName)` must guard with `nodeService.exists()` and must be cheap —
  it runs on every permission evaluation for the node.
- Use setter injection only — no `@Autowired`. Never call `AuthenticationUtil.runAsSystem` in
  `hasAuthority` for a user-facing check.

### 4. Unit Test (optional — only when a dynamic authority is generated)
`{platform-project-root}/src/test/java/{package}/security/{Name}DynamicAuthorityTest.java`

```java
package {package}.security;

import org.alfresco.service.cmr.repository.NodeRef;
import org.alfresco.service.cmr.repository.NodeService;
import org.alfresco.service.cmr.repository.StoreRef;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class {Name}DynamicAuthorityTest {

    @Mock NodeService nodeService;

    private {Name}DynamicAuthority authority;
    private final NodeRef nodeRef = new NodeRef(StoreRef.STORE_REF_WORKSPACE_SPACESSTORE, "test-node-id");

    @BeforeEach
    void setUp() {
        authority = new {Name}DynamicAuthority();
        authority.setNodeService(nodeService);
    }

    @Test
    void hasAuthority_returnsFalse_whenNodeDoesNotExist() {
        when(nodeService.exists(nodeRef)).thenReturn(false);

        assertFalse(authority.hasAuthority(nodeRef, "alice"));
    }

    @Test
    void getAuthority_returnsExpectedPseudoAuthority() {
        assertEquals({Name}DynamicAuthority.AUTHORITY, authority.getAuthority());
    }
}
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** — the bare artifact ID. Derive it as
  `{platform-artifactId}` from Section 2 or from `<artifactId>` in the platform `pom.xml`.
  **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Permission model file: `alfresco/extension/{prefix}-permissionDefinitions.xml`
- Permission group / permission names: PascalCase, project-scoped — **never** a built-in name
- Dynamic authority bean ID: `{prefix}.{name}DynamicAuthority`; pseudo-authority string `{prefix}_{name}`
- Always use `PermissionService` to set/check permissions at runtime — never bypass it
- Never generate permission models inside the Event Handler project
- After generating files, invoke the `permission-model-validator` skill

## Share UI Note
Custom permission **groups** can be surfaced in the Share "Manage Permissions" UI via a
`share-config-custom.xml` entry in a Share JAR — use `/share-config` for that. The permission
model itself (this command) is a repository (Platform JAR) artefact.
