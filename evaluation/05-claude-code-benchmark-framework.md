# 05. Claude Code benchmark framework

## 장 요약

이 장은 앞선 evaluation 장과 원칙 장을 하나의 benchmark framework로 묶는다. 목적은 Claude Code를 찬양하거나 비난하는 것이 아니라, 새로운 coding harness를 비교할 때 어떤 질문을 먼저 던져야 하는지 고정하는 것이다. 이 framework는 단일 점수표가 아니라, 구조를 분해하고 evidence를 수집하며 weakest dimension을 찾게 해 주는 질문지다.

## 범위와 비범위

이 장이 다루는 것:

- Claude Code를 기준 사례로 한 benchmark axes
- 각 axis별로 어떤 evidence를 봐야 하는지
- 설명 가능성, 운영 가능성, 측정 가능성을 함께 보는 right-sized rubric

이 장이 다루지 않는 것:

- 하나의 절대 점수로 제품을 서열화하는 방식
- 특정 기업의 private KPI나 business objective
- benchmark runner implementation과 infra automation 전부

이 장은 책 전체의 synthesis 장이다. 본문에서 반복된 논의를 한 표로 접어 두고, 다른 하네스를 읽을 때 다시 꺼내 쓰게 만드는 데 목적이 있다.
따라서 아래 axis는 코드에 박힌 공식 taxonomy가 아니라 현재 공개 스냅샷을 읽기 위한 분석 프레임이며, 저장소 구조가 크게 바뀌면 함께 재검증해야 한다.

## 자료와 독서 기준

주요 reader-facing 근거:

- [../02-architecture-map.md](../02-architecture-map.md)
- [../05-context-assembly-and-query-pipeline.md](../05-context-assembly-and-query-pipeline.md)
- [../08-tool-system-and-permissions.md](../08-tool-system-and-permissions.md)
- [../12-task-model-and-background-execution.md](../12-task-model-and-background-execution.md)
- [../17-end-to-end-scenarios.md](../17-end-to-end-scenarios.md)
- [../context/](../context)
- [../execution/](../execution)
- [../safety/](../safety)

외부 프레이밍:

- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), 2026-03-30

## 대표 코드 발췌

이 장의 benchmark axis가 공허한 체크리스트가 아닌 이유는, 공개 사본이 실제로 비교 가능한 상태와 artifact를 들고 있기 때문이다.

```ts
constructor(config: QueryEngineConfig) {
  this.config = config
  this.mutableMessages = config.initialMessages ?? []
  this.abortController = config.abortController ?? createAbortController()
  this.permissionDenials = []
  this.readFileState = config.readFileCache
  this.totalUsage = EMPTY_USAGE
}
```

이 발췌는 `src/QueryEngine.ts`의 초기화 구간이다. message history, permission denial, usage 누적이 모두 runtime object에 붙어 있기 때문에, 이 장에서 말하는 `continuity`, `economics`, `evaluation readiness` 같은 축을 실제 artifact 기준으로 다시 읽을 수 있다.

## benchmark axes

| axis | Claude Code에서 볼 대표 evidence | 다른 harness에 던질 질문 |
| --- | --- | --- |
| runtime topology | entrypoint 분기, REPL/SDK/remote family | 어떤 owner와 deployment family가 존재하는가 |
| context discipline | snapshot, budget, compaction, continuation | context pressure를 어떻게 관리하는가 |
| boundary management | permission mode, sandbox, rule/classifier layering | capability와 permission을 어떻게 분리하는가 |
| continuity | task artifact, transcript, resume, restore | interruption 이후 일을 어떻게 이어 가는가 |
| operator control | REPL, command surface, approval prompts, transcript mode | 사람이 어디서 보고 개입하는가 |
| observability | result packet, transcript, API logging, spans, diagnostics | 무엇을 trace하고 어디서 병목을 볼 수 있는가 |
| reproducibility | flag override, VCR, config snapshot | benchmark 조건을 어떻게 고정하는가 |
| economics | cost, usage, duration, cache hit | 성공의 비용 구조를 어떻게 읽는가 |
| evaluation readiness | transcript/outcome/grader input 후보 | 실제 benchmark/eval loop에 넣을 수 있는가 |

이 표가 의미하는 것은 "Claude Code에 기능이 많다"가 아니다. production coding harness로서 load-bearing한 축이 무엇인지 드러난다는 뜻이다.

## 세 가지 판단 축: 설명 가능성, 운영 가능성, 측정 가능성

이 framework에서 각 axis는 세 질문으로 다시 읽는다.

1. 설명 가능한가  
   외부 독자나 팀원이 구조를 이해할 수 있는가
2. 운영 가능한가  
   failure와 recovery를 실제로 다룰 수 있는가
3. 측정 가능한가  
   transcript, outcome, grader input을 만들어 benchmark loop에 넣을 수 있는가

예를 들어 `continuity` axis를 보자.

- 설명 가능성: transcript와 restore path가 문서에 보이는가
- 운영 가능성: 실제로 interruption 이후 이어서 일할 수 있는가
- 측정 가능성: resumed trial과 non-resumed trial을 비교할 artifact가 남는가

이 세 질문을 함께 써야 benchmark가 reading guide이자 operational tool이 된다.

## right-sized rubric

| 등급 | 의미 |
| --- | --- |
| `부재` | axis가 사실상 구현되지 않았거나 설명조차 안 된다 |
| `국소적` | 기능은 있지만 특정 surface에만 있고 전체 run과 연결되지 않는다 |
| `운영 가능` | 기능과 artifact가 있고 failure/recovery를 설명할 수 있다 |
| `benchmark-ready` | 기능, artifact, re-run control, grader input까지 모두 갖췄다 |

이 rubric은 단순하지만 충분히 유용하다. production coding harness를 비교할 때는 평균 점수보다 "어느 axis가 `부재` 또는 `국소적`인가"를 먼저 보는 편이 낫다. weakest dimension이 전체 경험을 자주 결정하기 때문이다.

## 이 framework를 실제로 쓰는 순서

1. runtime topology를 먼저 본다.  
   owner와 deployment family가 무엇인지 정리한다.
2. context discipline과 boundary management를 본다.  
   capability가 어떻게 shaped되고 어디서 제한되는지 본다.
3. continuity와 operator control을 본다.  
   장기 실행과 human oversight가 구조적으로 가능한지 확인한다.
4. observability, reproducibility, economics를 본다.  
   비교 가능한 evidence가 있는지, drift를 막을 수 있는지, 비용 구조가 보이는지 확인한다.
5. 마지막으로 evaluation readiness를 본다.  
   앞선 axis들이 실제 benchmark loop로 이어질 수 있는지 확인한다.

이 순서는 곧 reading order이기도 하다. 그래서 이 장은 checklist이면서 책의 index 역할도 한다.

## worked application: 새 harness를 비교할 때

새로운 coding harness를 하나 본다고 가정해 보자.

### 질문 1. owner와 runtime family가 있는가

- CLI만 있는가, IDE/remote/headless path도 있는가
- family 차이가 artifact와 policy에 반영되는가

### 질문 2. context와 boundary가 함께 설계됐는가

- context pressure를 budget/compaction/continuation으로 다루는가
- permission이 allowlist 하나로 끝나지 않고 layered decision surface를 가지는가

### 질문 3. interruption과 recovery가 artifact로 남는가

- task, transcript, resume state가 있는가
- retry와 restore가 같은 semantics를 유지하는가

### 질문 4. trace와 cost가 benchmark input으로 재사용 가능한가

- transcript, result packet, usage/cost, timing span이 있는가
- feature config와 external dependency를 통제할 재현 surface가 있는가

### 질문 5. 사람의 판단을 넣을 자리가 있는가

- operator가 transcript와 prompts를 읽을 수 있는가
- feedback나 review signal을 구조적으로 수집할 수 있는가

이 다섯 질문을 통과하면, 그 하네스는 단지 "동작하는 데모"가 아니라 benchmark 가능한 시스템으로 읽힌다.

## 무엇을 절대 잊지 말아야 하는가

이 framework는 Claude Code를 정답 아키텍처로 선언하지 않는다. 오히려 반대로, Claude Code가 공개 사본만으로도 benchmark 질문을 많이 불러일으키는 사례라는 점이 중요하다. 다른 하네스가 이 질문에 더 좋은 답을 줄 수도 있고, 일부 축에서는 훨씬 단순한 구조가 더 낫기도 하다.

출판용 문서에서 중요한 것은 결론의 찬반보다 질문의 품질이다. 이 framework는 그 질문을 재사용 가능하게 만드는 장치다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 benchmark axis 대부분에 대해 실제 artifact를 노출한다.
- 가장 강한 점은 구조가 코드와 문서 양쪽에서 모두 읽힌다는 것이다.
- weakest axis를 찾기 쉽도록 질문지가 구성돼야 실제 개선 행동으로 이어진다.

원칙:

- benchmark framework는 점수표보다 질문지에 가까워야 한다.
- 각 axis는 설명 가능성, 운영 가능성, 측정 가능성을 함께 평가해야 한다.
- weakest dimension을 먼저 찾고, 그 dimension의 귀속점을 분리해야 한다.

해석:

- Anthropic의 eval framing과 Meta-Harness의 최적화 관점은 이 framework에서 실무형 질문지로 만난다.
- Claude Code는 그 질문지를 검증해 보는 기준 사례이지, 유일한 답이 아니다.

권고:

- 새로운 harness를 문서화할 때 이 장의 axis 표를 그대로 복사해 첫 페이지 checklist로 써 보라.
- 평균 점수 대신 `부재`와 `국소적` axis부터 고쳐라.
- benchmark-ready 여부를 판단할 때는 artifact와 re-run control이 실제로 있는지 먼저 확인하라.

## benchmark 질문

1. 이 framework로 다른 coding harness를 실제로 분해해 비교할 수 있는가.
2. 각 axis에 대해 artifact, 운영 규칙, 측정 입력을 모두 적을 수 있는가.
3. weakest dimension을 찾았을 때 바로 개선 행동으로 이어지는가.
4. Claude Code 사례를 기준점으로 삼되, 더 나은 대안 구조를 상상할 여지를 남기는가.

## 요약

Claude Code benchmark framework의 핵심은 단일 점수표가 아니라 구조적 질문지다. runtime topology에서 evaluation readiness까지 이어지는 축으로 시스템을 분해해 보면, 무엇이 load-bearing이고 어디가 weakest dimension인지 더 빨리 드러난다. 그때 비로소 benchmark는 비교가 아니라 설계 도구가 된다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/main.tsx`, `src/QueryEngine.ts`, `src/screens/REPL.tsx`
   runtime topology와 owner 분기를 먼저 본다.
2. `src/context.ts`, `src/query.ts`, `src/query/tokenBudget.ts`
   context discipline을 본다.
3. `src/utils/permissions/permissions.ts`
   boundary management를 확인한다.
4. `src/Task.ts`, `src/utils/sessionStorage.ts`, `src/utils/sessionRestore.ts`
   continuity를 본다.
5. `src/services/api/logging.ts`, `src/utils/telemetry/sessionTracing.ts`, `src/cost-tracker.ts`
   observability와 economics를 확인한다.
6. `src/services/analytics/growthbook.ts`, `src/services/vcr.ts`
   reproducibility control을 본다.
7. 다시 [01-model-evals-vs-harness-evals.md](./01-model-evals-vs-harness-evals.md)부터 [04-production-traces-feedback-loops-and-optimization.md](./04-production-traces-feedback-loops-and-optimization.md)까지 되돌아가, evaluation readiness를 최종 점검한다.
