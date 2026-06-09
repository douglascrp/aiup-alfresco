# validate-tutorials

Static validation harness that checks `aiup-alfresco` generates structurally correct
artefacts for each tutorial scenario.

## How it works

1. Each `scenarios/<scenario>/REQUIREMENTS.md` describes the extension to generate.
2. `generate-all.sh` generates all scenarios automatically using `claude -p`.
3. `run-all.sh` checks all populated scenarios; empty directories are reported as SKIP.

## Automated generation

```bash
# Generate all 12 scenarios and check them:
./generate-all.sh && ./run-all.sh

# Generate and check a single scenario:
./generate-all.sh content-types && ./run-scenario.sh content-types
```

## Running checks only

```bash
# All scenarios:
./run-all.sh

# Single scenario:
./run-scenario.sh content-types

# Custom generated directory:
./run-scenario.sh content-types /path/to/my/generated/project
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
