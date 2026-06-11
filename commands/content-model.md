---
description: "Generate Alfresco content model XML and Spring context file from requirements."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /content-model — Content Model Generator

Generate Alfresco content model files based on requirements.

## Input
Read `REQUIREMENTS.md` (or use "$ARGUMENTS" as input) to extract content model requirements and
resolve the Platform JAR project's `Root path` from Section 2 (Project Architecture).

- If Section 2 contains no `Platform JAR` project, stop and explain that `/content-model` only
  applies to the in-process repository addon project.

## Output Files

### 1. Content Model XML
Create `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/model/content-model.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<model name="{prefix}:contentModel" xmlns="http://www.alfresco.org/model/dictionary/1.0">
    <description>...</description>
    <version>1.0</version>
    <imports>
        <import uri="http://www.alfresco.org/model/dictionary/1.0" prefix="d"/>
        <import uri="http://www.alfresco.org/model/content/1.0" prefix="cm"/>
    </imports>
    <namespaces>
        <namespace uri="http://www.{company}.com/model/{prefix}/1.0" prefix="{prefix}"/>
    </namespaces>
    <!-- types and aspects here -->
</model>
```

### 2. Spring Context
Create `{platform-project-root}/src/main/resources/alfresco/module/{module-id}/context/bootstrap-context.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans" ...>
    <bean id="{prefix}.dictionaryBootstrap"
          parent="dictionaryModelBootstrap"
          depends-on="dictionaryBootstrap">
        <property name="models">
            <list>
                <value>alfresco/module/{module-id}/model/content-model.xml</value>
            </list>
        </property>
    </bean>
</beans>
```

### 3. Model Constants Interface
Create `{platform-project-root}/src/main/java/{package}/model/{Name}Model.java`:

```java
package {package}.model;

import org.alfresco.service.namespace.QName;

/**
 * Constants for the {prefix} content model.
 *
 * Use these constants everywhere instead of constructing QNames inline.
 * The two-argument QName.createQName(URI, localName) form is safe at class-load
 * time because it does not require a registered namespace prefix resolver.
 */
public interface {Name}Model {

    String NAMESPACE_URI = "http://www.{company}.com/model/{prefix}/1.0";
    String NAMESPACE_PREFIX = "{prefix}";

    // --- Types ---
    QName TYPE_{TYPE_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{typeLocalName}");

    // --- Aspects ---
    QName ASPECT_{ASPECT_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{aspectLocalName}");

    // --- Properties ---
    QName PROP_{PROP_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{propLocalName}");

    // --- Associations ---
    QName ASSOC_{ASSOC_LOCAL_NAME_UPPER} = QName.createQName(NAMESPACE_URI, "{assocLocalName}");
}
```

**Rules:**
- Generate one `QName` constant per type, aspect, property, and association declared in the model
- Constant name format: `{KIND}_{LOCAL_NAME_IN_UPPER_SNAKE_CASE}` where `KIND` is `TYPE`, `ASPECT`, `PROP`, or `ASSOC`
- This is a Java `interface` — all fields are implicitly `public static final`; do NOT use `class`
- Always use the **two-argument** form `QName.createQName(NAMESPACE_URI, localName)` — never the shorthand `QName.createQName("{prefix}:{localName}")` which requires a registered namespace resolver at class-load time
- Place in package `{java-package}.model` (e.g. `com.acme.extensions.model`)
- Filename: `{PascalCasePrefix}Model.java` (e.g. prefix `acme` → `AcmeModel.java`)
- Never expose this interface as a Spring bean — it is a pure Java constant holder

## Modelling Reference

Apply these patterns inside the `<types>` / `<aspects>` of the content model when the
requirements call for them.

### Constraints (LIST / REGEX / LENGTH / MINMAX / custom)

Declare reusable constraints under `<constraints>` (sibling of `<types>`), then reference them
from a property with `<constraints><constraint ref="{prefix}:..."/></constraints>`.

```xml
<constraints>
    <constraint name="{prefix}:statusList" type="LIST">
        <parameter name="allowedValues">
            <list><value>Draft</value><value>Approved</value><value>Rejected</value></list>
        </parameter>
        <parameter name="caseSensitive"><value>true</value></parameter>
    </constraint>

    <constraint name="{prefix}:codePattern" type="REGEX">
        <parameter name="expression"><value>[A-Z]{2}-\d{4}</value></parameter>
        <parameter name="requiresMatch"><value>true</value></parameter>
    </constraint>

    <constraint name="{prefix}:shortText" type="LENGTH">
        <parameter name="minLength"><value>1</value></parameter>
        <parameter name="maxLength"><value>255</value></parameter>
    </constraint>

    <constraint name="{prefix}:scoreRange" type="MINMAX">
        <parameter name="minValue"><value>0</value></parameter>
        <parameter name="maxValue"><value>100</value></parameter>
    </constraint>

    <!-- Custom constraint: type is a fully-qualified class extending AbstractConstraint -->
    <constraint name="{prefix}:custom" type="{package}.model.constraint.{Name}Constraint"/>
</constraints>
```

A custom constraint class:
`{platform-project-root}/src/main/java/{package}/model/constraint/{Name}Constraint.java`

```java
package {package}.model.constraint;

import org.alfresco.repo.dictionary.constraint.AbstractConstraint;

public class {Name}Constraint extends AbstractConstraint {
    @Override
    protected void evaluateSingleValue(Object value) {
        // throw ConstraintException(...) when value is invalid
    }
}
```

- Use built-in `LIST`/`REGEX`/`LENGTH`/`MINMAX` before writing a custom constraint.
- A custom constraint `type` is the fully-qualified class name; the class extends
  `org.alfresco.repo.dictionary.constraint.AbstractConstraint`.

### Mandatory aspects

Force an aspect onto every instance of a type:

```xml
<type name="{prefix}:document">
    <parent>cm:content</parent>
    <mandatory-aspects>
        <aspect>{prefix}:auditable</aspect>
    </mandatory-aspects>
</type>
```

### Property indexing & tokenisation

Control how a property is indexed for search. `tokenised="false"` is required for exact-match
and sorting and pairs with the `=` AFTS prefix used by `/web-scripts` and `/behaviours`.

```xml
<property name="{prefix}:code">
    <type>d:text</type>
    <index enabled="true">
        <atomic>true</atomic>
        <stored>false</stored>
        <tokenised>false</tokenised>   <!-- false = exact match/sort; true = full-text; both = both -->
    </index>
</property>
```

### Associations: child vs peer

- **Child association** (`<child-association>`) — composition; deleting the parent cascades to
  children. Use for "owns / contains".
- **Peer association** (`<association>`) — a non-owning reference between independent nodes.

```xml
<associations>
    <child-association name="{prefix}:attachments">
        <source><mandatory>false</mandatory><many>true</many></source>
        <target><class>cm:content</class><mandatory>false</mandatory><many>true</many></target>
    </child-association>

    <association name="{prefix}:relatedTo">
        <source><mandatory>false</mandatory><many>true</many></source>
        <target><class>{prefix}:document</class><mandatory>false</mandatory><many>true</many></target>
    </association>
</associations>
```

### Multi-valued, default values & encryption

```xml
<property name="{prefix}:tags">
    <type>d:text</type>
    <multiple>true</multiple>            <!-- multi-valued -->
</property>
<property name="{prefix}:status">
    <type>d:text</type>
    <default>Draft</default>             <!-- default value applied on creation -->
    <constraints><constraint ref="{prefix}:statusList"/></constraints>
</property>
<property name="{prefix}:ssn">
    <type>d:encrypted</type>             <!-- transparently encrypted at rest -->
</property>
```

## Conventions
- `{module-id}` is the Platform JAR **artifactId** exactly as declared in `module.properties` under `module.id` minus the `{groupId}.` prefix — i.e. the bare artifact ID (e.g. `content-types`, not `com.someco.content-types`). Read it from `<artifactId>` in the platform `pom.xml`, or derive it as `{platform-artifactId}` from Section 2 of `REQUIREMENTS.md`. **Never use the full `module.id` property value as the directory name.**
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- Follow namespace naming from AGENTS.md
- Use `cm:content` as default parent for document types
- Use `cm:folder` as default parent for folder types
- Every property must specify a valid `d:` data type
- Include constraints where requirements specify them
- Never generate content model files inside the Event Handler project

## Validation
After generating files, invoke the `content-model-validator` skill to validate the output.
