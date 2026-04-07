# 03. 에이전트 하네스의 품질 속성

> Why this chapter exists: 기능 목록보다 먼저 봐야 하는 harness quality
> attributes를 고정하고, observability, trace privacy, economic efficiency,
> reviewability를 독립 속성으로 올린다.
> Reader level: beginner / advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: medium
> Verified canonical registry sources: `S6`, `S7`, `S8`, `S22`, `S23`, `S29`

## Core claim

하네스를 설계할 때는 기능 목록보다 품질 속성을 먼저 보는 편이 낫다. 중요한
것은 "명령이 몇 개인가"보다 reliability, steerability, recoverability,
observability, trace privacy, reviewability, reproducibility, economic
efficiency가 어떤 artifact와 운영 습관에 기대고 있는가다.

`S22`는 trace/span과 sensitive-data capture를 runtime artifact로 다루고,
`S23`은 eval-driven development와 workflow trace grading을 권장한다.
`S6`과 `S8`은 long-running harness가 handoff artifact와 scaffold cost를 함께
관리해야 함을 보여 준다. 그래서 품질 속성은 추상적인 미덕이 아니라,
"무엇을 남기고 무엇을 측정하며 무엇을 다시 검토할 수 있는가"의 문제다.

## What this chapter is not claiming

- 모든 시스템이 아래 속성을 동일한 비중으로 최적화해야 한다는 주장
- 속성 수가 많을수록 좋은 harness라는 주장
- 특정 제품의 최종 scorecard를 이 장 하나로 확정하겠다는 주장

## 여덟 품질 속성

| 품질 속성 | 핵심 질문 | 대표 artifact |
| --- | --- | --- |
| reliability | 같은 작업을 예측 가능한 구조로 이어 갈 수 있는가 | task lifecycle, retry policy, terminal state |
| steerability | 사람이 상태를 읽고 방향을 바꿀 수 있는가 | transcript, approval queue, override surface |
| recoverability | 중단 뒤 semantic continuity가 유지되는가 | handoff note, resume summary, restore state |
| observability | 현재 상태와 결과를 읽을 수 있는가 | trace, transcript, diagnostics, result packet |
| trace privacy | trace가 유용하면서도 민감정보 노출을 통제하는가 | redaction rule, capture setting, masking policy |
| reviewability | skeptical reviewer가 pass/fail 이유를 재구성할 수 있는가 | grader criteria, trace link, cost record, policy note |
| reproducibility | 같은 조건을 다시 만들 수 있는가 | isolated environment, version pin, fixture, dataset provenance |
| economic efficiency | 같은 결과를 적은 turn, 적은 latency, 적은 비용으로 내는가 | cost record, cache, token budget, retry churn |

이 여덟 속성은 체크리스트가 아니라 서로 긴장하는 품질 목표다.

## observability와 reviewability는 다르다

둘은 밀접하지만 같지 않다.

- observability는 시스템이 무엇을 했는지 보이게 하는 속성이다.
- reviewability는 그 기록만으로 skeptical reviewer가 판단을 재구성할 수 있게
  하는 속성이다.

trace가 많아도 grader criteria, policy context, cost record가 없으면
reviewability는 낮다. 반대로 간결한 artifact라도 why-pass / why-fail이
재구성되면 reviewability는 높을 수 있다.

## trace privacy는 observability의 하위 항목이 아니라 독립 속성이다

`S22`는 built-in tracing이 기본 활성화이며, generation/function span의
input/output capture가 민감정보를 담을 수 있음을 명시한다. 또
`trace_include_sensitive_data`로 이를 제어할 수 있다고 설명한다. 따라서
"trace를 남긴다"는 말은 곧 "무엇을 캡처하고 무엇을 숨기는가"를 함께 설계한다는
뜻이다.

`S29`는 GenAI events, metrics, model spans, agent spans vocabulary를 제안하지만
현재 status가 `Development`다. 즉 schema 표준화는 도움을 주지만, 그대로
고정 규칙처럼 다루기보다 freshness note와 함께 써야 한다.

## economic efficiency는 정확도의 적이 아니라 설계 제약이다

`S8`은 더 강한 scaffold가 quality를 올릴 수 있지만, 비용과 wall-clock
latency도 크게 늘릴 수 있음을 보여 준다. 그래서 economic efficiency는
"돈을 아끼자"가 아니라 "성공당 얼마를 써도 되는가"를 명시하는 속성이다.

이 속성은 보통 아래와 같이 드러난다.

- 더 많은 evaluator loop를 돌릴 것인가
- 긴 trace와 rich artifact를 어디까지 보존할 것인가
- clean-state reset을 더 자주 할 것인가
- approval과 retry를 얼마나 허용할 것인가

## quality attribute는 operational artifact와 함께 읽어야 한다

품질 속성을 artifact와 연결하지 않으면 문장이 공허해진다.

- reliability는 terminal state와 retry path를 남기는 artifact가 있어야 보인다.
- recoverability는 handoff note와 resume summary가 있어야 보인다.
- observability는 trace와 transcript가 있어야 보인다.
- trace privacy는 capture toggle과 masking policy가 있어야 보인다.
- reviewability는 grader criteria와 pass/fail evidence가 있어야 보인다.
- reproducibility는 isolated environment와 provenance가 있어야 보인다.
- economic efficiency는 cost record와 latency budget이 있어야 보인다.

## 대표 trade-off

| 속성 쌍 | 흔한 긴장 |
| --- | --- |
| observability vs trace privacy | 더 많은 capture는 분석을 돕지만 민감정보 노출 위험을 늘린다 |
| reviewability vs economic efficiency | richer artifact와 grader loop는 재검토를 돕지만 비용과 latency를 올린다 |
| recoverability vs simplicity | handoff와 restore를 강화할수록 상태 공간이 복잡해진다 |
| reproducibility vs flexibility | dynamic config가 많을수록 동일 조건 재현은 어려워진다 |
| steerability vs autonomy | operator surface를 넓히면 개입은 쉬워지지만 자율 흐름은 자주 끊길 수 있다 |

## What to measure

- trace completeness와 missing span 비율
- sensitive-data capture 설정과 masking coverage
- skeptical reviewer가 동일 판단에 도달하는 비율
- isolated rerun 재현 성공률
- 성공 task당 cost, latency, retry 횟수
- handoff 뒤 재작업 없이 이어진 세션 비율

## Failure signatures

- trace는 있지만 reviewer가 pass/fail 이유를 설명하지 못한다.
- 민감정보를 남길까 봐 trace를 끄고, 그 결과 장애 원인 분석이 막힌다.
- 동일 failure를 재현하지 못해 개선 검증이 흔들린다.
- evaluator loop가 효과는 있지만 cost와 시간 증가를 설명하지 못한다.
- artifact는 풍부하지만 schema와 status가 불분명해 도구 간 비교가 어렵다.

## Review questions

1. 이 시스템의 strongest/weakest quality attribute는 무엇인가.
2. observability와 reviewability를 서로 다른 artifact로 설명할 수 있는가.
3. trace privacy는 "나중에 붙일 옵션"이 아니라 설계 속성으로 다뤄지고 있는가.
4. economic efficiency를 성공률과 함께 읽고 있는가.

## Sources / evidence notes

- `S22`는 built-in tracing, trace/span 구조, sensitive-data capture toggle을
  제공한다. observability와 trace privacy를 분리해 설명하는 근거다.
- `S23`은 eval-driven development, workflow trace grading, grader criteria를
  강조한다. reviewability 속성을 별도로 두는 근거다.
- `S29`는 GenAI events, metrics, model spans, agent spans vocabulary를 주지만
  아직 `Development` status다. observability schema를 freshness-sensitive하게
  다뤄야 하는 근거다.
- `S6`은 clean state와 handoff artifact를 강조한다. recoverability와
  reviewability를 operational artifact에 연결하는 근거다.
- `S8`은 stronger scaffold와 cost/latency trade-off를 보여 준다. economic
  efficiency를 독립 속성으로 올리는 근거다.
