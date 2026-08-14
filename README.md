# Diagnose System Performance

Skill portátil para investigar gargalos, regressões e incidentes de performance com um processo orientado por evidências. O mesmo conteúdo funciona em Claude Code, Codex e OpenCode.

## O que ela faz

A skill conduz a investigação pela cadeia:

`métrica degradada → comportamento observado → subsistema → hipótese → possível causa-raiz`

Ela cobre nove ramos: latência; CPU; memória e Garbage Collector; banco de dados; conexões e pools; erros e timeouts; disco e I/O; rede; filas e throughput.

O comportamento padrão é seguro: observar primeiro, separar diagnóstico de correção e pedir autorização antes de profiling invasivo, carga ou mudanças em produção.

## Estrutura

```text
performance-diagnostics-skill/
├── skills/diagnose-system-performance/
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   └── references/
│       ├── decision-tree.md
│       ├── investigation-method.md
│       └── response-template.md
└── scripts/
    └── install.sh
```

## Instalação pessoal

Instalar nas três ferramentas:

```bash
./scripts/install.sh --target all --scope user
```

Instalar apenas em uma delas:

```bash
./scripts/install.sh --target claude --scope user
./scripts/install.sh --target codex --scope user
./scripts/install.sh --target opencode --scope user
```

Os destinos usados são:

| Ferramenta | Instalação pessoal | Instalação no projeto |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Codex | `~/.agents/skills/` | `.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` | `.opencode/skills/` |

Se já existir uma skill com o mesmo nome, o instalador interrompe sem alterar nada. Use `--force` para mover a versão anterior para um backup datado e instalar a nova.

## Instalação em um projeto

```bash
./scripts/install.sh --target all --scope project --project-dir /caminho/do/repositorio
```

## Uso

Claude Code:

```text
/diagnose-system-performance Investigue por que o p99 aumentou após o último deploy.
```

Codex:

```text
$diagnose-system-performance Analise esta regressão de throughput usando as métricas disponíveis.
```

OpenCode pode selecionar a skill automaticamente pelo contexto. Também é possível pedir explicitamente:

```text
Use a skill diagnose-system-performance para investigar o crescimento contínuo de memória deste serviço.
```

## Exemplos de solicitações

- “O p50 está normal, mas o p99 triplicou. Investigue.”
- “A CPU média está em 35%, porém uma instância perdeu throughput.”
- “Depois do deploy, o pool de conexões fica esgotado em horário de pico.”
- “O consumer acumula lag mesmo com workers aparentemente ociosos.”
- “A RAM cresce continuamente; diferencie cache, leak e comportamento do allocator.”

## Atualização

Edite apenas a fonte em `skills/diagnose-system-performance/` e execute novamente o instalador com `--force`. Assim, o método e a árvore permanecem idênticos nas três ferramentas.

