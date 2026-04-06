# 03. coding harness benchmark 설계

## 장 요약

coding harness를 비교할 때 모델 스펙만 보면 거의 항상 중요한 차이를 놓친다. 실제 현장에서는 context discipline, permission policy, continuity artifact, operator legibility, observability, reproducibility, economics가 함께 결과를 바꾼다. 이 장은 Claude Code를 기준 사례로 삼아, 새로운 coding harness를 비교할 때 최소한 어떤 차원을 같이 측정해야 하는지 정리한다.

## 범위와 비범위

이 장이 다루는 것:

- coding harness benchmark의 핵심 차원 선정
- 각 차원에 대해 어떤 evidence를 수집해야 하는지
- deterministic replay와 feature configuration control을 benchmark 설계에 포함해야 하는 이유
- thin wrapper와 long-running coding harness를 비교하는 최소 절차

이 장이 다루지 않는 것:

- 특정 오픈 benchmark dataset의 채점 스크립트 전체
- statistical significance 계산과 experiment platform 운영 전부
- 기업별 privacy/compliance rule의 조직 운영 세부

이 장은 [01-model-evals-vs-harness-evals.md](./01-model-evals-vs-harness-evals.md), [02-tasks-trials-transcripts-and-graders.md](./02-tasks-trials-transcripts-and-graders.md), [04-production-traces-feedback-loops-and-optimization.md](./04-production-traces-feedback-loops-and-optimization.md)를 전제로 한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/query.ts`
- `src/query/tokenBudget.ts`
- `src/utils/permissions/permissions.ts`
- `src/Task.ts`
- `src/utils/sessionStorage.ts`
- `src/utils/sessionRestore.ts`
- `src/services/analytics/growthbook.ts`
- `src/services/vcr.ts`
- `src/screens/REPL.tsx`

외부 프레이밍:

- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), 2026-03-30

함께 읽으면 좋은 장:

- [../context/01-context-as-an-operational-resource.md](../context/01-context-as-an-operational-resource.md)
- [../execution/02-state-resumability-and-session-ownership.md](../execution/02-state-resumability-and-session-ownership.md)
- [../safety/04-safety-autonomy-benchmark.md](../safety/04-safety-autonomy-benchmark.md)
- [../17-end-to-end-scenarios.md](../17-end-to-end-scenarios.md)

## benchmark 차원을 다시 정리하라

| 차원 | Claude Code에서 볼 evidence | 이 차원이 필요한 이유 |
| --- | --- | --- |
| context discipline | `src/query.ts`, `src/query/tokenBudget.ts`, compaction path | 같은 모델이어도 context pressure 처리 방식이 결과를 바꾼다 |
| boundary management | `src/utils/permissions/permissions.ts`, sandbox-aware tool policy | capability가 있어도 실행 가능한지 여부가 달라진다 |
| continuity | task artifact, transcript, resume restore | 긴 작업과 interruption recovery를 측정해야 한다 |
| operator legibility | REPL transcript mode, permission prompts, summaries | 사람과 시스템의 공동 작업 품질을 본다 |
| observability | result packet, transcript, telemetry, diagnostics | failure analysis와 optimization이 가능해진다 |
| reproducibility | GrowthBook override, VCR fixture | 동일 조건 비교가 가능해야 benchmark가 drift하지 않는다 |
| economics | cost/usage/duration | 같은 성공이라도 production feasibility가 달라진다 |
| evaluator separation | separate QA persona, explicit criteria, contract artifact | self-grading leniency를 줄일 수 있는가 |

이 표를 보면 benchmark가 "기능 목록"이 아니라 failure surface 목록이라는 점이 분명해진다. 어떤 harness가 어느 축에서 약한지 알면, 같은 모델인데 왜 결과가 다른지도 더 빨리 설명할 수 있다.

## evaluator 분리와 contract explicitness도 측정하라

Anthropic의 2026-03-24 글이 추가해 주는 benchmark 차원은 두 가지다.

1. evaluator separation
   generator가 자기 산출물을 직접 승인하는가, 아니면 skeptical external evaluator가 있는가
2. contract explicitness
   각 chunk나 sprint가 무엇을 done으로 보는지, 어떤 behavior를 확인할지 미리 합의하는가

이 두 차원은 especially long-running coding harness에서 중요하다. 많은 시스템이 transcript와 cost는 남기지만, self-grading leniency와 verification ambiguity는 따로 측정하지 않는다. 그러나 실제 failure는 여기서 자주 생긴다.

## evaluator가 overhead인지 leverage인지 판정하라

evaluator는 무조건 좋은 것이 아니다. evaluator가 value인지 overhead인지는 현재 모델과 task 난도 경계에 따라 달라진다. 모델이 solo로도 안정적으로 넘는 작업이라면 evaluator는 비용과 latency만 늘릴 수 있다. 반대로 모델이 경계 근처에서 stub feature, shallow QA, premature approval을 보인다면 evaluator는 실제 lift를 줄 수 있다.

따라서 benchmark에서는 evaluator를 고정된 정답 구조로 보지 말고, 다음 질문으로 판정하는 편이 좋다.

- evaluator가 발견한 failure가 generator solo run에서는 반복되는가
- evaluator가 고친 문제 수가 추가 cost와 duration을 정당화하는가
- model upgrade 이후에도 같은 evaluator scaffold가 여전히 load-bearing한가

## context discipline과 boundary management는 항상 함께 봐야 한다

`src/query.ts`의 token budget continuation은 context discipline을 측정 가능한 구조로 만든다.

```ts
const decision = checkTokenBudget(
  budgetTracker!,
  toolUseContext.agentId,
  getCurrentTurnTokenBudget(),
  getTurnOutputTokens(),
)
```

반면 `src/utils/permissions/permissions.ts`는 같은 capability가 mode, rule, hook, classifier 아래서 ask/deny/allow로 어떻게 바뀌는지 드러낸다.

```ts
if (decisionReason.type === 'rule') {
  return `Permission rule '${ruleString}' from ${sourceString} requires approval...`
}
...
appState.toolPermissionContext.mode === 'bypassPermissions'
```

이 두 축을 분리해서 봐야 하는 이유는 명확하다.

- context discipline이 좋아도 boundary management가 약하면 위험한 자동화가 생긴다.
- boundary management가 강해도 context discipline이 약하면 쓸데없이 많은 turn과 denial이 생긴다.

따라서 coding harness benchmark는 accuracy 차원만이 아니라 friction structure 차원을 함께 가져야 한다.

## reproducibility를 빼면 benchmark는 drift한다

long-running harness benchmark에서 흔한 실수는 transcript와 cost만 남기고, feature configuration과 fixture control을 빼는 것이다. Claude Code는 이 부분을 꽤 노골적으로 드러낸다.

- `GrowthBook` env override는 특정 feature configuration을 강제로 고정한다.
- `VCR`는 외부 API interaction을 fixture로 재생한다.

```ts
 * Useful for eval harnesses that need to test specific feature flag configurations.
```

```ts
if (env.isCI && !isEnvTruthy(process.env.VCR_RECORD)) {
  throw new Error(`Anthropic API fixture missing: ${filename}...`)
}
```

이런 surface가 없으면 trial variance가 모델 때문인지, runtime flag 때문인지, 외부 API drift 때문인지 구분하기 어려워진다.

## minimal scoring rule은 "존재"가 아니라 "설명 가능성"까지 봐야 한다

출판용 프레임에서는 각 차원을 0-3으로 간단히 볼 수 있다.

| 점수 | 의미 |
| --- | --- |
| 0 | 차원이 사실상 부재하거나 측정 불가 |
| 1 | 기능은 있으나 operator나 reviewer가 읽기 어렵다 |
| 2 | 기능과 artifact가 있으나 recovery/variance 설명이 약하다 |
| 3 | 기능, artifact, failure analysis, re-run control이 모두 드러난다 |

예를 들어:

- context discipline  
  `3`을 받으려면 budget/continuation/compaction이 같은 loop 안에서 설명 가능해야 한다.
- boundary management  
  `3`을 받으려면 allow/ask/deny가 rule, mode, classifier, hook 층위까지 드러나야 한다.
- reproducibility  
  `3`을 받으려면 feature config override와 replayable fixture가 모두 있어야 한다.

즉 benchmark는 "있다/없다"보다 "artifact와 설명이 있는가"를 더 많이 본다.

## benchmark 절차를 right-sized하게 설계하라

최소 절차는 다음 다섯 단계면 충분하다.

1. task family를 정한다.  
   예: 코드 수정, multi-file refactor, interrupted resume, high-permission action
2. 각 task를 여러 trial로 실행한다.  
   REPL과 SDK, permission mode 차이, flag 고정 여부를 포함한다.
3. transcript, outcome, cost/usage, diagnostics를 수집한다.
4. 위의 차원으로 채점하고 variance를 기록한다.
5. weakest dimension이 구조 문제인지 운영 문제인지 판정한다.

이 절차를 따르면 "누가 더 똑똑한가"보다 "누가 더 production coding harness에 가깝게 동작하는가"를 평가하게 된다.

## worked comparison: Claude Code vs thin wrapper

### Claude Code형 harness

- context discipline: query loop 안에서 budget/continuation/compaction이 드러난다
- boundary management: mode, rule, hook, classifier가 layered하다
- continuity: transcript, restore, task artifact가 있다
- reproducibility: GrowthBook override와 VCR이 있다
- observability: result packet, telemetry, diagnostics, transcript가 있다

### thin wrapper형 harness

- context discipline: one-shot prompt bundle 중심
- boundary management: coarse allowlist 정도만 있음
- continuity: interruption 이후 artifact가 거의 없음
- reproducibility: feature flag drift와 external dependency drift를 막기 어렵다
- observability: 마지막 output 외에는 평가 자료가 빈약하다

이 비교에서 드러나는 것은 "기능이 많다"가 아니다. load-bearing axis의 수와 품질이 다르다는 것이다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 context, boundary, continuity, observability, reproducibility를 개별 코드 surface로 드러낸다.
- coding harness benchmark는 accuracy 하나로 환원되지 않는다.
- replay와 flag control은 production benchmark에서 필수다.

원칙:

- coding harness benchmark는 failure surface 중심으로 설계해야 한다.
- 각 차원은 artifact와 explanation을 함께 요구해야 한다.
- variance가 큰 harness는 평균 점수보다 recovery와 reproducibility를 먼저 본다.
- evaluator separation과 contract explicitness도 benchmark 차원으로 기록하는 편이 낫다.

해석:

- Anthropic의 eval framing과 Meta-Harness의 최적화 관점은 Claude Code에서 구조 차원 benchmark로 만난다.
- coding harness를 제품으로 보려면 context, policy, continuity, economics가 같은 표 안에 올라와야 한다.

권고:

- 새 harness를 비교할 때는 최소 6개 이상 차원을 함께 보되, 그중 하나는 반드시 reproducibility로 두어라.
- point estimate보다 variance와 failure signature를 함께 기록하라.
- 약한 차원을 찾았으면 먼저 그 차원이 모델 문제인지 harness 구조 문제인지 분리해라.
- evaluator를 붙였다면, 그 evaluator가 overhead인지 leverage인지 별도 열로 적어라.

## benchmark 질문

1. 이 benchmark는 accuracy 외의 load-bearing axis를 충분히 포함하는가.
2. 각 axis에 대해 실제 artifact를 수집할 수 있는가.
3. replay/flag override 없이도 동일 조건 비교가 가능하다고 말할 수 있는가.
4. weakest dimension을 보고 바로 구조 개선 행동으로 연결할 수 있는가.

## 요약

coding harness benchmark는 모델 비교표가 아니라 구조 비교표에 가깝다. Claude Code는 context discipline, boundary management, continuity, observability, reproducibility, economics를 함께 보게 만드는 좋은 기준 사례다. 이 프레임을 쓰면 새 harness의 약점이 기능 부족인지 구조 부족인지 더 빨리 드러난다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/query.ts`와 `src/query/tokenBudget.ts`
   context discipline을 본다.
2. `src/utils/permissions/permissions.ts`
   boundary management 층위를 확인한다.
3. `src/Task.ts`, `src/utils/sessionStorage.ts`, `src/utils/sessionRestore.ts`
   continuity artifact를 본다.
4. `src/QueryEngine.ts`
   run-level outcome packet을 본다.
5. `src/services/analytics/growthbook.ts`와 `src/services/vcr.ts`
   reproducibility surface를 확인한다.
6. `src/screens/REPL.tsx`
   operator legibility와 feedback surface를 비교한다.
