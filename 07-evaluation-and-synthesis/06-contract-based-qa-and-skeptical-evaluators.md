# 06. contract-based QA와 skeptical evaluator

## 장 요약

long-running coding harness에서 QA를 마지막 단계의 smoke test로만 두면, generator가 무엇을 끝낸 것으로 볼지와 evaluator가 무엇을 실패로 볼지가 뒤섞이기 쉽다. Anthropic의 2026-03-24 글이 추가로 보여 주는 것은, 좋은 evaluator loop가 grader 하나로 닫히지 않는다는 점이다. 그 앞에는 contract가 있고, 그 뒤에는 skeptical judgment와 calibration이 있다. 이 장은 contract-based QA와 skeptical evaluator를 evaluation 설계 단위로 정리한다.

핵심 질문은 세 가지다. 첫째, 이번 chunk에서 무엇을 done으로 볼 것인가. 둘째, 어떤 criteria와 threshold를 적용할 것인가. 셋째, evaluator가 generator의 자기 설명을 얼마나 쉽게 믿지 않도록 만들 것인가. 이 세 질문에 답하지 않으면 QA는 쉽게 post-hoc commentary로 흐른다.

## 범위와 비범위

이 장이 다루는 것:

- sprint contract나 chunk contract를 evaluation 설계 단위로 읽는 법
- criteria, threshold, fail rule을 분리하는 이유
- skeptical evaluator가 왜 self-grading보다 다루기 쉬운지
- live app inspection이 필요한 경우와 static artifact로 충분한 경우
- disagreement case를 calibration input으로 쓰는 방법

이 장이 다루지 않는 것:

- 특정 browser automation script의 구현 세부
- 특정 QA prompt의 wording 최적화
- Claude Code 공개 사본 안에 full contract-negotiation loop가 이미 존재한다고 단정하는 일

이 장은 evaluation 파트의 원칙 장이다. 따라서 local product fact를 새로 증명하기보다, reader-facing corpus와 외부 원칙을 묶어 contract-based QA라는 비교 프레임을 제공한다.

## 자료와 독서 기준

주요 reader-facing 근거:

- [./02-tasks-trials-transcripts-and-graders.md](02-tasks-trials-transcripts-and-graders.md)
- [./03-benchmarking-coding-harnesses.md](03-benchmarking-long-running-agent-harnesses.md)
- [./04-production-traces-feedback-loops-and-optimization.md](04-production-traces-feedback-loops-and-optimization.md)
- [02-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md)
- [08-benchmark-oriented-code-reading-guide.md](08-benchmark-oriented-code-reading-guide.md)

외부 프레이밍:

- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09

함께 읽으면 좋은 장:

- [../foundations/05-evaluator-driven-harness-design.md](../01-foundations/05-evaluator-driven-harness-design.md)
- [./05-claude-code-benchmark-framework.md](05-harness-benchmark-framework.md)

## grader 앞에 contract가 온다

많은 evaluation 문서는 transcript와 outcome만 남기고 grader를 붙이는 순간부터 평가가 시작된다고 생각한다. contract-based QA는 이 순서를 뒤집는다. grading 이전에 먼저 contract를 만든다.

contract가 답하는 질문은 보통 이렇다.

- 이번 round에서 무엇을 만들 것인가
- 어떤 behavior가 보이면 done인가
- 무엇이 fail condition인가
- evaluator는 어디까지 확인해야 하는가

이 contract가 있으면 generator와 evaluator가 같은 말을 다른 뜻으로 쓰는 일을 줄일 수 있다. 반대로 contract가 없으면 evaluator는 run 뒤에야 "사실 이것도 필요했다"고 기준을 바꾸기 쉽고, generator는 "그건 요구사항이 아니었다"고 방어하기 쉽다.

## sprint contract는 todo list보다 강하다

Anthropic의 2026-03-24 글이 말하는 sprint contract는 일반 task list보다 더 강한 artifact다. todo list가 work items를 나열한다면, sprint contract는 verification-ready agreement를 만든다.

| artifact | 주로 하는 일 | 약한 점 |
| --- | --- | --- |
| task list | 할 일을 나눈다 | done 기준이 흐릴 수 있다 |
| spec | 큰 방향을 정한다 | chunk-level verification이 멀다 |
| sprint contract | 이번 chunk의 done과 verification을 고정한다 | 작성 비용이 든다 |

따라서 contract-based QA는 task decomposition을 대체하지 않는다. 오히려 decomposition과 verification 사이를 잇는 중간 artifact로 읽는 편이 맞다.

## criteria, threshold, fail rule을 분리하라

evaluator를 설계할 때 자주 생기는 혼동은 "무엇을 볼 것인가"와 "어느 정도여야 통과인가"와 "어떤 경우 즉시 실패인가"를 한 문단에 섞어 버리는 것이다. 더 좋은 방법은 세 층을 나누는 것이다.

- criteria  
  product depth, functionality, visual design, code quality처럼 평가 항목
- threshold  
  각 항목이 어느 점수 밑이면 fail인지, 혹은 어떤 최소 수준을 요구하는지
- fail rule  
  하나라도 threshold 아래면 전체 sprint fail인지, 평균 점수로 통과할지

이 셋을 분리해 두면 evaluator tuning이 쉬워진다. generator가 잘못한 것인지, threshold가 너무 느슨한지, fail rule이 평균화돼 edge case를 숨기는지 따로 볼 수 있기 때문이다.

## skeptical evaluator는 무엇을 의미하는가

skeptical evaluator는 단순히 까다로운 reviewer가 아니다. 더 정확히는 generator의 narrative보다 observed behavior와 explicit contract를 우선하는 evaluator를 뜻한다.

skeptical evaluator는 보통 다음 성향을 가진다.

- generator의 self-report를 그대로 믿지 않는다.
- happy path만이 아니라 edge case를 찾는다.
- "대체로 된다"보다 explicit fail condition을 우선한다.
- issue를 찾은 뒤에도 쉽게 downgrade하지 않는다.

Anthropic의 글이 말하는 calibration 과제는 바로 이 skeptical stance를 일관되게 유지하게 만드는 것이다.

## live app inspection이 필요한 경우

모든 evaluation이 transcript와 static artifact만으로 충분한 것은 아니다. 어떤 작업은 live app inspection이 있어야만 실제 품질을 볼 수 있다.

- interactive UI behavior
- workflow continuity
- API와 database state의 연결
- visual polish와 interaction friction

이 경우 browser automation이나 user-like walkthrough는 optional garnish가 아니라 grading input의 일부가 된다. 반대로 pure code transformation이나 static analysis 중심 작업은 transcript, diagnostics, test result만으로도 충분할 수 있다. 핵심은 tool choice보다 judgment target이다. 무엇을 판정해야 하는지 먼저 정하면 어떤 inspection이 필요한지도 따라온다.

## disagreement case는 최고의 calibration 입력이다

evaluator를 개선할 때 가장 고신호인 데이터는 disagreement case다. evaluator가 pass를 냈지만 인간은 fail로 보는 사례, evaluator가 shallow inspection으로 놓친 사례, issue를 발견하고도 심각도를 낮춘 사례가 특히 중요하다.

이 사례들을 calibration input으로 쓰면 세 종류의 수정을 할 수 있다.

- criteria wording 보정
- threshold 조정
- evaluator stance 보정

즉 evaluator calibration은 abstract preference tuning이 아니라, 구체적인 misjudgment trace를 반복적으로 줄이는 작업에 가깝다.

## evaluator는 언제 leverage이고 언제 overhead인가

contract-based QA도 cost가 든다. writing cost, negotiation cost, browser inspection cost, extra round-trip latency가 모두 붙는다. 그래서 evaluator는 항상 정답 구조가 아니다.

더 나은 판단 기준은 다음과 같다.

- generator solo run이 반복적으로 stub feature나 shallow QA를 남기는가
- evaluator가 발견한 issue가 final app usability를 실제로 바꾸는가
- model upgrade 뒤에도 같은 evaluator scaffold가 계속 필요한가

이 세 질문에 `예`가 줄어들면 evaluator는 leverage보다 overhead에 가까워진다. 따라서 evaluator 도입뿐 아니라 evaluator 제거도 문서화할 가치가 있다.

## 관찰, 원칙, 해석, 권고

관찰:

- Anthropic의 2026-03-24 글은 contract, criteria, threshold, evaluator calibration을 하나의 loop로 묶어 설명한다.
- reader-facing corpus의 기존 evaluation 장들은 grading input과 outcome artifact를 잘 설명하지만, contract-based QA vocabulary는 별도 보강이 필요했다.
- current Claude Code 공개 스냅샷만으로는 full contract-negotiation loop를 local product fact로 단정하기 어렵다.

원칙:

- grader 앞에 contract가 와야 한다.
- criteria, threshold, fail rule은 서로 다른 설계 단위다.
- skeptical evaluator는 generator와 분리된 stance를 가져야 한다.

해석:

- contract-based QA는 evaluation을 post-hoc judging에서 execution-time alignment로 이동시킨다.
- evaluator quality는 model quality와 별개로 조율 가능한 harness surface다.

권고:

- long-running harness 문서에는 chunk contract artifact를 별도 항목으로 넣어라.
- evaluator를 적을 때는 input, criteria, threshold, fail rule, stance를 따로 적어라.
- disagreement case를 calibration corpus로 축적하라.

## benchmark 질문

1. 이 시스템은 grading 이전에 contract를 명시적으로 세우는가.
2. criteria, threshold, fail rule이 분리돼 있는가.
3. evaluator가 generator의 self-report보다 observed behavior를 우선하는가.
4. evaluator가 현재 모델에 대해 leverage인지 overhead인지 설명할 수 있는가.

## 요약

contract-based QA와 skeptical evaluator는 long-running coding harness에서 evaluation을 더 이른 실행 단계로 끌어온다. task list만으로는 verification ambiguity가 남고, grader 하나만으로는 self-grading leniency를 해결하기 어렵다. contract, criteria, threshold, skeptical stance, calibration loop를 함께 설계해야 비로소 QA가 실제 lift를 주는 scaffold가 된다.

## 대표 근거 읽기 순서

1. [evaluation/02-tasks-trials-transcripts-and-graders.md](02-tasks-trials-transcripts-and-graders.md)
   grading input과 rule vocabulary를 먼저 잡는다.
2. [02-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md)
   chunking과 handoff artifact를 본다.
3. [evaluation/04-production-traces-feedback-loops-and-optimization.md](04-production-traces-feedback-loops-and-optimization.md)
   calibration loop를 본다.
4. [evaluation/03-benchmarking-coding-harnesses.md](03-benchmarking-long-running-agent-harnesses.md)
   benchmark axis로 어떻게 기록할지 확인한다.
5. [evaluation/05-claude-code-benchmark-framework.md](05-harness-benchmark-framework.md)
   전체 framework 안에서 어디에 놓이는지 다시 본다.
