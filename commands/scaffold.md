---
description: "Scaffolds one deployable project or a mixed two-project repository from REQUIREMENTS.md: pom.xml(s), module.properties, module-context.xml, and Spring Boot Application class. Supports Platform JAR (in-process), Event Handler (out-of-process), and Mixed (both) architectures. Run this first, before /content-model."
user-invocable: true
allowed-tools: "Read, Write, Glob"
---

# /scaffold — Project Scaffolding

Generates the build and bootstrap files needed to compile and package the extension.
Must run **once**, at the start of a project, before any other generation command.

## Input

1. Read `REQUIREMENTS.md` — specifically **Section 2 (Project Architecture)** to determine
   which projects to scaffold.  If `REQUIREMENTS.md` does not exist, stop and instruct the
   user to run `/requirements` first.

2. Ask the user for:
   - `groupId` — Java group ID (e.g. `com.acme`) if not inferrable from requirements
   - `artifactId` — base Maven artifact ID (default: kebab-case of extension name)

3. Derive from `REQUIREMENTS.md`:
   - `{platform-artifactId}` = `{artifactId}` in Mode A, `{artifactId}-platform` in Mode C
   - `{events-artifactId}` = `{artifactId}` in Mode B, `{artifactId}-events` in Mode C
   - `{module-id}` = `{platform-artifactId}` (the Platform JAR module's artifact ID)
   - `{java-package}` = `{groupId}.{artifactId-camelCase}` (e.g. `com.acme.duplicateguard`)
   - `{acs-version}` = target ACS version (e.g. `26.1` → property value `26.1.0`)

## Critical Separation Rule

When `REQUIREMENTS.md` declares both a Platform JAR project and an Event Handler project:

- generate **two sibling child modules/projects**, not one combined Maven module
- keep repository addon files only in the Platform JAR project
- keep Spring Boot event-listener files only in the Event Handler project
- leave the repo root as an aggregator only; do **not** create a runtime `src/` tree there

Forbidden output shape:
- one Maven module containing both `src/main/resources/alfresco/module/...` and Spring Boot `Application.java` / `application.properties`
- one POM that attempts to mix `alfresco-sdk-aggregator` and `alfresco-java-sdk`

---

## Architecture Modes

### Mode A — Platform JAR only (in-process)
Single project at the repo root.

```
.
├── pom.xml
├── src/main/java/{java-package}/
├── src/main/resources/alfresco/module/{module-id}/
│   ├── module.properties
│   ├── module-context.xml
│   └── context/ (bootstrap-context.xml, service-context.xml)
└── src/test/java/{java-package}/
```

### Mode B — Event Handler only (out-of-process)
Single Spring Boot project at the repo root.

```
.
├── pom.xml
├── src/main/java/{java-package}/
│   └── Application.java
├── src/main/resources/application.properties
└── src/test/java/{java-package}/
```

### Mode C — Mixed (both)
Aggregator POM at the repo root, two child modules as sibling directories.

```
.
├── pom.xml                        ← aggregator (packaging=pom, no SDK parent)
├── {artifactId}-platform/         ← Platform JAR child module
│   ├── pom.xml
│   ├── src/main/java/{java-package}/
│   └── src/main/resources/alfresco/module/{artifactId}-platform/
│       ├── module.properties
│       ├── module-context.xml
│       └── context/
└── {artifactId}-events/           ← Event Handler child module
    ├── pom.xml
    ├── src/main/java/{java-package}/
    │   └── Application.java
    └── src/main/resources/application.properties
```

---

## Output Files

### Platform JAR — `pom.xml`
*(Root for Mode A; `{artifactId}-platform/pom.xml` for Mode C)*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
             https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.alfresco.maven</groupId>
        <artifactId>alfresco-sdk-aggregator</artifactId>
        <version>4.15.0</version>
    </parent>

    <groupId>{groupId}</groupId>
    <artifactId>{platform-artifactId}</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>{Human Readable Name}</name>
    <description>{description from REQUIREMENTS.md}</description>

    <properties>
        <alfresco.platform.version>{acs-version}.0</alfresco.platform.version>
        <alfresco.platform.war.artifactId>alfresco-community</alfresco.platform.war.artifactId>
        <junit.jupiter.version>5.10.2</junit.jupiter.version>
        <maven.compiler.plugin.version>3.13.0</maven.compiler.plugin.version>
        <maven.surefire.plugin.version>3.2.5</maven.surefire.plugin.version>
        <maven.compiler.release>17</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.alfresco</groupId>
                <artifactId>${alfresco.bomDependency.artifactId}</artifactId>
                <version>${alfresco.platform.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <dependency>
            <groupId>org.alfresco</groupId>
            <artifactId>alfresco-repository</artifactId>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.alfresco</groupId>
            <artifactId>alfresco-remote-api</artifactId>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.alfresco.surf</groupId>
            <artifactId>spring-webscripts</artifactId>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>${junit.jupiter.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>${maven.compiler.plugin.version}</version>
                <configuration><release>17</release></configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>${maven.surefire.plugin.version}</version>
                <configuration>
                    <excludes><exclude>**/*IT.java</exclude></excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

**Rules:**
- `alfresco.platform.version` must end in `.0` (e.g. ACS `26.1` → `26.1.0`)
- `alfresco.platform.war.artifactId` is always `alfresco-community` for development scaffolding
- Import `${alfresco.bomDependency.artifactId}` in `<dependencyManagement>` to resolve Alfresco and Spring versions
- `spring-webscripts` must be listed explicitly even though it is transitive via `alfresco-remote-api`
- Use `org.alfresco.surf:spring-webscripts` for ACS 26.1 scaffolds
- Do NOT add version tags to Alfresco dependencies — the Alfresco BOM manages them after it is imported
- Pin `junit-jupiter`, `maven-compiler-plugin`, and `maven-surefire-plugin` explicitly in the generated POM
- Do NOT add the AMP plugin unless the user explicitly requests AMP packaging
- In Mode C, the Platform JAR child module still keeps `alfresco-sdk-aggregator` as its parent; the root aggregator is **not** this POM's parent

---

### Platform JAR — `module.properties`
*`src/main/resources/alfresco/module/{module-id}/module.properties`*  
*(Mode A at repo root; Mode C under `{artifactId}-platform/`.)*

```properties
module.id={groupId}.{module-id}
module.title={Human Readable Title}
module.description={description from REQUIREMENTS.md}
module.version=1.0.0
module.repo.version.min={acs-version}
```

**Rules:**
- `module.id` must be globally unique across all modules in the repository
- `module.repo.version.min` uses the short ACS version without the patch suffix (e.g. `26.1`)
- Never add `module.repo.version.max` unless the requirements explicitly cap compatibility

---

### Platform JAR — `module-context.xml`
*`src/main/resources/alfresco/module/{module-id}/module-context.xml`*  
*(Mode A at repo root; Mode C under `{artifactId}-platform/`.)*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="
           http://www.springframework.org/schema/beans
           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!--
        Module Spring entry point — import sub-contexts only, never define beans here.
        Load order matters: bootstrap first (dictionary), then services/behaviours,
        then web scripts.
    -->
    <import resource="classpath:alfresco/module/{module-id}/context/bootstrap-context.xml"/>
    <!-- /workflow   adds: workflowDeployer bean in bootstrap-context.xml (no new import needed) -->
    <!-- /behaviours adds: service-context.xml  -->
    <!-- /web-scripts adds: webscript-context.xml (if separate from service-context.xml) -->
    <!-- /actions    adds: action-context.xml   -->

</beans>
```

**Rules:**
- This is the **sole entry point** the Alfresco module loader reads — import only, no bean definitions
- `bootstrap-context.xml` must always be the first import
- Append one `<import>` line each time a new sub-context is generated by a subsequent command

---

### Event Handler — `pom.xml`
*(Root for Mode B; `{artifactId}-events/pom.xml` for Mode C)*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
             https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.alfresco</groupId>
        <artifactId>alfresco-java-sdk</artifactId>
        <version>7.2.0</version>
    </parent>

    <groupId>{groupId}</groupId>
    <artifactId>{events-artifactId}</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>{Human Readable Name} — Event Handler</name>
    <description>{description from REQUIREMENTS.md} (asynchronous event-driven component)</description>

    <properties>
        <maven.compiler.release>17</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <!--
            Starter auto-configures ActiveMQ listener, event deserialisation,
            and the Alfresco Java Event API beans.
        -->
        <dependency>
            <groupId>org.alfresco</groupId>
            <artifactId>alfresco-java-event-api-spring-boot-starter</artifactId>
        </dependency>

        <!-- JUnit 5 + Mockito for unit and integration tests -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

**Rules:**
- Do NOT specify a `<version>` for `alfresco-java-event-api-spring-boot-starter` — managed by the SDK parent BOM
- `spring-boot-maven-plugin` is required to produce an executable fat JAR
- In Mode C, the Event Handler child module still keeps `alfresco-java-sdk` as its parent; the root aggregator is **not** this POM's parent

---

### Event Handler — `Application.java`
*`src/main/java/{java-package}/Application.java`*  
*(Mode B at repo root; Mode C under `{artifactId}-events/`.)*

```java
package {java-package};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

---

### Event Handler — `application.properties`
*`src/main/resources/application.properties`*  
*(Mode B at repo root; Mode C under `{artifactId}-events/`.)*

```properties
# ActiveMQ broker connection — values injected from environment variables.
# See AGENTS.md §ActiveMQ Configuration for the full variable mapping.
spring.activemq.broker-url=${SPRING_ACTIVEMQ_BROKER_URL:tcp://localhost:61616}
spring.activemq.user=${SPRING_ACTIVEMQ_USER:admin}
spring.activemq.password=${SPRING_ACTIVEMQ_PASSWORD:admin}

# Alfresco event topic (default; override only if ACS is configured differently)
alfresco.events.defaultExchangeName=alfresco.repo.event2
```

**Rules:**
- Always use environment variable placeholders with defaults — never hardcode credentials
- Do not add properties that the starter auto-configures unless overriding the default

---

### Mixed — Aggregator `pom.xml`
*(Root `pom.xml` for Mode C only)*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
             https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <!--
        Aggregator POM — no parent, no dependencies.
        Each child module declares its own SDK parent independently.
    -->
    <groupId>{groupId}</groupId>
    <artifactId>{artifactId}</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <name>{Human Readable Name}</name>
    <description>{description from REQUIREMENTS.md}</description>

    <modules>
        <module>{artifactId}-platform</module>
        <module>{artifactId}-events</module>
    </modules>

    <properties>
        <maven.compiler.release>17</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

</project>
```

**Rules:**
- The aggregator must have `<packaging>pom</packaging>` and **no** `<parent>` element
- Do not define dependencies or plugins in the aggregator — each child manages its own
- `mvn clean package` from the aggregator root builds both child modules in declaration order
- Do not create runtime source files under the repo root in Mode C

---

## Conventions

| Item | Rule |
|------|------|
| `{module-id}` | `{platform-artifactId}`; in Mode C this means `{artifactId}-platform` |
| `{java-package}` | `{groupId}.{artifactId-nohyphens}` (e.g. `com.acme.invoiceprocessor`) |
| Platform JAR suffix (Mode C) | `{artifactId}-platform` |
| Event Handler suffix | always `{artifactId}-events` |
| `<packaging>` | Platform JAR → `jar`; Event Handler → `jar`; Aggregator → `pom` |

---

## Workflow Position

```
/requirements  →  /scaffold  →  /content-model  →  /workflow  →  /behaviours  →  /web-scripts  →  /actions  →  /events  →  /docker-compose  →  /test
```

- `/scaffold` must run before all generation commands: `pom.xml` must exist to compile, `module.properties` and `module-context.xml` must exist for the Platform JAR loader, and `Application.java` must exist for the Spring Boot auto-configuration to start.
- After `/scaffold`, subsequent commands (`/behaviours`, `/web-scripts`, `/events`) will add sub-context imports to `module-context.xml` or handler classes to the event handler module.
