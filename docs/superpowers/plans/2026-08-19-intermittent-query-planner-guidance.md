# Intermittent Query Planner Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensinar a skill a investigar o planner quando o mesmo query shape fica lento de forma intermitente e a tratar index hints apenas como mitigação temporária.

**Architecture:** A mudança fica isolada em uma nova subseção de `4.1 Queries individuais lentas` na árvore de decisão existente. Um cenário de recuperação de referência verifica se o agente distingue planejamento de execução, considera índices e colunas pesadas e limita a recomendação de index hints.

**Tech Stack:** Markdown, skill portátil para Claude Code, Codex e OpenCode.

## Global Constraints

- Preservar investigação orientada por evidências e separar diagnóstico de correção.
- Não concluir que excesso de índices ou colunas pesadas são a causa sem medição.
- Descrever index hint como mitigação paliativa, reversível e monitorada, não como solução padrão.
- Não criar commits sem solicitação explícita do usuário.

---

### Task 1: Adicionar e validar o ramo de planner intermitente

**Files:**
- Modify: `skills/diagnose-system-performance/references/decision-tree.md:132-148`

**Interfaces:**
- Consumes: ramo `4.1 Queries individuais lentas` e os princípios definidos em `skills/diagnose-system-performance/SKILL.md`.
- Produces: subseção `4.1.1 Mesmo query shape lento apenas em algumas execuções`.

- [ ] **Step 1: Executar o cenário sem a nova orientação**

Use um agente em contexto limpo, sem fornecer o texto novo, com o prompt:

```text
Uma consulta com o mesmo query shape normalmente leva 30 ms, mas algumas execuções levam 2 s. O tempo extra parece ocorrer antes da execução. A tabela tem muitos índices e uma coluna vector grande. Usando somente a skill diagnose-system-performance atual, produza uma investigação curta e diga se forçaria um índice.
```

Resultado esperado: a resposta não recupera de forma confiável todos estes requisitos: separar planner de execução; comparar execuções; avaliar excesso e relevância dos índices; verificar índice, leitura e projeção da coluna pesada; e restringir index hint a mitigação temporária.

- [ ] **Step 2: Adicionar a orientação mínima**

Inserir após a lista de causas de `4.1`:

```markdown
#### 4.1.1 Mesmo query shape lento apenas em algumas execuções

Se o mesmo query shape é lento de forma intermitente, compare execuções rápidas e lentas com parâmetros, cardinalidade, cache e concorrência equivalentes. Separe o tempo de planejamento ou otimização do tempo de execução e verifique se houve escolha ou replanejamento de planos diferentes.

Se o planner, otimizador ou componente equivalente estiver lento:

- avalie quantos índices candidatos ele considera e se há índices redundantes, sobrepostos, irrelevantes para o query shape ou pouco seletivos; reduza ou redesenhe índices somente depois de confirmar uso, redundância e impacto;
- verifique estatísticas, distribuição dos dados e diferenças entre estimativas e cardinalidade real;
- procure colunas pesadas, como vetores, arquivos, binários, BLOBs ou documentos grandes, e confirme se entram em algum índice, na leitura de linhas/documentos candidatos ou no resultado por falta de projeção; mantenha essas colunas fora do caminho crítico quando não forem necessárias.

Alguns bancos permitem limitar a escolha do planner com um index hint ou mecanismo equivalente; MongoDB é um exemplo. Considere isso apenas como mitigação temporária, paliativa, reversível e monitorada para os query shapes afetados: reduzir os planos candidatos pode evitar planejamento lento, mas forçar um índice remove parte da capacidade do banco de se adaptar a mudanças de dados e workload. Prefira corrigir índices, estatísticas, projeção e modelagem que causam a instabilidade.
```

- [ ] **Step 3: Reexecutar o cenário com a skill atualizada**

Execute o mesmo prompt em contexto limpo, agora disponibilizando a skill atualizada.

Resultado esperado: a resposta cobre os cinco pontos diagnósticos, não recomenda remover índices sem evidência e apresenta index hint apenas como mitigação temporária com monitoramento e risco explícitos.

- [ ] **Step 4: Verificar estrutura e diff**

Run: `git diff --check && git diff -- skills/diagnose-system-performance/references/decision-tree.md`

Expected: `git diff --check` sem saída; o diff contém somente a nova subseção no ramo `4.1`.
