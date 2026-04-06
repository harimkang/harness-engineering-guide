# 01. model eval과 harness eval

## 장 요약

모델 점수가 높다고 제품이 잘 작동하는 것은 아니다. model eval은 대체로 주어진 입력에 대한 모델의 잠재 능력을 재고, harness eval은 그 모델이 실제 runtime, tool surface, permissions, transcript, cost budget, operator control 안에서 어떤 행동을 내는지 잰다. Claude Code 사례는 이 차이를 추상적 구호가 아니라 run-level artifact의 차이로 보여 준다.

## 범위와 비범위

이 장이 다루는 것:

- model eval과 harness eval이 무엇을 각각 고정하고 무엇을 측정하는지
- Claude Code가 남기는 result packet, transcript, cost/usage, flag control이 왜 harness eval의 재료가 되는지
- determinism과 feature-flag control 자체가 harness evaluation concern인 이유

이 장이 다루지 않는 것:

- 구체적인 외부 benchmark suite의 구현법 전부
- 모델 자체의 학습 데이터, preference tuning, base capability 분석
- 평가 자동화 파이프라인의 CI wiring 세부

이 내용은 [03-benchmarking-coding-harnesses.md](./03-benchmarking-coding-harnesses.md), [04-production-traces-feedback-loops-and-optimization.md](./04-production-traces-feedback-loops-and-optimization.md), [../appendix/references.md](../appendix/references.md)에서 이어서 확장한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/QueryEngine.ts`
- `src/query.ts`
- `src/query/config.ts`
- `src/cost-tracker.ts`
- `src/services/api/logging.ts`
- `src/services/analytics/growthbook.ts`
- `src/services/vcr.ts`
- `src/hooks/useLogMessages.ts`

외부 프레이밍:

- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), 2026-03-30

함께 읽으면 좋은 장:

- [../context/01-context-as-an-operational-resource.md](../context/01-context-as-an-operational-resource.md)
- [../execution/03-task-orchestration-and-long-running-execution.md](../execution/03-task-orchestration-and-long-running-execution.md)
- [../safety/04-safety-autonomy-benchmark.md](../safety/04-safety-autonomy-benchmark.md)
- [../17-end-to-end-scenarios.md](../17-end-to-end-scenarios.md)

## 무엇을 고정하고 무엇을 측정하는가

| 구분 | 주로 고정하는 것 | 주로 측정하는 것 | 놓치기 쉬운 실패 |
| --- | --- | --- | --- |
| model eval | prompt format, reference answer, grader | 모델의 응답 품질 | tool surface, permissions, runtime latency, recovery |
| harness eval | 모델은 일부만 고정, runtime/owner/tool/policy 포함 | 실제 run의 성공, 비용, turn 수, denial, recovery, observability | base model capability 그 자체 |

이 구분이 중요한 이유는 실패의 귀속점이 달라지기 때문이다. 같은 모델이라도 tool permission 정책이 다르면 전혀 다른 제품 경험이 나오고, 같은 harness라도 모델이 바뀌면 output quality는 달라질 수 있다. 무엇을 탓할지 먼저 분리하지 않으면 평가 결과는 개선 행동으로 연결되지 않는다.

## Claude Code는 run-level outcome을 먼저 남긴다

`src/QueryEngine.ts`의 result packet은 모델 응답 텍스트만 반환하지 않는다. turn 수, API 소요 시간, 비용, usage, permission denial, fast mode state까지 함께 포함한다.

```ts
yield {
  type: 'result',
  subtype: 'success',
  is_error: false,
  duration_ms: Date.now() - startTime,
  duration_api_ms: getTotalAPIDuration(),
  num_turns: messages.length - 1,
  result: resultText ?? '',
  session_id: getSessionId(),
  total_cost_usd: getTotalCost(),
  usage: this.totalUsage,
  modelUsage: getModelUsage(),
  permission_denials: this.permissionDenials,
  ...
}
```

이 구조가 시사하는 바는 단순하다. Claude Code가 성능 단위로 취급하는 것은 "모델이 마지막에 무슨 문장을 냈는가"가 아니라 "한 번의 harnessed run 전체가 어떤 궤적과 비용으로 끝났는가"다.

이 점은 harness eval의 핵심과 맞닿는다.

- run마다 turn count가 다를 수 있다.
- permission denial은 capability 부족이 아니라 policy friction일 수 있다.
- `usage`와 `total_cost_usd`는 같은 답을 더 비싸게 내는 run을 구분하게 해 준다.

model eval만으로는 이 차이를 거의 잡아내지 못한다.

## transcript와 logging이 evaluation surface를 넓힌다

REPL path는 `useLogMessages()`를 통해 transcript를 append-only chain으로 기록한다. 이 hook은 매 render마다 full array를 다시 쓰지 않고, incrementally tail만 `recordTranscript()`에 넘기며 compaction과 rewind까지 고려한다.

```ts
// messages is append-only between compactions, so track where we left off
// and only pass the new tail to recordTranscript.
void recordTranscript(
  slice,
  ...,
  parentHint,
  messages,
)
```

이 transcript는 harness eval에서 세 가지 역할을 한다.

1. run을 나중에 재구성하는 raw evidence
2. human reviewer나 grader가 읽을 입력
3. compaction, resume, prompt suggestion 같은 scaffold change가 실제로 어떤 interaction shape를 만들었는지 확인하는 자료

즉 Claude Code에서 transcript는 UI scrollback이 아니라 evaluation surface의 일부다.

## determinism과 flag control도 harness eval concern이다

harness eval은 runtime control surface까지 포함해야 한다. `src/services/analytics/growthbook.ts`는 env-var override로 remote eval과 disk cache를 우회할 수 있게 해, 특정 feature configuration을 deterministic하게 고정한다.

```ts
/**
 * Set CLAUDE_INTERNAL_FC_OVERRIDES ... to bypass remote eval and disk cache.
 * Useful for eval harnesses that need to test specific feature flag configurations.
 */
```

`src/services/vcr.ts`는 테스트/강제 VCR 모드에서 fixture를 읽고 쓰며, CI에서는 fixture가 없으면 실패하게 만들어 replayability를 강제한다.

```ts
if (env.isCI && !isEnvTruthy(process.env.VCR_RECORD)) {
  throw new Error(
    `Anthropic API fixture missing: ${filename}. Re-run tests with VCR_RECORD=1, then commit the result.`,
  )
}
```

이 두 구조는 중요한 교훈을 준다. harness eval은 모델 출력만 측정하는 것이 아니라, 동일한 harness 조건을 반복 가능하게 만드는 control surface까지 설계해야 한다. feature flag가 매번 달라지거나 외부 호출이 fixture 없이 흔들리면 evaluation은 곧바로 drift한다.

## 비용과 usage는 부가 지표가 아니라 1차 outcome이다

`src/cost-tracker.ts`는 session별 cost state를 저장하고 resume 시 복원한다.

```ts
export function saveCurrentSessionCosts(...): void {
  saveCurrentProjectConfig(current => ({
    ...current,
    lastCost: getTotalCostUSD(),
    lastAPIDuration: getTotalAPIDuration(),
    ...
    lastSessionId: getSessionId(),
  }))
}
```

`src/services/api/logging.ts`는 API attempt 단위로 input/output/cache tokens, cost, duration, query source, permission mode, query chain metadata까지 남긴다.

```ts
{
  inputTokens: usage.input_tokens,
  outputTokens: usage.output_tokens,
  cachedInputTokens: usage.cache_read_input_tokens ?? 0,
  uncachedInputTokens: usage.cache_creation_input_tokens ?? 0,
  durationMs,
  costUSD,
  querySource,
  permissionMode,
  ...
}
```

이런 구조가 있으면 harness eval은 "맞았는가"만이 아니라 "얼마나 많은 turn과 비용과 friction으로 맞았는가"를 함께 묻게 된다. production coding harness에서는 이 두 번째 질문이 첫 번째만큼 중요하다.

## model eval을 대체하는 것이 아니라, 감싸는 것이다

여기서 model eval을 버리자는 뜻은 아니다. Claude Code 사례가 보여 주는 더 좋은 독법은 다음과 같다.

1. model eval로 base capability를 본다.
2. harness eval로 그 capability가 실제 runtime에서 어떻게 증폭되거나 손실되는지 본다.
3. 둘이 충돌하면 귀속점을 분리한다.
   예: model은 충분하지만 permission/continuation/prompt assembly가 성능을 깎는 경우

이 순서를 지키면 "모델만 바꾸면 해결될까?"와 "하네스 구조를 바꾸는 편이 맞을까?"를 구분할 수 있다.

## 관찰, 원칙, 해석, 권고

관찰:

- QueryEngine result packet은 텍스트 출력보다 넓은 run-level outcome을 남긴다.
- transcript persistence와 cost logging은 evaluation input을 product 안에서 직접 생성한다.
- GrowthBook override와 VCR fixture는 harness evaluation의 재현성 문제를 정면으로 다룬다.

원칙:

- run-level artifact가 없다면 harness eval은 구호에 그친다.
- 재현성 control 없이 측정만 늘리면 결과는 해석 불가능해진다.
- 비용, denial, latency, turn count는 부가 지표가 아니라 harness outcome의 일부다.

해석:

- Anthropic의 evals 글이 말하는 task/trial/outcome 언어는 Claude Code에서 result packet, transcript, cost state, feature override로 구체화된다.
- Meta-Harness 관점에서 보면 Claude Code는 모델이 아니라 harness 자체가 최적화 대상이라는 사실을 강하게 드러낸다.

권고:

- 새로운 coding harness를 평가할 때는 최소한 result packet, transcript, cost/usage, flag control 네 층을 함께 설계하라.
- model eval 결과와 harness eval 결과를 같은 표에 섞지 말고, 귀속점 열을 별도로 두어라.
- feature flag, sandbox, transcript policy처럼 runtime 조건이 흔들리는 surface를 deterministic override 없이 평가하지 말라.

## benchmark 질문

1. 이 시스템은 run-level artifact를 텍스트 출력 밖으로 충분히 노출하는가.
2. 같은 모델 아래서 harness 조건만 고정하거나 바꿔 볼 수 있는가.
3. 비용, denial, latency, turn count를 outcome으로 읽는가.
4. replayable fixture와 flag override 없이도 evaluation이 drift하지 않는다고 자신할 수 있는가.

## 요약

model eval과 harness eval의 차이는 추상적 범주 차이가 아니라 artifact 차이다. Claude Code는 result packet, transcript, cost/usage, VCR, flag override 같은 구조를 통해 실제 run 전체를 평가 대상으로 만든다. 이 구조를 읽지 못하면 실패 원인을 모델 탓으로만 돌리게 되고, 개선도 엉뚱한 층을 건드리게 된다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/QueryEngine.ts`
   result packet이 어떤 run-level outcome을 남기는지 본다.
2. `src/hooks/useLogMessages.ts`
   transcript가 evaluation evidence로 어떻게 누적되는지 본다.
3. `src/cost-tracker.ts`
   cost/usage가 session outcome으로 어떻게 저장되고 복원되는지 본다.
4. `src/services/api/logging.ts`
   API attempt 단위 계측이 어떤 metadata를 남기는지 확인한다.
5. `src/services/analytics/growthbook.ts`
   feature configuration을 evaluation-friendly하게 고정하는 surface를 본다.
6. `src/services/vcr.ts`
   replayability가 harness concern임을 확인한다.
