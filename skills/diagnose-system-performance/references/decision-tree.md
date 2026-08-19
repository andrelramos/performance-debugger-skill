# Árvore de decisão para problemas de performance

Use esta árvore como mapa, não como checklist rígido. Comece no sinal mais diretamente ligado ao impacto e atravesse para outros ramos quando houver evidência de interação.

## Roteamento inicial

| Sinal dominante | Ramo inicial | Primeira distinção |
|---|---|---|
| Respostas ou jobs lentos | Latência | p50 também piorou ou apenas p95/p99? |
| Processamento no limite | CPU | todos os cores ou apenas um? |
| RAM crescente ou pausas | Memória e Garbage Collector | retenção, alocação ou pressão externa? |
| Tempo concentrado em queries | Banco de dados | query lenta, volume, lock ou saturação? |
| Espera para adquirir recurso | Conexões e pools | falta de capacidade ou retenção anormal? |
| Falhas sob carga | Erros e timeouts | origem, orçamento e amplificação por retry? |
| I/O wait ou storage lento | Disco e I/O | IOPS, throughput, latência ou fila? |
| Chamadas remotas degradadas | Rede | RTT, perda, DNS, handshake ou round-trips? |
| Backlog ou vazão insuficiente | Filas e throughput | chegada supera serviço ou consumers degradaram? |

## 1. Latência

### 1.1 Delimitar

- Compare p50, p95, p99, máximo e taxa de timeout; média isolada esconde caudas.
- Segmente por operação, status, payload, tenant, instância, zona, versão e dependência.
- Decomponha tempo em fila, aplicação, banco, chamadas externas, serialização e rede.

### 1.2 Se p50, p95 e p99 pioraram juntos

Suspeite de degradação sistêmica ou caminho comum:

- CPU ou memória pressionadas em muitas instâncias;
- banco/dependência mais lento para a maioria das operações;
- aumento geral de payload, volume ou custo algorítmico;
- mudança de configuração, runtime, infraestrutura ou deploy;
- filas permanentes por capacidade insuficiente.

Medições decisivas: breakdown de tracing, tempo de serviço versus espera, perfil por versão e comparação com baseline de mesmo volume.

### 1.3 Se p50 estável, mas p95/p99 pioraram

Suspeite de comportamento esparso:

- contenção de locks ou pool;
- pausas do Garbage Collector;
- retries e hedging;
- partição, shard, host ou zona degradada;
- cache miss, cold start ou lazy initialization;
- payloads grandes e operações específicas;
- noisy neighbor ou throttling.

Medições decisivas: traces dos outliers, distribuição por instância/partição, aquisição de pools, pausas e número de tentativas.

### 1.4 Se a latência cresce com a demanda

- Verifique se a taxa de chegada se aproxima da taxa de serviço.
- Procure filas invisíveis: executor, thread pool, event loop, socket backlog, pool de conexão e banco.
- Compare concorrência útil com tempo bloqueado.
- Teste se o custo por operação também cresce; isso indica contenção, cache pior ou complexidade dependente do volume.

## 2. CPU

### 2.1 Todos os cores altos

Possíveis mecanismos:

- carga legítima acima da capacidade;
- algoritmo, parsing, compressão, criptografia ou serialização caros;
- retries, polling ou loops repetindo trabalho;
- Garbage Collector consumindo CPU por taxa alta de alocação;
- excesso de context switches ou threads executáveis;
- consultas/processamento movidos indevidamente para a aplicação.

Colete perfil de CPU por amostragem, taxa de requests, custo por operação, alocações, retries e run queue.

### 2.2 Um core alto com CPU agregada moderada

Suspeite de:

- event loop ou dispatcher saturado;
- lock global ou seção serial;
- partição única/hot key;
- afinidade incorreta;
- etapa single-threaded limitando pipeline paralelo.

Analise CPU por core/thread e throughput da etapa serial. CPU média da máquina pode mascarar esse gargalo.

### 2.3 CPU cresce mais rápido que o volume

Investigue complexidade não linear, tamanho médio dos dados, cache hit ratio, contenção, retries e trabalho duplicado. Normalize CPU por transação e por byte processado.

### 2.4 CPU alta sem throughput correspondente

Procure spin lock, busy wait, polling agressivo, retry storm, compressão inútil, logging excessivo, invalidação de cache ou Garbage Collector. Diferencie tempo de usuário, sistema, steal e iowait.

## 3. Memória e Garbage Collector

### 3.1 Memória cresce continuamente e não retorna

Distinga:

- retenção real de objetos/referências;
- cache sem limite ou cardinalidade inesperada;
- filas/backlogs guardados em memória;
- buffers, listeners, tasks ou conexões não liberados;
- memória nativa/off-heap versus heap gerenciado;
- fragmentação ou comportamento esperado do allocator.

Compare heap usado após coleta completa, RSS/working set, memória nativa, número de objetos por classe e dominadores entre snapshots.

### 3.2 Picos associados a uma operação

Verifique materialização de coleções, leitura integral de arquivos, descompressão, serialização duplicada, joins em memória e concorrência da operação. Meça bytes alocados e pico por operação, não só RAM global.

### 3.3 Garbage Collector frequente ou pausas longas

Pergunte:

- a taxa de alocação aumentou?
- o live set cresceu?
- heap está pequeno para o workload ou grande demais para a meta de pausa?
- há objetos grandes, promoção precoce ou fragmentação?
- CPU de GC substituiu trabalho útil?

Correlacione pausas e tempo de CPU do GC com p95/p99. Ajuste de heap/coletor é hipótese posterior; primeiro descubra por que alocação ou retenção mudou.

### 3.4 Swap, page faults ou pressão do host

Se heap parece saudável mas latência piora, verifique working set total, containers vizinhos, page faults major, swap, limites de cgroup e OOM kills. O problema pode estar fora do runtime.

## 4. Banco de dados

### 4.1 Queries individuais lentas

Inspecione plano real, linhas estimadas versus reais, índices, seletividade, join order, sorts, spills, scans e parâmetros. Compare tempo no servidor, aquisição de conexão e transferência de resultados.

Possíveis causas:

- índice ausente/inadequado ou não utilizado;
- mudança de plano ou parameter sensitivity;
- estatísticas desatualizadas;
- volume/cardinalidade maior;
- sort/hash spill por memória insuficiente;
- funções/conversões impedindo acesso eficiente;
- lock wait confundido com execução lenta.

#### 4.1.1 Mesmo query shape lento apenas em algumas execuções

Se o mesmo query shape é lento de forma intermitente, compare execuções rápidas e lentas com parâmetros, cardinalidade, cache e concorrência equivalentes. Separe o tempo de planejamento ou otimização do tempo de execução e verifique se houve escolha ou replanejamento de planos diferentes.

Se o planner, otimizador ou componente equivalente estiver lento:

- avalie quantos índices candidatos ele considera e se há índices redundantes, sobrepostos, irrelevantes para o query shape ou pouco seletivos; reduza ou redesenhe índices somente depois de confirmar uso, redundância e impacto;
- verifique estatísticas, distribuição dos dados e diferenças entre estimativas e cardinalidade real;
- procure colunas pesadas, como vetores, arquivos, binários, BLOBs ou documentos grandes, e confirme se entram em algum índice, na leitura de linhas/documentos candidatos ou no resultado por falta de projeção; mantenha essas colunas fora do caminho crítico quando não forem necessárias.

Alguns bancos permitem limitar a escolha do planner com um index hint ou mecanismo equivalente; MongoDB é um exemplo. Considere isso apenas como mitigação temporária, paliativa, reversível e monitorada para os query shapes afetados: reduzir os planos candidatos pode evitar planejamento lento, mas forçar um índice remove parte da capacidade do banco de se adaptar a mudanças de dados e workload. Prefira corrigir índices, estatísticas, projeção e modelagem que causam a instabilidade.

### 4.2 Muitas queries por operação

Procure N+1, lazy loading, chamadas duplicadas, chatty APIs, paginação implementada em memória e falta de batching. Meça queries por transação e round-trips, não apenas duração média de cada query.

### 4.3 Muitas linhas ou bytes lidos

Separe quantidade de linhas de quantidade de bytes. Uma linha pode ser pesada devido a BLOBs, arquivos, imagens, documentos, JSON grande, arrays, biometria, vetores ou embeddings.

Cadeia típica:

`colunas pesadas → mais leitura e transferência → mais desserialização e alocação → CPU/GC/rede maiores → latência e throughput piores`

Verifique projeção de colunas, filtros, paginação, acesso tardio ao conteúdo pesado, compressão e modelo de armazenamento. Evite `SELECT *` em caminhos críticos sem necessidade comprovada.

### 4.4 Locks e transações

Meça lock wait, blockers, deadlocks, duração e escopo das transações. Procure transações abertas durante chamadas externas, operações em lote grandes, ordem inconsistente de locks e isolamento mais forte que o necessário.

### 4.5 Banco saturado

Relacione CPU, I/O, buffer/cache hit, memória, sessões ativas, fila, replica lag e limites. Confirme se a saturação vem do workload investigado ou de vizinhos. Escalar capacidade pode aliviar, mas não comprova causa-raiz.

## 5. Conexões e pools

### 5.1 Tempo alto para adquirir conexão/recurso

Meça utilização, fila de espera, tempo de aquisição, timeouts, churn e duração de uso.

Hipóteses:

- pool pequeno para concorrência e tempo de retenção atuais;
- conexões não devolvidas ou streams não fechados;
- transações/queries lentas retendo o recurso;
- pool grande demais saturando o destino;
- criação de conexão cara por ausência de reuso;
- limites desalinhados entre aplicação, proxy e banco.

Não aumente o pool automaticamente. Pela relação aproximada `concorrência em uso ≈ taxa × tempo de retenção`, reduzir retenção pode ser mais seguro que ampliar conexões.

### 5.2 Muitas threads ou tarefas esperando

Identifique o recurso comum: conexão, lock, semaphore, socket, executor ou quota. Um thread pool maior pode apenas mover a fila e aumentar memória/context switches.

## 6. Erros e timeouts

### 6.1 Delimitar a origem

- Quem emitiu o timeout: cliente, proxy, aplicação, banco ou dependência?
- O orçamento diminui a cada hop ou cada camada reinicia um timeout completo?
- A operação continuou depois que o cliente desistiu?
- Há cancelamento propagado?

### 6.2 Verificar amplificação

Retries podem transformar uma degradação pequena em saturação. Meça tentativas por operação, backoff, jitter, requests duplicados, taxa de sucesso por tentativa e carga desperdiçada.

### 6.3 Padrões úteis

- erros apenas sob carga: capacidade, pool, quota ou fila;
- erros periódicos: renovação, rotação, coleta, batch ou autoscaling;
- timeouts com CPU baixa: bloqueio, dependência, pool, rede ou I/O;
- 5xx após aumento de latência: consequência provável, não necessariamente causa inicial.

## 7. Disco e I/O

### 7.1 Distinguir o limite

Observe latência, IOPS, throughput, tamanho das operações, profundidade de fila e iowait. Alto throughput não implica bom desempenho para I/O pequeno e aleatório; muitas IOPS também não explicam operações grandes sequenciais.

### 7.2 Hipóteses comuns

- logs síncronos ou verbose demais;
- fsync frequente;
- cache miss e leitura aleatória;
- spill de banco/sort para disco;
- compaction, backup ou snapshot concorrente;
- volume compartilhado/noisy neighbor;
- inode, espaço ou quota perto do limite;
- leitura/escrita de arquivos grandes no caminho síncrono.

Correlacione tempo de I/O da operação com fila do dispositivo e atividade de outros processos.

## 8. Rede

### 8.1 Separar componentes

Meça DNS, conexão TCP, TLS, time to first byte, transferência, RTT, perda, retransmissões e resets. Tracing de aplicação sem esses componentes pode atribuir rede ao serviço remoto.

### 8.2 Hipóteses comuns

- muitos round-trips pequenos;
- ausência de keep-alive ou reuso;
- handshake/DNS repetido;
- perda e retransmissões;
- caminho entre zonas/regiões;
- payload grande ou compressão inadequada;
- proxy, service mesh, NAT ou load balancer saturado;
- balanceamento desigual ou endpoint degradado.

Compare por origem, destino, zona, protocolo e versão. Evite concluir “rede” apenas porque a chamada externa aparece lenta.

## 9. Filas e throughput

### 9.1 Backlog crescente

Compare taxa de chegada, taxa de conclusão, concorrência efetiva, tempo de serviço e idade da mensagem mais antiga.

- chegada > serviço: capacidade sustentada insuficiente;
- serviço caiu: consumer, dependência, lock, erro ou mudança de custo;
- backlog concentrado: partição/hot key ou ordenação;
- muitas reentregas: falha, timeout, visibility window ou idempotência;
- lag alto com consumers ociosos: atribuição, polling, lease ou configuração.

### 9.2 Throughput baixo sem recurso saturado

Procure limite de concorrência, etapa serial, batch pequeno, espera externa, backpressure, rate limit, partições insuficientes ou coordenação excessiva.

### 9.3 Throughput alto com latência pior

Pode haver batching maior, fila deliberada ou troca entre vazão e tempo de resposta. Verifique se o comportamento respeita o SLO antes de tratá-lo como regressão.

## Interações que atravessam ramos

- Retry storm: timeout → retries → CPU/conexões/banco → mais timeout.
- Pool esgotado: query lenta → retenção de conexão → fila → p99 alto.
- Objetos/colunas pesadas: banco/rede → alocação → Garbage Collector → cauda de latência.
- Backlog: serviço lento → memória maior → GC/CPU → serviço ainda mais lento.
- Logging excessivo: erro/retry → disco e CPU → latência.
- Hot partition: distribuição desigual → core/shard/fila específicos saturados com médias globais normais.
