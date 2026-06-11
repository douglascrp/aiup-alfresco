# validate-tutorials

Static validation harness that checks `aiup-alfresco` generates structurally correct
artefacts for each tutorial scenario.

## How it works

Each scenario has two parts:

1. `scenarios/<scenario>/REQUIREMENTS.md` — describes the extension (also the input to
   live generation via `generate-all.sh`).
2. `scenarios/<scenario>/fixture/` — a small, committed, known-good artefact tree.
3. `checks/<scenario>.sh` — asserts the structural rules against a project directory.

`run-scenario.sh`/`run-all.sh` validate the **committed fixtures** by default, so the suite
runs **fully offline**: no sibling repository, no pre-populated `generated/` directory, no
`claude` CLI, no network, no Docker — just `bash`, `xmllint`, and `grep`.

`generate-all.sh` is the separate, optional **live-generation** tester: it runs the actual
slash commands via `claude -p` into `generated/<scenario>/` (requires the `claude` CLI), which
you can then validate by pointing `run-scenario.sh` at that directory.

## Running checks (offline, default)

```bash
# All scenarios (against committed fixtures):
./run-all.sh

# Single scenario:
./run-scenario.sh content-types

# Validate a real generated/other project instead of the fixture:
./run-scenario.sh content-types /path/to/my/generated/project
```

## Live generation (optional, requires claude CLI)

```bash
# Generate all scenarios into generated/ using claude -p:
./generate-all.sh

# Generate a single scenario, then validate the generated output:
./generate-all.sh content-types && ./run-scenario.sh content-types generated/content-types
```

## What is checked

Every scenario verifies:
- A `pom.xml` uses `alfresco-sdk-aggregator` as parent (SDK 4.15.0)
- `module.properties` exists with `module.id` and `module.version`
- `module-context.xml` exists and imports at least one sub-context

Additional checks per scenario:

| Scenario | Commands | Extra checks |
|----------|----------|-------------|
| maven-sdk-baseline | `/scaffold` | Common checks only |
| content-types | `/scaffold` `/content-model` | `content-model.xml` well-formed, no `enforced="true"`, `*Model.java` uses `QName.createQName()`, `bootstrap-context.xml` uses `dictionaryModelBootstrap` |
| actions | `/scaffold` `/content-model` `/actions` | + `*ActionExecuter.java` extends `ActionExecuterAbstractBase`, `service-context.xml` has `action-executer` bean |
| behaviours | `/scaffold` `/content-model` `/behaviours` | + `*Behaviour.java` implements `*Policy`, uses `PolicyComponent` + `JavaBehaviour`, no `LANGUAGE_LUCENE` |
| web-scripts | `/scaffold` `/content-model` `/web-scripts` | + all `*.desc.xml` have `<authentication>`, `<format>`, `<transaction>`, `<cache>`, URL starts with `/api/`, `*.json.ftl` exists, `webscript-context.xml` exists |
| workflows | `/scaffold` `/content-model` `/workflow` | + `*.bpmn` well-formed with `xmlns:activiti`, `isExecutable="true"`, no `org.flowable`, no `redeploy=true`; `*-workflow-model.xml` imports `bpm`; `bootstrap-context.xml` uses `workflowDeployer`; `*Workflow.properties` exists |
| scheduled-jobs | `/scaffold` `/content-model` `/scheduled-jobs` | + `*Job.java` extends `AbstractScheduledLockedJob`, `*JobExecuter.java` uses `RetryingTransactionHelper`, `scheduler-context.xml` has `CronTriggerBean`/`schedulerFactory`/cron/enabled/startDelay, unit test mocks `RetryingTransactionHelper` |
| bootstrap-loader | `/scaffold` `/bootstrap-loader` | + `*BootstrapLoader.java` extends `AbstractModuleComponent`, `bootstrap-context.xml` uses `module.baseComponent` with `moduleId`/`sinceVersion`/`appliesFromVersion`, unit test mocks `NodeLocatorService` |
| rule-conditions | `/scaffold` `/content-model` `/rule-conditions` | + `*Condition.java` extends `ActionConditionEvaluatorAbstractBase`, overrides `evaluateImpl()`, declares `NAME` constant; `service-context.xml` uses `action-condition-evaluator`; unit test mocks `ActionCondition` |
| repository-patch | `/scaffold` `/content-model` `/repository-patch` | + `*Patch.java` extends `AbstractPatch`, overrides `applyInternal()`, closes `ResultSet`, no `LANGUAGE_LUCENE`; `patch-context.xml` uses `basePatch` with schema version properties |
| transforms | `/scaffold` `/transforms` | + `rendition-context.xml` uses `RenditionDefinition2Impl`/`renditionDefinitionRegistry2`; `mimetypes-extension-map.xml` in Alfresco config format; custom engine has `TransformEngine`, `CustomTransformer`, `*engine_config.json`, `Dockerfile` |
| aca-extension | `/aca-extension` | + `*.plugin.json` has routes/navbar/toolbar/contextMenu/sidebar; `*.module.ts` has `provideExtensionConfig`/`APP_INITIALIZER`/`setComponents`/`provideEffects`; service uses `AppConfigService`; components are `standalone: true` |

## Dependencies

`bash`, `xmllint` (pre-installed on macOS), `grep` — no Docker, no Maven, no network.
