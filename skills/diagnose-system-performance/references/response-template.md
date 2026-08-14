# Estrutura da resposta de diagnóstico

Use o nível de detalhe proporcional ao problema. Não preencha campos com suposições apresentadas como fatos.

## Resumo executivo

- **Impacto:**
- **Sinal dominante:**
- **Estado do diagnóstico:** confirmado, provável ou inconclusivo
- **Hipótese principal:**
- **Próxima ação decisiva:**

## Evidências observadas

Liste somente fatos, com janela, unidade, segmento e fonte quando disponíveis.

| Evidência | Baseline | Janela degradada | Interpretação limitada |
|---|---:|---:|---|
| Exemplo: p99 do endpoint | 180 ms | 2,4 s | A cauda degradou |

## Decomposição

Mostre onde o tempo ou recurso está concentrado. Diferencie tempo de espera de tempo de serviço.

## Hipóteses ordenadas

Para cada hipótese:

1. **Mecanismo**
2. **Evidências favoráveis**
3. **Evidências contrárias ou ausentes**
4. **Medição/experimento discriminante**
5. **Risco da coleta**
6. **Confiança:** baixa, média ou alta

## Plano de investigação

Ordene por ganho de informação e segurança:

1. verificação read-only;
2. coleta/segmentação adicional;
3. reprodução controlada;
4. experimento reversível, se autorizado.

Inclua o resultado esperado para cada hipótese; “coletar mais logs” sem pergunta específica não é um passo suficiente.

## Causa-raiz e correção

Só use esta seção quando a evidência sustentar o mecanismo. Separe:

- causa-raiz;
- fatores contribuintes;
- correção imediata;
- correção estrutural;
- teste de regressão/performance;
- métricas de validação;
- condição de rollback.

## Lacunas e limites

Registre dados indisponíveis, suposições, possíveis vieses de amostragem e o que impediria uma conclusão mais forte.

