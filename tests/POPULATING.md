# Populating generated/ for validate-tutorials

> **You usually don't need this.** `./run-all.sh` validates the committed
> `scenarios/<scenario>/fixture/` trees fully offline (no `claude`, no network, no sibling
> repo). This document covers the **optional live-generation** path: regenerating artefacts
> from the actual slash commands via `claude -p` to confirm the generators still produce
> conformant output.

The harness ships with a fully automated script that generates all scenario artefacts
using `claude -p` (non-interactive mode) and then validates them.

---

## Fully automated: generate + check in one command

```bash
cd aiup-alfresco/tests/validate-tutorials

# Generate all 12 scenarios, then check them:
./generate-all.sh && ./run-all.sh
```

No interactive input needed. `generate-all.sh`:

1. For each scenario, cleans `generated/<scenario>/`, copies the matching
   `scenarios/<scenario>/REQUIREMENTS.md` into it.
2. Renders each required aiup slash command via `scripts/aiup-command.sh render`.
3. Pipes the rendered prompt into `claude -p --dangerously-skip-permissions`,
   which writes files directly into the generated directory.
4. Repeats for each command in sequence (scaffold → content-model → domain command).

`run-all.sh` then checks all 12 generated directories and prints a summary.

Expected final output:

```
Scenario                       Result
----------------------------------------------
maven-sdk-baseline             PASS
content-types                  PASS
actions                        PASS
behaviours                     PASS
web-scripts                    PASS
workflows                      PASS
scheduled-jobs                 PASS
bootstrap-loader               PASS
rule-conditions                PASS
repository-patch               PASS
transforms                     PASS
aca-extension                  PASS
----------------------------------------------
TOTAL                          PASS:12  FAIL:0  SKIP:0
```

---

## Generate a single scenario

```bash
./generate-all.sh content-types
# Validate the freshly generated output (not the committed fixture):
./run-scenario.sh content-types generated/content-types
```

---

## Requirements

- `claude` CLI in PATH (no `--plugin-dir` needed — `generate-all.sh` uses
  `scripts/aiup-command.sh render` which reads command specs directly from the
  repository, not from Claude Code's plugin system)

---

## What each scenario generates

| Scenario | Commands run | Key files checked |
|----------|-------------|-------------------|
| maven-sdk-baseline | `/scaffold` | `pom.xml` (sdk-aggregator), `module.properties`, `module-context.xml` |
| content-types | `/scaffold` `/content-model` | + `content-model.xml`, `*Model.java` (QName), `bootstrap-context.xml` (dictionaryModelBootstrap) |
| actions | `/scaffold` `/content-model` `/actions` | + `*ActionExecuter.java` (extends ActionExecuterAbstractBase), `service-context.xml` (action-executer) |
| behaviours | `/scaffold` `/content-model` `/behaviours` | + `*Behaviour.java` (Policy, PolicyComponent, JavaBehaviour, no LANGUAGE_LUCENE), `service-context.xml` |
| web-scripts | `/scaffold` `/content-model` `/web-scripts` | + `*.desc.xml` (auth, format, transaction, cache, /api/ URL), `*.json.ftl`, `webscript-context.xml` |
| workflows | `/scaffold` `/content-model` `/workflow` | + `*.bpmn` (activiti ns, isExecutable, no flowable/redeploy), `*-workflow-model.xml` (bpm import), `bootstrap-context.xml` (workflowDeployer), `*Workflow.properties` |
| scheduled-jobs | `/scaffold` `/content-model` `/scheduled-jobs` | + `*Job.java` (AbstractScheduledLockedJob), `*JobExecuter.java` (RetryingTransactionHelper), `scheduler-context.xml` (CronTriggerBean, cron, enabled, startDelay), unit test |
| bootstrap-loader | `/scaffold` `/bootstrap-loader` | + `*BootstrapLoader.java` (AbstractModuleComponent), `bootstrap-context.xml` (module.baseComponent, moduleId, sinceVersion), unit test |
| rule-conditions | `/scaffold` `/content-model` `/rule-conditions` | + `*Condition.java` (ActionConditionEvaluatorAbstractBase, evaluateImpl, NAME), `service-context.xml` (action-condition-evaluator), unit test |
| repository-patch | `/scaffold` `/content-model` `/repository-patch` | + `*Patch.java` (AbstractPatch, applyInternal, ResultSet.close), `patch-context.xml` (basePatch, schema version), unit test |
| transforms | `/scaffold` `/transforms` | + `rendition-context.xml` (RenditionDefinition2Impl), `mimetypes-extension-map.xml`; optional engine: `*Engine.java`, `*Transformer.java`, `*engine_config.json`, `Dockerfile` |
| aca-extension | `/aca-extension` | + `*.plugin.json` (routes/navbar/toolbar/contextMenu/sidebar), `*.module.ts` (provideExtension, APP_INITIALIZER, setComponents), `*.service.ts` (AppConfigService), standalone components, `public-api.ts` |

---

## Troubleshooting

**A scenario generates 0 files or Claude asks for input**
The `claude -p` invocation didn't find `REQUIREMENTS.md`. The script appends an explicit
path context to every prompt, but if Claude's model changes its behaviour, run the failing
scenario individually and check its `.prompt-*.txt` log:

```bash
./generate-all.sh content-types
# Inspect what was sent to claude:
cat generated/content-types/.prompt-scaffold.txt | head -20
```

**A scenario FAIL after generation**
The checker output shows exactly which file and pattern failed. Common cases:

- `FAIL: *.bpmn process definition file exists` — the `/workflow` command generated the
  model but not the BPMN. Re-run `./generate-all.sh workflows`; non-determinism in LLM
  output means a second run often produces the missing file.
- `FAIL: all descriptors use /api/ URL prefix` — `/web-scripts` generated `/someco/` URLs
  instead of `/api/sc/`. This is a gap in the command spec to fix in `commands/web-scripts.md`.
- `FAIL: bootstrap-context.xml uses workflowDeployer` — `/workflow` registered BPMN via
  `dictionaryModelBootstrap` (forbidden pattern). Re-run or fix `bootstrap-context.xml` manually.
- `FAIL: *Model.java uses two-arg QName.createQName()` — `/content-model` used the
  one-arg form. This is a gap in `commands/content-model.md` to fix.
