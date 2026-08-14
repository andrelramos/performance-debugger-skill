---
name: diagnose-system-performance
description: Diagnostica gargalos, regressões e incidentes de performance em sistemas a partir de evidências, usando uma árvore de decisão para latência, CPU, memória, Garbage Collector, banco de dados, conexões, erros, disco, rede e filas. Use quando houver lentidão, throughput baixo, saturação, timeouts, consumo anormal de recursos, degradação após deploy ou necessidade de investigar causa-raiz. Não use como justificativa para otimizações sem métricas ou para executar carga destrutiva sem autorização.
---

# Diagnosticar performance de sistemas

Conduza a investigação do sintoma até hipóteses testáveis. Responda no idioma do usuário e adapte comandos, métricas e exemplos à stack descoberta.

## Princípios obrigatórios

1. Comece pelas evidências, nunca por uma solução favorita.
2. Preserve a cadeia: métrica degradada → comportamento observado → subsistema → hipótese → possível causa-raiz.
3. Compare janela degradada, baseline saudável e mudanças de workload, configuração ou deploy.
4. Diferencie correlação, mecanismo causal e causa-raiz comprovada.
5. Mantenha diagnóstico e correção separados. Só implemente mudanças quando o usuário pedir.
6. Declare lacunas, suposições e nível de confiança. Não invente métricas ausentes.
7. Prefira verificações read-only. Antes de profiling invasivo, carga, restart, alteração em produção ou consulta cara, explique o risco e obtenha autorização.

## Carregar referências

- Leia sempre `references/investigation-method.md` antes de conduzir a investigação.
- Consulte `references/decision-tree.md` e carregue primeiro apenas os ramos compatíveis com o sinal dominante. Expanda para ramos vizinhos quando as evidências indicarem interação.
- Use `references/response-template.md` para estruturar a entrega e os checkpoints.

## Fluxo de trabalho

### 1. Enquadrar o problema

Registre impacto, serviço/operação, ambiente, janela temporal, baseline, percentis afetados, volume e mudanças recentes. Se faltarem dados essenciais, faça poucas perguntas de alto valor enquanto continua com verificações seguras disponíveis.

### 2. Confirmar e segmentar o sinal

Valide a métrica com uma segunda visão quando possível. Segmente por endpoint, operação, instância, zona, tenant, payload, status, versão e intervalo. Procure início abrupto, crescimento gradual, periodicidade e relação com demanda.

### 3. Escolher o ramo inicial

Classifique o sinal dominante entre latência, CPU, memória/GC, banco, conexões, erros/timeouts, disco/I/O, rede ou filas/throughput. Não trate a classificação como conclusão: recursos interagem e o ramo pode mudar.

### 4. Formular hipóteses concorrentes

Crie de duas a cinco hipóteses ordenadas. Para cada uma, declare mecanismo, evidência favorável, evidência contrária e a medição mais barata capaz de discriminá-la.

### 5. Instrumentar e testar

Use tracing, profiling, logs estruturados, métricas por recurso e planos de execução conforme o ramo. Prefira experimentos pequenos, reversíveis e isolados. Uma hipótese só avança quando produz uma previsão observável.

### 6. Concluir ou iterar

Marque cada hipótese como confirmada, enfraquecida ou inconclusiva. Se nenhuma explicar todas as evidências, volte ao último ponto comprovado e reclassifique o ramo; não force uma narrativa.

### 7. Recomendar a próxima ação

Ordene ações por redução de risco e ganho de informação. Quando houver causa-raiz sustentada, proponha correção, validação, teste de regressão e sinais de rollback, sem executar mudanças fora do escopo autorizado.

## Critério de conclusão

Considere o diagnóstico suficiente somente quando houver: sintoma reproduzido ou bem delimitado; mecanismo compatível com todas as evidências relevantes; hipótese principal distinguida das alternativas; e método de validação da correção. Se faltar algum item, entregue um diagnóstico parcial e o próximo passo decisivo.

