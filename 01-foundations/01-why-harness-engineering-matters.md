# 01. 왜 하네스 엔지니어링이 중요한가

> Why this chapter exists: 하네스를 왜 별도 설계 영역으로 읽어야 하는지,
> 그리고 왜 observability, economics, policy surface, reviewability가 처음부터
> 들어와야 하는지 고정한다.
> Reader level: beginner / advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: medium
> Verified proposal sources: `S1`, `S6`, `S8`, `S22`, `S30`

## Core claim

하네스 엔지니어링은 "모델을 한 번 더 잘 부르게 만드는 프롬프트 기술"이 아니다.
그것은 장기 실행형 agent가 도구를 쓰고, 사람과 상호작용하고, 실패에서 회복하며,
다시 측정 가능한 run artifact를 남기도록 만드는 운영 시스템 설계다.

Anthropic은 agent 성능을 올릴 때 먼저 workflow와 agent 구조를 단순하고
검토 가능하게 잡으라고 말한다 (`S1`). 또 장기 실행 작업에서는 clean state와
structured handoff artifact가 성능을 좌우한다고 말한다 (`S6`). OpenAI의
Agents SDK와 tracing 문서는 run-level trace가 development와 production 모두의
관찰 표면임을 드러낸다 (`S22`). NIST GenAI Profile은 이런 artifact가 단지
개발 편의가 아니라 trustworthiness review의 입력이 된다는 점을 보여 준다
(`S30`). 그래서 하네스는 모델 호출의 주변부가 아니라 모델 호출이 성능을 낼 수
있게 만드는 load-bearing layer다.

## What this chapter is not claiming

- 모델 품질보다 하네스가 언제나 더 중요하다는 주장
- 모든 agent 시스템이 복잡한 multi-agent harness를 가져야 한다는 주장
- 특정 제품의 비공개 구현을 추정해 채워 넣겠다는 주장

## 왜 별도 설계 영역인가

모델이 좋아도 아래 질문에 답하지 못하면 실제 제품 성능은 쉽게 무너진다.

1. 세션은 어떤 instruction, permission, policy 아래에서 시작되는가
2. agent는 무엇을 보고, 어떤 tool을, 어떤 계약 표면으로 쓸 수 있는가
3. 사람이 언제 개입하고, 어떤 artifact를 보고 판단하는가
4. 세션이 길어지거나 끊기면 무엇이 남고, 무엇을 다음 run에 넘기는가
5. run이 끝난 뒤 무엇을 측정하고, 무엇을 review하고, 무엇을 비교할 수 있는가

이 질문은 prompt template 하나로 풀리지 않는다. workflow decomposition,
context control, tool contract, policy surface, trace schema, handoff note,
cost record, grader artifact가 함께 필요하다. 그래서 하네스는 모델 wrapper가
아니라 운영 시스템이다.

## 모델 wrapper와 운영 시스템의 차이

| 질문 | 단순 wrapper의 답 | 하네스 엔지니어링의 답 |
| --- | --- | --- |
| 입력을 어떻게 만들까 | prompt template | context assembly, compaction, memory, handoff artifact |
| 모델이 무엇을 할까 | completion 생성 | tool use, permission, task orchestration, escalation |
| 사람이 어떻게 개입할까 | 거의 없음 | transcript, approvals, skeptical review, override surface |
| 실패 후 어떻게 이어 갈까 | 재시도 | clean state, resume contract, progress note, restore path |
| 무엇을 측정할까 | 최종 응답 품질 | trace, transcript, cost, latency, denial, outcome, grader result |
| 무엇을 검토할까 | prompt wording | policy drift, release drift, trace privacy, trustworthiness review |

production coding harness에서는 오른쪽 열이 사용자 경험과 운영 비용을 더 많이
좌우한다.

## foundation 단계에서 반드시 드러나야 하는 네 가지 운영 면

### 1. observability와 reviewability

run을 다시 읽을 수 있게 해 주는 artifact가 없으면 시스템은 개선도, 감사도,
사후 분석도 어렵다. `S22`는 trace와 span을 built-in artifact로 다루고,
sensitive-data capture를 설정으로 제어한다. 이 책에서는 transcript, trace,
result packet, cost record, permission decision, handoff note를 하나의
reviewability family로 읽는다.

### 2. release drift와 policy surface

하네스는 고정된 프롬프트가 아니라 release note, SDK surface, policy control,
tool contract에 계속 영향을 받는다. 따라서 "어떻게 동작하는가" 못지않게
"어떤 설정과 정책이 그 동작을 만든 것인가"를 함께 기록해야 한다.

### 3. economics와 headroom

`S8`은 더 강한 harness가 더 좋은 결과를 낼 수 있지만, 비용과 wall-clock
latency가 급격히 커질 수 있음을 보여 준다. harness quality는 정확도만이 아니라
"성공당 얼마가 들고 얼마나 오래 걸리는가"라는 질문과 함께 읽어야 한다.

### 4. continuity와 handoff artifact

`S6`은 장기 작업을 여러 세션에 걸쳐 이어 갈 때 clean state와 structured
handoff artifact가 중요하다고 강조한다. progress note, sprint contract,
resume summary 같은 artifact는 단지 편의 기능이 아니라 장기 수행의 핵심
구조다.

## operational artifact가 없는 harness는 왜 쉽게 막히는가

좋은 모델이 있어도 다음 failure는 쉽게 생긴다.

- trace가 없어 어느 판단이 어디서 틀어졌는지 모른다.
- handoff note가 없어 다음 세션이 context를 다시 만들어야 한다.
- cost record가 없어 quality 상승이 합리적인 대가였는지 판단하지 못한다.
- policy surface가 불분명해 release drift와 permission drift를 설명하지 못한다.
- review artifact가 약해 evaluator나 human reviewer가 "왜 pass였는지"를
  재구성하지 못한다.

이 실패들은 모델 eval 점수만으로 거의 드러나지 않는다. 그래서 하네스
엔지니어링을 별도 설계 영역으로 보는 것이 중요하다.

## Design implications

- 하네스를 설명할 때 prompt와 model choice보다 먼저 operational artifact를
  그려야 한다.
- trace, transcript, handoff, cost, policy note는 나중에 덧붙일 telemetry가
  아니라 구조의 일부다.
- release drift가 큰 surface는 verified date와 source ID를 함께 남겨야 한다.
- governance review는 추상 규정이 아니라, 실제 운영 artifact가 얼마나 남는지에
  따라 품질이 달라진다.

## What to measure

- 성공한 run당 cost와 wall-clock latency
- trace completeness와 reviewer replay 가능성
- approval / denial / escalation 빈도
- handoff artifact가 다음 세션에서 재사용된 비율
- policy or release drift가 문서에 반영되기까지 걸린 시간

## Failure signatures

- 모델은 충분해 보이는데 run을 설명할 trace와 transcript가 없다.
- 품질은 좋아졌지만 비용과 시간 증가를 정당화할 artifact가 없다.
- 세션 간 handoff가 빈약해 같은 일을 반복해서 설명한다.
- 설정이나 policy가 바뀌었는데 verified date와 source note가 갱신되지 않는다.
- skeptical reviewer가 pass/fail 이유를 재구성하지 못한다.

## Review questions

1. 이 시스템은 모델 호출 바깥의 load-bearing decision을 무엇으로 남기는가.
2. trace, transcript, handoff, cost record 가운데 무엇이 실제 review artifact인가.
3. release drift와 policy drift를 설명할 canonical source와 verified date가 있는가.
4. 더 좋은 품질이 나왔을 때 그것이 economics와 운영 복잡도를 정당화하는가.

## Sources / evidence notes

- `S1`은 workflow와 agent를 가장 단순한 구성부터 시작하라고 권한다. 이 장은
  하네스를 "모델 호출을 둘러싼 운영 시스템"으로 읽는 출발점에 그 framing을 쓴다.
- `S6`은 clean state와 structured handoff artifact를 장기 실행형 harness의
  핵심으로 다룬다. 이 장의 continuity와 reviewability framing은 여기에 기대고
  있다.
- `S8`은 더 강한 scaffold가 quality를 올릴 수 있지만 cost와 latency를 키운다는
  점을 보여 준다. economics를 foundation concern으로 끌어올린 근거다.
- `S22`는 built-in tracing, trace/span 구조, sensitive-data capture rule을
  제공한다. observability와 reviewability를 artifact 관점에서 설명할 때 쓴다.
- `S30`은 trustworthiness considerations를 design, development, use,
  evaluation에 걸쳐 반영하라고 말한다. governance를 artifact review language와
  연결하는 근거다.
