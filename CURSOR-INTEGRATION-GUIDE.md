# Guia: integrar o AIUP Alfresco (Cursor) em um projeto Alfresco existente

Este guia descreve como configurar do zero a máquina de um desenvolvedor e integrar o pacote **aiup-alfresco** a um projeto Alfresco já existente (ex.: **project-repo**) no **Cursor**.

**Público-alvo:** desenvolvedor que nunca usou AIUP, Cursor skills ou o repositório `aiup-alfresco`.

---

## Visão geral

O **aiup-alfresco** não é um plugin instalável com um único comando no Cursor. É um **pacote de especificações** (regras, skills, comandos e scripts) que orienta o agente de IA a gerar e revisar código Alfresco seguindo um workflow estruturado.

No seu projeto existente, a integração consiste em:

1. Instalar ferramentas na máquina
2. Obter o repositório `aiup-alfresco`
3. Copiar ou referenciar os artefatos necessários dentro do projeto Alfresco
4. Adaptar versões do Alfresco ao seu `pom.xml`
5. Abrir o projeto no Cursor e validar que tudo funciona

---

## Parte 1 — Pré-requisitos na máquina

### 1.1 Instalar software base

| Ferramenta | Versão mínima | Para quê |
|------------|---------------|----------|
| **Git** | qualquer recente | clonar repositórios |
| **Java JDK** | 17+ | build Maven do Alfresco |
| **Maven** | 3.9+ | compilar o módulo |
| **Docker** + **Docker Compose** | v2 | subir ACS localmente (opcional, mas recomendado) |
| **Cursor** | build recente | IDE com Agent, Rules e Skills |
| **jq** | qualquer | hooks automáticos (opcional, mas recomendado) |

**Linux (Ubuntu/Debian) — exemplo:**

```bash
sudo apt update
sudo apt install -y git openjdk-17-jdk maven docker.io docker-compose-v2 jq
sudo usermod -aG docker "$USER"   # logout/login depois disso
```

**Verificar instalação:**

```bash
git --version
java -version      # deve mostrar 17 ou superior
mvn -version       # Maven 3.9+
docker --version
docker compose version
jq --version
```

### 1.2 Instalar o Cursor

1. Baixe em [https://cursor.com](https://cursor.com)
2. Instale e abra o aplicativo
3. Em **Settings**, confirme que estão habilitados:
   - **Rules** (regras de projeto)
   - **Agent** (chat com agente)
   - **Hooks** (opcional, mas útil)

---

## Parte 2 — Obter o aiup-alfresco

Você precisa do repositório com o pacote Cursor já adaptado (branch `main` com `.cursor/`, `CURSOR.md`, etc.).

### Opção A — Clone local (recomendado para começar)

```bash
mkdir -p ~/Projetos/opensource/aborroy
git clone https://github.com/aborroy/aiup-alfresco.git ~/Projetos/opensource/aborroy/aiup-alfresco
```

Se você usa um fork local (com as adaptações Cursor), clone o seu fork:

```bash
git clone <URL-do-seu-fork>/aiup-alfresco.git ~/Projetos/opensource/aborroy/aiup-alfresco
```

### Opção B — Submodule dentro do projeto Alfresco (recomendado para equipe)

No root do projeto Alfresco (ex.: `project-repo`):

```bash
cd /caminho/para/project-repo
git submodule add https://github.com/aborroy/aiup-alfresco.git tools/aiup-alfresco
git submodule update --init --recursive
```

---

## Parte 3 — Integrar ao projeto existente (ex.: project-repo)

Suponha esta estrutura do projeto:

```
project-repo/
├── pom.xml
├── src/main/java/...
├── src/main/resources/alfresco/module/project-repo/...
└── README.md
```

### 3.1 Decidir a estratégia de integração

| Estratégia | Vantagem | Desvantagem |
|------------|----------|-------------|
| **Submodule** (`tools/aiup-alfresco/`) | fácil atualizar; não duplica conteúdo | exige `git submodule update` |
| **Cópia pontual** | simples; sem submodule | difícil sincronizar com upstream |

Para equipe, prefira **submodule**.

### 3.2 Instalar o pacote Cursor no root do projeto

Com submodule em `tools/aiup-alfresco/`, execute **uma vez** (e após cada `git submodule update`):

```bash
cd /caminho/para/project-repo
./tools/aiup-alfresco/scripts/install-cursor-pack.sh
```

O script:

- Instala `.cursor/rules/aiup-alfresco.mdc` e hooks (se ainda não existirem)
- Gera skills de slash command em `.cursor/skills/` com paths apontando para `tools/aiup-alfresco/`
- Preserva skills customizadas já presentes em `.cursor/skills/` (`--merge`)

**Scripts portáteis (opcional):**

```bash
mkdir -p scripts/aiup
cp tools/aiup-alfresco/scripts/aiup-command.sh scripts/aiup/
chmod +x scripts/aiup/*.sh
```

> **Importante:** skills dentro de `tools/aiup-alfresco/.cursor/skills/` **não** aparecem no autocomplete do Agent quando o workspace é `project-repo/`. O `install-cursor-pack.sh` coloca as skills na raiz do projeto consumidor.

### 3.3 Estrutura final esperada no project-repo

```
project-repo/
├── .cursor/
│   ├── rules/aiup-alfresco.mdc      # regra do projeto
│   ├── skills/                       # slash commands + validadores + agentes (gerados por install-cursor-pack.sh)
│   ├── hooks.json                    # automação opcional
│   └── hooks/*.sh
├── tools/
│   └── aiup-alfresco/                # submodule (fonte da verdade)
│       ├── AGENTS.md
│       ├── commands/
│       ├── skills/
│       ├── agents/
│       └── scripts/
├── scripts/aiup/                     # atalhos (opcional)
│   └── aiup-command.sh
├── pom.xml
└── src/...
```

### 3.4 Adaptar versões do Alfresco (obrigatório em projeto existente)

O `AGENTS.md` do aiup-alfresco assume **ACS 26.1** e **SDK 4.15.0**. O **project-repo** usa:

- ACS **23.4.1**
- SDK **4.10.0**

Crie uma regra local que sobrescreve as versões, para o agente não gerar código incompatível.

Crie o arquivo `.cursor/rules/project-alfresco-versions.mdc`:

```markdown
---
description: Versões Alfresco do projeto project-repo — prevalecem sobre AGENTS.md do aiup-alfresco
alwaysApply: true
---

# Stack do project-repo

Ao gerar ou revisar código neste repositório, use **estas** versões (não as do AGENTS.md genérico):

| Componente | Versão |
|------------|--------|
| Alfresco Content Services | 23.4.1 (Community) |
| Alfresco Share | 23.4.0.46 |
| Maven In-Process SDK | 4.10.0 (`alfresco-sdk-aggregator`) |
| Java | 17 |
| Módulo | `project-repo` (`br.com.dgcloud`) |
| Namespace do model | `project` |

Leia `pom.xml` e os arquivos em `src/main/resources/alfresco/module/project-repo/` antes de propor alterações.
Não atualize versões do SDK/ACS sem solicitação explícita do usuário.
```

> **Nota:** substitua os valores acima pelos do seu `pom.xml` se o projeto tiver versões diferentes.

### 3.5 Slash commands no Agent

Após `install-cursor-pack.sh`, no chat do Cursor (modo **Agent**), digite:

```
/requirements Precisamos gerenciar contratos com datas de revisão
/scaffold
/content-model
```

O autocomplete lista todos os comandos AIUP (`/requirements`, `/scaffold`, `/rest-api`, …). Cada skill aponta para `tools/aiup-alfresco/commands/<name>.md`.

### 3.6 Versionar no Git

Adicione ao repositório (não commite `skills-lock.json` nem `.agents/`):

```bash
git add .cursor/ tools/aiup-alfresco .gitmodules   # se submodule
git add .cursor/rules/project-alfresco-versions.mdc
git status   # revisar antes do commit
```

---

## Parte 4 — Configurar o Cursor

### 4.1 Abrir o workspace correto

1. No Cursor: **File → Open Folder**
2. Selecione a pasta **`project-repo`** (root do projeto), não a pasta `aiup-alfresco` isolada
3. O Agent precisa ver `pom.xml`, `src/` e `.cursor/` no mesmo workspace

### 4.2 Confirmar que Rules e Skills carregaram

1. Abra **Settings → Rules**
2. Verifique se aparecem:
   - `aiup-alfresco`
   - regra de versões local (ex.: `project-alfresco-versions`)
3. Em **Agent**, digite `/` — deve listar `/requirements`, `/scaffold`, `content-model-validator`, etc.

### 4.3 Habilitar Hooks (opcional)

1. **Settings → Hooks** → habilitar
2. Reinicie o Cursor (**Developer: Reload Window**)
3. Confirme que existe `.cursor/hooks.json` na raiz do projeto Alfresco

---

## Parte 5 — Validar a instalação

### 5.1 Teste 1 — listar comandos

```bash
cd /caminho/para/project-repo
./tools/aiup-alfresco/scripts/aiup-command.sh list
```

Deve listar todos os comandos (`requirements`, `scaffold`, `content-model`, `rest-api`, `permissions`, `audit`, …).

### 5.2 Teste 2 — renderizar prompt Cursor

```bash
./tools/aiup-alfresco/scripts/aiup-command.sh render --agent cursor content-model
```

Copie a saída e cole no Agent do Cursor. O agente deve ler `AGENTS.md` e `commands/content-model.md`.

### 5.3 Teste 3 — prompt manual no Agent

No chat do Cursor (modo **Agent**), envie:

```
Siga @.cursor/rules/project-alfresco-versions.mdc e @tools/aiup-alfresco/AGENTS.md.
Analise o content model existente em @src/main/resources/alfresco/module/project-repo/model/content-model.xml
e liste possíveis melhorias sem alterar arquivos ainda.
```

Se o agente ler os arquivos corretos e respeitar as versões do seu `pom.xml`, a integração está funcionando.

### 5.4 Teste 4 — slash command

No Agent, digite:

```
/scaffold
```

O agente deve ler `tools/aiup-alfresco/AGENTS.md` e seguir `tools/aiup-alfresco/commands/scaffold.md`.

### 5.5 Teste 5 — skill de validação

```
Valide o content model usando a skill content-model-validator em
@src/main/resources/alfresco/module/project-repo/model/content-model.xml
```

---

## Parte 6 — Como usar no dia a dia (projeto existente)

Em projeto **já scaffolded**, você normalmente **não** roda `scaffold` de novo. O fluxo típico é:

| Situação | Comando AIUP / ação |
|----------|---------------------|
| Nova funcionalidade | `requirements` → depois o comando específico |
| Novo tipo/aspecto no model | `content-model` |
| Novo web script | `web-scripts` |
| Novo behaviour | `behaviours` |
| Nova action | `actions` |
| Workflow BPMN | `workflow` |
| Job agendado | `scheduled-jobs` |
| Debug após `mvn` falhar | skill `alfresco-debugger-agent` |
| Revisar APIs antigas | skill `migration-advisor` |

### Exemplo — adicionar um aspecto ao model

1. No terminal:

```bash
./tools/aiup-alfresco/scripts/aiup-command.sh render --agent cursor content-model \
  "Adicionar aspecto project:revisaoExterna com propriedades de data e responsável"
```

2. Cole o prompt no Agent
3. Revise o diff antes de commitar
4. Valide com `mvn clean package`

### Exemplo — iteração rápida com @

```
Execute o comando content-model do AIUP conforme
@tools/aiup-alfresco/commands/content-model.md.
Respeite @.cursor/rules/project-alfresco-versions.mdc e o model existente em
@src/main/resources/alfresco/module/project-repo/model/content-model.xml.
```

---

## Parte 7 — Manutenção e atualizações

### 7.1 Atualizar o aiup-alfresco (submodule)

```bash
cd /caminho/para/project-repo
git submodule update --remote tools/aiup-alfresco
./tools/aiup-alfresco/scripts/install-cursor-pack.sh
# Reaplicar ajustes locais em .cursor/rules/ se necessário
```

### 7.2 Após cada merge do upstream

Sempre rode `install-cursor-pack.sh` para sincronizar slash commands e o orquestrador `aiup-alfresco` com novos comandos.

### 7.3 O que não fazer

- Não abra só a pasta `aiup-alfresco` se o objetivo é desenvolver o projeto Alfresco
- Não copie o `AGENTS.md` inteiro para a raiz sem adaptar versões
- Não dependa de skills só dentro do submodule — use `install-cursor-pack.sh` para slash commands na raiz
- Não atualize ACS/SDK para 26.1 só porque o aiup-alfresco usa essa versão por padrão

---

## Parte 8 — Troubleshooting

| Problema | Solução |
|----------|---------|
| Agent ignora convenções Alfresco | Verificar Rules habilitadas; usar `@tools/aiup-alfresco/AGENTS.md` explicitamente |
| `/scaffold` não aparece | Cursor 2.4+; rodar `install-cursor-pack.sh`; skills em `.cursor/skills/` na **raiz** do workspace; recarregar Cursor |
| `unsupported agent 'cursor'` | Atualizar `aiup-command.sh` do submodule |
| Hooks não disparam | `chmod +x .cursor/hooks/*.sh`; habilitar Hooks nas settings; reiniciar Cursor |
| `jq: command not found` | `sudo apt install jq` ou desabilitar hooks em `.cursor/hooks.json` |
| Código gerado para ACS 26.1 | Reforçar a regra de versões local no prompt |
| Orchestrador sem comandos novos | Rodar `install-cursor-pack.sh` após atualizar submodule |

---

## Checklist final

```
[ ] Git, Java 17, Maven 3.9+, Docker, jq instalados
[ ] Cursor instalado com Rules, Agent e (opcional) Hooks habilitados
[ ] aiup-alfresco clonado ou adicionado como submodule em tools/aiup-alfresco/
[ ] install-cursor-pack.sh executado na raiz do projeto Alfresco
[ ] Regra de versões local criada (.cursor/rules/<projeto>-alfresco-versions.mdc)
[ ] Projeto aberto no Cursor pela pasta raiz
[ ] aiup-command.sh list retorna todos os comandos AIUP
[ ] /scaffold ou /requirements aparece no autocomplete do Agent
[ ] Teste no Agent com @AGENTS.md e content-model.xml funcionou
[ ] Alterações commitadas no Git (.cursor/, submodule, regra de versões)
```

---

## Referências

- Uso no Cursor (neste repositório): [CURSOR.md](./CURSOR.md)
- Portabilidade para outros agentes: [PORTABILITY.md](./PORTABILITY.md)
- Repositório upstream: [github.com/aborroy/aiup-alfresco](https://github.com/aborroy/aiup-alfresco)
