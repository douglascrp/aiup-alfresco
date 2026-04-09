---
description: "Generate integration tests for Alfresco extensions using Testcontainers (self-contained, no pre-running ACS required)."
allowed-tools: "Read, Write, Grep, Glob"
argument-hint: "[path to REQUIREMENTS.md or description]"
---

# /test — Test Generator

Generate tests for the Alfresco extension.

## Input
Read `REQUIREMENTS.md` and all generated artefacts from previous commands.
Resolve the project `Root path` values from Section 2 (Project Architecture) before writing tests.

- Generate Platform JAR tests only when a `Platform JAR` project exists.
- Generate Share JAR tests only when a `Share JAR` project exists.
- Generate Event Handler tests only when an `Event Handler` project exists.
- In Mixed mode, write each test file under its own project root; do not place both test suites in
  the same module.

## Output Files

### In-Process SDK (Maven) — Platform JAR / AMP

#### 1. Testcontainers Integration Test
`{platform-project-root}/src/test/java/{package}/{Name}ContainerIT.java`

Self-contained: starts the ACS stack from `compose.yaml` via `DockerComposeContainer`, runs all
scenarios, then tears everything down. No pre-running ACS instance required.

```java
@Testcontainers(disabledWithoutDocker = true)
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class {Name}ContainerIT {

    @Container
    static final DockerComposeContainer<?> STACK =
            new DockerComposeContainer<>(new File("{compose-file-relative-path}"))
                    .withExposedService("alfresco_1", 8080,
                            Wait.forHttp("/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-")
                                    .withStartupTimeout(Duration.ofMinutes(10)))
                    .withLocalCompose(true);

    private String nodesApi;
    private String authHeader;
    private HttpClient http;

    @BeforeAll
    void setup() throws Exception {
        String host = STACK.getServiceHost("alfresco_1", 8080);
        int    port = STACK.getServicePort("alfresco_1", 8080);
        nodesApi   = "http://" + host + ":" + port
                   + "/alfresco/api/-default-/public/alfresco/versions/1/nodes";
        authHeader = "Basic " + Base64.getEncoder()
                .encodeToString("admin:admin".getBytes(StandardCharsets.UTF_8));
        http = HttpClient.newHttpClient();
        // create any shared test folder structure here
    }

    @AfterAll
    void cleanup() throws Exception {
        // permanently delete all test data
    }

    // @Test methods using java.net.http.HttpClient against nodesApi
}
```

- Use `java.net.http.HttpClient` for HTTP calls — no extra test dependencies.
- Use `@TestInstance(PER_CLASS)` + `@Order` when tests share state (e.g., a node created in test 1 is used in test 2).
- Cover all user stories and acceptance criteria from `REQUIREMENTS.md`.
- Create isolated test folder trees in `@BeforeAll`; permanently delete them in `@AfterAll`.

#### 2. External ACS Integration Test (optional)
`{platform-project-root}/src/test/java/{package}/{Name}IT.java`

Runs against an already-running ACS instance when `-Dacs.endpoint.path=` is provided.
Skips gracefully otherwise so `mvn verify` always succeeds without Docker.

```java
@BeforeAll
void setup() throws Exception {
    assumeTrue(System.getProperty("acs.endpoint.path") != null,
            "Skipping: set -Dacs.endpoint.path=http://host:8080 to run against an external ACS instance");
    // ...
}
```

#### 3. HTTP API Smoke Tests
`{platform-project-root}/http-tests/{extension-name}.sh`
- Plain shell scripts using `curl` + `jq`
- Cover: happy path, validation errors (400), not found (404), unauthorized (401)
- Use environment variables for `HOST`, `USERNAME`, `PASSWORD`
- Auto-detect `sha256sum` vs `shasum` where content hashing is needed

#### 3b. Workflow Integration Tests (when REQUIREMENTS.md Section 7 declares workflow requirements)

Add test methods to `{Name}ContainerIT.java` for each workflow scenario:

```java
// --- Workflow Testing Setup ---

private String workflowApi;
private String processId;   // shared across @Test methods

// In @BeforeAll, after the STACK starts:
workflowApi = "http://" + host + ":" + port
        + "/alfresco/api/-default-/public/workflow/versions/1";

// Discover processDefinitionId dynamically — never hardcode the version suffix (:1:104)
HttpRequest defReq = HttpRequest.newBuilder()
        .uri(URI.create(workflowApi + "/process-definitions?name={processName}"))
        .header("Authorization", authHeader)
        .GET().build();
HttpResponse<String> defResp = http.send(defReq, HttpResponse.BodyHandlers.ofString());
assertEquals(200, defResp.statusCode(), "Expected 200 on process-definitions query");
// Parse: $.list.entries[0].entry.id → processDefinitionId
String processDefinitionId = /* parse from defResp.body() */ null;
assertNotNull(processDefinitionId, "Process definition not found — did /workflow deploy correctly?");

// --- Test methods ---

@Test
@Order(10)
void shouldStartWorkflow() throws Exception {
    String body = """
        {
            "processDefinitionId": "%s",
            "variables": [
                {"name": "bpm_workflowDescription", "value": "Integration test workflow", "type": "d:text"}
            ]
        }
        """.formatted(processDefinitionId);
    HttpRequest req = HttpRequest.newBuilder()
            .uri(URI.create(workflowApi + "/processes"))
            .header("Authorization", authHeader)
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(body)).build();
    HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
    assertEquals(201, resp.statusCode(), "Expected 201 on process start: " + resp.body());
    // Parse processId from resp.body() → $.entry.id
}

@Test
@Order(20)
void shouldShowPendingTask() throws Exception {
    HttpRequest req = HttpRequest.newBuilder()
            .uri(URI.create(workflowApi + "/tasks?processId=" + processId))
            .header("Authorization", authHeader)
            .GET().build();
    HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
    assertEquals(200, resp.statusCode());
    // Assert task count > 0 and verify candidateGroup / assignee
}

@Test
@Order(30)
void shouldCompleteTaskWithApproveOutcome() throws Exception {
    // First retrieve the task ID
    // Then complete with outcome variable in UNDERSCORE form (not colon)
    String taskId = /* retrieve first task ID */ null;
    String body = """
        {
            "action": "complete",
            "variables": [
                {"name": "{prefix}wf_{taskName}Outcome", "value": "Approve", "type": "d:text"}
            ]
        }
        """;
    HttpRequest req = HttpRequest.newBuilder()
            .uri(URI.create(workflowApi + "/tasks/" + taskId))
            .header("Authorization", authHeader)
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(body)).build();
    HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
    assertEquals(200, resp.statusCode(), "Expected 200 on task complete: " + resp.body());
}

@Test
@Order(40)
void shouldRejectAndReturnToInitiator() throws Exception {
    // Start a new process, complete with Reject outcome, assert workflow routes to revise task
}

@AfterAll
void cleanupWorkflows() throws Exception {
    // Delete all test-started processes using admin credentials
    if (processId != null) {
        HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(workflowApi + "/processes/" + processId))
                .header("Authorization", authHeader)
                .DELETE().build();
        http.send(req, HttpResponse.BodyHandlers.ofString());
    }
}
```

**Workflow test conventions:**
- Always discover `processDefinitionId` via `GET /process-definitions?name={processName}` — never hardcode the version suffix (`:1:104`)
- Use `POST /tasks/{taskId}` with `"action": "complete"` — not legacy patterns
- Workflow variable names in the REST API use the **underscore form** (`{prefix}wf_{propName}`) — matches Alfresco's colon→underscore mapping
- Clean up test processes in `@AfterAll` using admin credentials; use `DELETE /processes/{id}`
- Timer tests: set timer duration to `PT5S` in a test-specific BPMN variant, or document separately as requiring a slow test suite

---

#### 4. Maven Failsafe + Testcontainers configuration

Add to `{platform-project-root}/pom.xml`:

```xml
<properties>
    <testcontainers.version>1.20.2</testcontainers.version>
    <maven.failsafe.plugin.version>3.2.5</maven.failsafe.plugin.version>
</properties>

<dependencyManagement>
    <dependencies>
        <!-- existing Alfresco BOM ... -->
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>testcontainers-bom</artifactId>
            <version>${testcontainers.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <!-- existing deps ... -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>testcontainers</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>

<build>
    <plugins>
        <!-- Surefire: unit tests only -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <configuration>
                <excludes><exclude>**/*IT.java</exclude></excludes>
            </configuration>
        </plugin>
        <!-- Failsafe: IT classes (Testcontainers + optional external) -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-failsafe-plugin</artifactId>
            <version>${maven.failsafe.plugin.version}</version>
            <executions>
                <execution>
                    <goals>
                        <goal>integration-test</goal>
                        <goal>verify</goal>
                    </goals>
                </execution>
            </executions>
            <configuration>
                <includes><include>**/*IT.java</include></includes>
                <systemPropertyVariables>
                    <acs.endpoint.path>${acs.endpoint.path}</acs.endpoint.path>
                    <acs.username>${acs.username}</acs.username>
                    <acs.password>${acs.password}</acs.password>
                </systemPropertyVariables>
                <!-- Docker Desktop 29.x on macOS requires API >= 1.40; docker-java defaults to older versions.
                     API_VERSION (not DOCKER_API_VERSION) is the env var docker-java 3.3.x actually reads. -->
                <environmentVariables>
                    <API_VERSION>1.44</API_VERSION>
                </environmentVariables>
            </configuration>
        </plugin>
    </plugins>
</build>
```

### Share JAR — Structural and Smoke Validation

Generate these only when a `Share JAR` project is declared in `REQUIREMENTS.md`.

#### 1. Share resource structure test

`{share-project-root}/src/test/java/{package}/share/{Name}ShareResourcesTest.java`

Use lightweight tests that validate generated Share resources without requiring a browser:

```java
class {Name}ShareResourcesTest {

    @Test
    void shouldLoadShareConfigWhenPresent() throws Exception {
        // parse share-config-custom.xml when /share-config was used
    }

    @Test
    void shouldLoadSurfExtensionMetadataWhenPresent() throws Exception {
        // parse site-data/extensions/*.xml when /surf was used
    }

    @Test
    void shouldLoadAikauPageArtifactsWhenPresent() throws Exception {
        // assert descriptor + JS model files exist when /aikau was used
    }
}
```

Required checks:

- `share-config-custom.xml` is well-formed XML when generated
- Surf extension metadata is well-formed XML when generated
- page descriptor XML files are well-formed
- Aikau page-model JS and optional widget modules exist when referenced
- message bundle keys referenced by generated Share artefacts are present
- no Share artefacts were written under `alfresco/module/...`

#### 2. Share smoke test shell script

`{share-project-root}/http-tests/share-smoke.sh`

Generate a plain shell script using `curl` that:

- checks `http://{host}/share/` and accepts `2xx` or `3xx`
- checks generated Share page URLs (for `/surf` or `/aikau`) and accepts login redirect or success
- fails clearly if Share is unhealthy or a generated page path returns an unexpected status

Example checks:

```bash
curl -s -o /dev/null -w '%{http_code}' "$HOST/share/" | grep -qE '^[23]'
curl -s -o /dev/null -w '%{http_code}' "$HOST/share/page/$PAGE_ID" | grep -qE '^[23]'
```

#### 3. Share validation conventions

- Do not require browser automation by default
- Prefer structural validation plus HTTP smoke checks over brittle DOM assertions
- When a page requires authentication, accept `302` redirect to login as evidence that the Share route is registered
- If the scenario includes both repo and Share projects, validate each module from its own root and then run stack-level smoke checks from the repository root
- Keep Share tests in the Share project; do not place them in the Platform JAR or Event Handler projects

> **macOS one-time setup**: Docker Desktop 29.x rejects Docker API versions below 1.40.
> The `<environmentVariables>` block above covers CI, but local developer machines also need:
> ```bash
> echo "api.version=1.44" >> ~/.docker-java.properties
> cat > ~/.testcontainers.properties <<'EOF'
> testcontainers.reuse.enable=true
> docker.client.strategy=org.testcontainers.dockerclient.UnixSocketClientProviderStrategy
> EOF
> ```
> See the *Docker Desktop on macOS — Testcontainers Compatibility* section in `AGENTS.md` for details.

**Run commands**:
```bash
# Self-contained (Docker required, port 8080 must be free)
mvn verify

# Against a running stack
mvn verify -Dacs.endpoint.path=http://localhost:8080

# Skip container tests, only build
mvn package -DskipITs
```

> **Prerequisite**: `compose.yaml` must exist at the repository root with the ACS stack and a volume mount
> for the extension JAR. Run `/docker-compose` first if it has not been generated yet.

---

### Out-of-Process SDK (Spring Boot) — Event Listeners

#### 1. Unit Tests
`{event-project-root}/src/test/java/{package}/handler/{Name}EventHandlerTest.java`
- JUnit 5 + Mockito
- Mock `AlfrescoEvent` payloads and verify handler logic in isolation

#### 2. Integration Test
`{event-project-root}/src/test/java/{package}/{Name}IT.java`
- Use an embedded ActiveMQ broker (`@EmbeddedActiveMQ`) or Testcontainers
- Publish a synthetic event, verify the handler processes it correctly
- Assert any side effects (external calls, state changes)

---

### Update Traceability
Update the Traceability Matrix in `REQUIREMENTS.md` with test references pointing to the
generated test class and method names.

## Conventions
- `{platform-project-root}` is `.` for Platform JAR only mode, or `{name}-platform/` for Mixed mode
- `{event-project-root}` is `.` for Event Handler only mode, or `{name}-events/` for Mixed mode
- `{compose-file-relative-path}` is `compose.yaml` for single-project layouts and typically `../compose.yaml` for child modules in Mixed mode
- Integration test class name ends with `IT`
- `@TestMethodOrder(MethodOrderer.OrderAnnotation.class)` for ordered execution
- Clean up test data in `@AfterAll` using `?permanent=true` deletes
- HTTP test scripts set `set -euo pipefail` and report pass/fail counts
