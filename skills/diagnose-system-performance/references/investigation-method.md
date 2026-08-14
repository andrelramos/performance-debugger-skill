# Método de investigação orientado por evidências

## 1. Definir o contrato do problema

Antes de procurar a causa, transforme “está lento” em uma afirmação mensurável:

- **Impacto:** quem ou o que foi afetado e com qual severidade?
- **Operação:** qual endpoint, job, consumer, query, fluxo ou tela?
- **Janela:** quando começou, quanto durou e ainda ocorre?
- **Baseline:** como o mesmo sinal se comporta em uma janela saudável comparável?
- **Demanda:** taxa de requisições, concorrência, tamanho de payload, cardinalidade e mix de operações.
- **Mudanças:** deploy, flag, configuração, índice, schema, infraestrutura, dependência, tráfego ou dados.
- **Objetivo:** SLO, orçamento de latência, throughput esperado ou limite de recurso.

Evite comparar períodos com workloads incompatíveis. Normalize por volume, operação e tamanho quando necessário.

## 2. Usar a cadeia de raciocínio

Mantenha cada conclusão rastreável:

1. **Métrica degradada:** p99, CPU, RSS, GC pause, lock wait, lag etc.
2. **Comportamento observado:** gradual, abrupto, periódico, por instância, por operação ou por carga.
3. **Subsistema envolvido:** aplicação, runtime, banco, pool, disco, rede, fila ou dependência.
4. **Hipótese:** mecanismo que prevê sinais verificáveis.
5. **Possível causa-raiz:** condição que originou o mecanismo e explica o início.

Exemplo: p99 subiu sem alterar p50 → apenas alguns requests esperam conexão → aquisição do pool concentra o tempo → hipótese de esgotamento do pool → possível causa-raiz: conexões retidas por transações longas após um deploy.

## 3. Correlacionar sem confundir com causalidade

Uma métrica alta durante o incidente é evidência de correlação. Para sustentar causalidade, procure pelo menos dois destes elementos:

- ordem temporal coerente;
- mecanismo técnico plausível;
- segmentação que acompanha o impacto;
- previsão confirmada por nova medição;
- reprodução controlada;
- melhora ao remover ou limitar o fator, com reversão segura.

Não conclua “CPU causou latência” apenas porque ambas subiram. CPU pode ser efeito de retries, serialização, GC ou aumento legítimo de demanda.

## 4. Decompor antes de otimizar

### Latência

Separe, quando possível:

`latência total = espera em fila + tempo de serviço + dependências + serialização + rede`

Compare p50, p95 e p99. Cauda degradada com mediana estável sugere contenção, outliers, pausas, retries ou partições específicas.

### Capacidade

Relacione taxa de chegada e taxa de serviço. Quando a chegada sustentada se aproxima ou supera a capacidade, pequenas variações criam filas e caudas longas.

### Recursos

Procure saturação, contenção e desperdício separadamente:

- **Saturação:** recurso próximo do limite útil.
- **Contenção:** trabalho bloqueado disputando um recurso.
- **Desperdício:** trabalho repetido ou desnecessário, como polling, retries e N+1.

## 5. Construir hipóteses discrimináveis

Use esta ficha por hipótese:

- **Hipótese:** uma frase causal e específica.
- **Explica:** quais observações ela cobre.
- **Prevê:** qual outro sinal deve existir se estiver correta.
- **Contradiz:** quais dados atuais a enfraquecem.
- **Medição decisiva:** menor coleta ou experimento que a diferencia das concorrentes.
- **Risco da coleta:** custo, overhead, privacidade e impacto operacional.

Priorize por `plausibilidade × impacto × facilidade de discriminação`, não apenas por familiaridade.

## 6. Selecionar instrumentos

Escolha o instrumento que responde à pergunta:

- **Métricas:** tendência, saturação, frequência e comparação temporal.
- **Tracing:** decomposição de uma operação e dependências críticas.
- **Profiling:** onde CPU, alocações, locks ou tempo de execução são consumidos.
- **Logs estruturados:** eventos discretos, erros, retries, cardinalidade e contexto.
- **Planos de execução:** caminho, estimativas, leituras, joins, sorts e spill de queries.
- **Dumps/snapshots:** retenção de memória, threads bloqueadas e estados raros.

Reduza cardinalidade e duração de coletas caras. Remova ou proteja dados sensíveis.

## 7. Experimentar com segurança

Prefira esta ordem:

1. observação read-only;
2. comparação histórica;
3. reprodução local ou staging;
4. canário com limite explícito;
5. alteração produtiva reversível.

Defina antes do experimento: hipótese, métrica de sucesso, limite de duração, condição de interrupção e rollback. Não execute carga em produção sem autorização explícita e capacidade confirmada.

## 8. Encerrar sem falsa certeza

Classifique o resultado:

- **Confirmado:** mecanismo e causa explicam as evidências e uma previsão foi validada.
- **Provável:** evidências convergem, mas falta uma validação decisiva.
- **Inconclusivo:** dados insuficientes ou hipóteses ainda indistinguíveis.
- **Refutado:** previsão incompatível com os dados.

Sempre preserve fatos observados separadamente de inferências.

