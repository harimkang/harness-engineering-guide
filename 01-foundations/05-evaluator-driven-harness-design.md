# 05. evaluator-driven harness 설계

> Why this chapter exists: evaluator-driven design을 task, workflow trace,
> skeptical review, eval hygiene, operational artifact 관점에서 읽는 법을
> 고정한다.
> Reader level: advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: medium
> Verified canonical registry sources: `S6`, `S7`, `S8`, `S21`, `S22`, `S23`

## Core claim

장기 실행형 하네스가 실패하는 이유를 "모델이 약해서" 하나로 묶으면 중요한
절반을 놓친다. evaluator-driven harness의 핵심은 agent 수를 늘리는 데 있지
않다. 더 중요한 것은 self-grading leniency를 별도 failure mode로 보고,
planner, generator, evaluator를 서로 다른 judgment layer로 분리하며,
workflow-level trace와 grader artifact를 남기고, contamination과 shared-state
noise를 줄이는 hygiene 규칙을 세우는 데 있다.

`S8`은 generator와 evaluator를 분리하고 evaluator를 더 skeptical하게
튜닝하는 편이 self-grading 문제를 다루기 쉽다고 말한다. `S7`은 task, trial,
transcript, grader, isolated environment를 갖춘 eval harness를 설명한다.
`S23`은 eval-driven development와 trace grading을 권장한다. 따라서
evaluator-driven design은 사후 QA가 아니라 운영 artifact와 control loop를
함께 설계하는 일이다.

## What this chapter is not claiming

- 모든 harness가 planner/generator/evaluator 삼분 구조를 가져야 한다는 주장
- evaluator를 추가하면 곧바로 품질이 보장된다는 주장
- 특정 제품이 full evaluator loop를 내부적으로 구현한다고 단정하겠다는 주장

## 왜 naive self-grading은 쉽게 무너지는가

agent에게 "방금 네가 만든 게 충분히 좋은가"를 묻는 순간, 흔히 두 문제가 생긴다.

1. 자기 의도와 worklog를 너무 잘 알아서 결함을 변호한다.
2. 확인 행동보다 설명과 합리화에 더 쉽게 끌린다.

`S8`은 subjective task에서 이 문제가 특히 강하지만, verifiable task에서도
poor judgment가 남는다고 설명한다. 따라서 evaluator-driven harness의 첫
출발점은 self-critique를 더 세게 요구하는 것이 아니라, self-grading 자체를
별도 failure mode로 인식하는 일이다.

## planner, generator, evaluator는 judgment layer다

| 역할 | 주로 줄이려는 실패 | 대표 artifact |
| --- | --- | --- |
| planner | under-scoping, premature implementation, vague acceptance criteria | expanded spec, sprint plan |
| generator | 구현 churn, integration failure, incomplete execution | code diff, run output, handoff note |
| evaluator | self-justification, shallow QA, lenient pass judgment | grader criteria, critique, fail/pass record |

이 표가 뜻하는 바는 분명하다. 세 역할을 분리한다는 것은 "agent 수를 늘린다"가
아니라, 서로 다른 판단을 서로 다른 artifact 위에서 하게 만든다는 뜻이다.

## evaluator-driven design을 가능하게 하는 operational artifact

evaluator가 제대로 일하려면 단순한 reviewer persona만으로는 부족하다.
다음 artifact family가 함께 필요하다.

- task or sprint contract
  - 무엇을 만들고 무엇을 검사할지 미리 고정한다.
- workflow trace와 transcript
  - 어떤 판단과 tool call이 pass/fail에 이르렀는지 다시 본다.
- grader criteria와 threshold
  - "좋다"가 아니라 무엇이 통과 조건인지 적는다.
- handoff note와 result packet
  - 다음 loop가 무엇을 이어받아야 하는지 남긴다.
- cost / latency record
  - evaluator loop가 값어치를 했는지 판단한다.

`S21`과 `S22`는 full trace, trace/span, handoff-aware execution을 설명한다.
`S23`의 trace grading은 workflow trace가 evaluator artifact가 될 수 있음을
명시적으로 보여 준다.

## skeptical evaluator는 persona이자 policy다

`S8`의 중요한 교훈은 standalone evaluator를 skeptical하게 튜닝하는 것이,
generator가 자기 work를 비판적으로 보게 만드는 것보다 더 tractable하다는
점이다. 이 장에서는 evaluator를 두 층으로 나눠 읽는다.

- persona
  - strict reviewer, skeptical QA, taste-heavy critic 같은 태도
- policy
  - criteria, threshold, fail rule, escalation rule 같은 판정 규칙

이 둘을 분리하면 다음 질문이 가능해진다.

- evaluator가 너무 forgiving한가
- criteria는 괜찮지만 threshold가 낮은가
- trace는 풍부한데 inspection behavior가 shallow한가

## eval hygiene와 contamination control

평가 artifact가 많아질수록 hygiene 규칙도 중요해진다.

- trial은 가능한 한 isolated environment에서 시작해야 한다.
- shared state, leftover file, cache noise는 agent quality와 infrastructure noise를
  섞어 버린다.
- production trace를 eval dataset로 재사용할 때는 provenance, deduping,
  time window, policy/version drift를 함께 기록해야 한다.
- generator prompt와 grader criteria가 섞일수록 평가가 느슨해질 수 있으므로,
  둘을 artifact와 역할 수준에서 분리하는 편이 낫다.

위 네 번째 항목은 `S7`의 stable environment / isolated trial framing과 `S23`의
task-specific eval, trace grading, continuous evaluation practice를 바탕으로 한
운영 권고다.

## scaffold는 현재 모델에 대한 가설이다

`S8`은 복잡한 harness를 만든 뒤에도 planner, evaluator, reset, sprint scaffold를
영구 구조로 신성시하지 않는다. 무엇이 여전히 load-bearing한지 다시 확인한다.

이는 중요한 설계 태도를 준다.

- scaffold는 영구 아키텍처가 아니다.
- scaffold는 현재 모델이 solo로 안정적으로 못하는 것을 보완하는 가설이다.
- 모델이 바뀌면 evaluator loop와 contract ritual이 과잉 복잡도가 될 수 있다.
- 반대로 작업 종류가 바뀌면 이전에는 불필요했던 evaluator가 다시 중요해질 수 있다.

## What to measure

- grader agreement와 skeptical reviewer agreement
- isolated rerun에서 pass/fail이 유지되는 비율
- trace grading이 찾아낸 failure category 수
- evaluator loop 추가 전후의 품질 상승 대비 cost / latency 변화
- production trace에서 eval dataset으로 승격된 사례의 provenance completeness

## Failure signatures

- generator가 자기 work를 계속 통과시키고 evaluator가 형식적 승인만 한다.
- trace는 남지만 grader criteria와 threshold가 없어 why-pass를 설명하지 못한다.
- production issue를 eval dataset으로 옮겼지만 provenance와 time window가 없다.
- shared state 때문에 eval score가 흔들리는데 이를 model failure로 오해한다.
- evaluator loop는 길어졌지만 실제 품질 개선과 economics trade-off를 설명하지 못한다.

## Review questions

1. 이 하네스는 self-evaluation failure를 별도 failure mode로 다루는가.
2. planner, generator, evaluator가 서로 다른 artifact와 judgment layer를 가지는가.
3. workflow trace와 grader criteria가 pass/fail 재구성에 충분한가.
4. eval hygiene와 contamination control 규칙이 명시돼 있는가.
5. evaluator scaffold가 현재 모델에 대해 여전히 load-bearing한지 재검증하는가.

## Sources / evidence notes

- `S8`은 self-evaluation 문제, skeptical evaluator tuning, planner/generator/
  evaluator split, contract-based QA를 직접 설명한다.
- `S7`은 task, trial, transcript, grader, isolated environment를 갖춘 eval
  harness를 설명한다. hygiene와 contamination control의 기초 근거다.
- `S23`은 eval-driven development, task-specific eval, trace grading을
  강조한다. workflow-level trace를 evaluator artifact로 다루는 근거다.
- `S21`과 `S22`는 full trace, trace/span, handoff-aware execution, sensitive
  data control을 설명한다. evaluator-driven loop의 operational artifact를
  reviewable하게 만드는 근거다.
- `S6`은 clean state와 structured handoff artifact를 강조한다. planner/
  generator/evaluator가 세션 사이를 넘나들 때 continuity artifact가 필요한
  근거다.
