# Orientação para queries intermitentemente lentas

## Objetivo

Adicionar à árvore de diagnóstico uma orientação específica para o caso em que o mesmo shape de query apresenta lentidão apenas em algumas execuções. A orientação deve ajudar a distinguir tempo de planejamento de tempo de execução e transformar essa variação em hipóteses verificáveis.

## Localização

Criar uma subseção dentro de `4.1 Queries individuais lentas`, em `skills/diagnose-system-performance/references/decision-tree.md`. A proximidade mantém o novo caso no ramo em que o agente já inspeciona planos, índices, seletividade e mudanças de plano.

## Conteúdo

A subseção deve orientar o agente a:

1. comparar execuções rápidas e lentas do mesmo query shape, preservando parâmetros, cardinalidade, cache e concorrência como dimensões da análise;
2. medir separadamente o custo do planner ou componente equivalente e o custo da execução;
3. se o planejamento for lento, avaliar excesso de índices candidatos, índices redundantes ou pouco relevantes e estatísticas que dificultem a escolha;
4. verificar se colunas pesadas, como vetores, arquivos, binários, BLOBs ou documentos grandes, entram no índice, na leitura de linhas/documentos candidatos ou no resultado por falta de projeção;
5. considerar redução ou redesenho de índices somente após confirmar uso, redundância e impacto, evitando recomendar remoção sem evidência;
6. registrar que alguns bancos, como MongoDB, permitem usar um index hint para limitar a escolha do planner;
7. tratar o index hint como mitigação paliativa, reversível e monitorada, pois força um plano que pode deixar de ser adequado quando dados e workload mudarem.

## Segurança e validação

A mudança é apenas documental. Ela deve preservar o método orientado por evidências da skill, separar diagnóstico de correção e evitar a conclusão automática de que muitos índices ou uma coluna pesada são a causa. A validação deve confirmar que um agente consegue recuperar todos os pontos acima e não recomenda index hint como solução padrão.
