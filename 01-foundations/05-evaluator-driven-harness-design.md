# 05. evaluator-driven harness 설계

## 장 요약

장기 실행형 하네스가 실패하는 이유를 "모델이 약해서" 하나로 묶으면 중요한 절반을 놓친다. Anthropic의 2026-03-24 글은 긴 코딩 작업에서 context drift만큼이나 self-evaluation failure가 크다는 점을 강조한다. agent는 자기 산출물을 과하게 후하게 보는 경향이 있고, 이 문제는 subjective task에서 더 쉽게 드러나지만 verifiable task에서도 사라지지 않는다. 이 장은 그런 failure mode를 다루기 위해 evaluator-driven harness를 어떻게 읽고 설계할지 정리한다.

이 장의 핵심은 세 가지다. 첫째, planner, generator, evaluator는 단지 역할 이름이 아니라 서로 다른 실패를 줄이는 scaffold다. 둘째, subjective judgment를 criteria와 threshold로 다시 적지 않으면 evaluator는 쉽게 drift한다. 셋째, 이런 scaffold는 영구불변 구조가 아니라 현재 모델이 무엇을 solo로 안정적으로 할 수 있는지에 따라 다시 제거되거나 단순화될 수 있다.

## 범위와 비범위

이 장이 다루는 것:

- self-evaluation failure를 별도 harness 문제로 읽는 법
- planner, generator, evaluator 분리가 어떤 실패를 줄이는지
- subjective quality를 gradable criteria로 바꾸는 방법
- evaluator를 skeptical persona로 다루는 이유
- model-relative scaffold pruning의 의미

이 장이 다루지 않는 것:

- 특정 prompt 문구의 최적값
- 특정 QA toolchain이나 Playwright script의 구현 세부
- Claude Code 공개 사본이 full planner/generator/evaluator 구조를 직접 구현한다고 단정하는 일

이 장은 원칙 장이다. 따라서 local product 사실을 새로 증명하기보다, 이미 다른 장에서 정리한 artifact와 Anthropic의 외부 원칙을 연결하는 synthesis frame을 제공한다.

## 자료와 독서 기준

주요 reader-facing 근거:

- [../foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md](04-core-design-axes-context-control-tools-memory-safety-evals.md)
- [../context/03-compaction-memory-and-handoff-artifacts.md](../03-context-and-control/03-compaction-memory-and-handoff-artifacts.md)
- [../execution/03-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md)
- [../evaluation/02-tasks-trials-transcripts-and-graders.md](../07-evaluation-and-synthesis/02-tasks-trials-transcripts-and-graders.md)
- [../evaluation/03-benchmarking-coding-harnesses.md](../07-evaluation-and-synthesis/03-benchmarking-long-running-agent-harnesses.md)
- [../evaluation/04-production-traces-feedback-loops-and-optimization.md](../07-evaluation-and-synthesis/04-production-traces-feedback-loops-and-optimization.md)

외부 프레이밍:

- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Anthropic, [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents), 2024-12-19

함께 읽으면 좋은 장:

- [../evaluation/06-contract-based-qa-and-skeptical-evaluators.md](../07-evaluation-and-synthesis/06-contract-based-qa-and-skeptical-evaluators.md)
- [../17-end-to-end-scenarios.md](../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)
- [../15-code-reading-guide.md](../07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md)

## naive self-grading은 왜 쉽게 무너지는가

agent에게 "방금 네가 만든 게 충분히 좋은가?"를 물으면, 많은 경우 두 가지 문제가 생긴다.

1. 자기 worklog와 의도를 너무 잘 알아서 결함을 변호한다.
2. 확인 행동보다 설명과 합리화에 더 쉽게 끌린다.

subjective task에서는 이 문제가 특히 분명하다. design quality나 originality는 binary test로 닫히지 않기 때문에, generator는 "그럴듯해 보인다"는 이유만으로 pass를 내리기 쉽다. 하지만 verifiable task에서도 문제는 남는다. edge case를 몇 개 놓쳤더라도, generator는 "큰 방향은 맞다"는 이유로 스스로 승인해 버릴 수 있다.

따라서 evaluator-driven harness의 첫 출발점은 model self-critique를 더 세게 요구하는 것이 아니라, self-grading 자체를 별도 failure mode로 인식하는 일이다.

## planner, generator, evaluator는 서로 다른 실패를 줄인다

Anthropic의 2026-03-24 글은 planner, generator, evaluator를 단순 multi-agent ornament로 다루지 않는다. 각 agent는 서로 다른 결함을 보정한다.

| 역할 | 주로 줄이려는 실패 | 대표 산출물 |
| --- | --- | --- |
| planner | under-scoping, premature implementation, spec drift의 출발점 | expanded spec, high-level design 방향 |
| generator | 실제 build failure, integration failure, implementation churn | code, 실행 결과, intermediate artifact |
| evaluator | self-justification, shallow QA, subjective drift | critique, fail/pass judgment, feedback artifact |

이 표가 뜻하는 바는 분명하다. planner, generator, evaluator를 분리한다는 것은 "agent 수를 늘린다"가 아니라, 문제를 서로 다른 judgment layer로 나눠 다룬다는 뜻이다.

## subjective quality를 gradable criteria로 바꿔라

evaluator가 정말로 skeptical하게 동작하려면, "좋은가?"라는 질문을 그대로 던져서는 안 된다. subjective task를 evaluation loop에 넣으려면 먼저 criteria language로 다시 적어야 한다.

예를 들어 design task라면 다음처럼 쪼갤 수 있다.

- design quality  
  전체 mood와 identity가 일관된가
- originality  
  default-heavy output이 아니라 deliberate choice가 보이는가
- craft  
  spacing, hierarchy, contrast 같은 기본기가 무너지지 않았는가
- functionality  
  aesthetic judgment과 별개로 usable한가

핵심은 criteria가 많다는 사실이 아니라, 무엇을 더 중요하게 보는지까지 같이 적는 것이다. 그렇지 않으면 evaluator는 다시 평균적인 안전 판단으로 돌아간다.

## evaluator는 persona이자 policy다

evaluator를 하나의 model call로만 생각하면, drift와 calibration 문제가 문서에서 사라진다. 더 좋은 독법은 evaluator를 두 층으로 나누는 것이다.

1. persona  
   design critic, skeptical QA, strict code reviewer처럼 어떤 태도로 볼 것인가
2. policy  
   criteria, threshold, fail rule, contract를 어떻게 적용할 것인가

이 둘을 분리해 두면 다음과 같은 질문이 가능해진다.

- evaluator가 너무 forgiving한가
- rule은 괜찮지만 threshold가 낮은가
- criteria는 있는데 실제 inspection behavior가 shallow한가

즉 evaluator는 단순 reviewer가 아니라, persona와 policy가 함께 shaped된 execution surface다.

## scaffold는 현재 모델에 대한 가설이다

Anthropic의 2026-03-24 글이 특히 중요한 이유는, 복잡한 harness를 만든 뒤 그대로 신성시하지 않았기 때문이다. planner, sprint construct, per-sprint evaluator 같은 요소를 하나씩 제거해 보면서 무엇이 여전히 load-bearing한지 다시 점검했다. 이 과정이 뜻하는 것은 단순하다.

- scaffold는 영구 아키텍처가 아니다.
- scaffold는 현재 모델이 solo로 잘 못하는 것을 보완하기 위한 operating hypothesis다.

모델이 더 긴 context를 안정적으로 다루고, solo build quality가 좋아지면 이전에는 필수였던 scaffold가 비용과 latency만 늘리는 장치가 될 수 있다. 반대로 새로운 종류의 작업이 들어오면, 이전에는 필요 없던 evaluator가 새로 load-bearing해질 수도 있다.

## 이 책에서 이 프레임을 어떻게 써야 하는가

이 책의 Claude Code 사례 spine은 transcript, task artifact, compaction, resume, permission, trace stack을 강하게 보여 준다. 반면 full evaluator-driven coding loop를 local product fact로 직접 보여 주지는 않는다. 따라서 독자는 두 단계를 분리해 읽는 편이 안전하다.

1. local code가 실제로 무엇을 보여 주는가  
   transcript, outcome, restore, task artifact, operator surface
2. Anthropic의 외부 원칙이 어떤 비교 프레임을 추가하는가  
   self-evaluation failure, skeptical evaluator, contract-first QA, scaffold pruning

이 구분을 지켜야 외부 원칙을 local product 사실처럼 오독하지 않게 된다.

## 관찰, 원칙, 해석, 권고

관찰:

- Anthropic의 2026-03-24 글은 self-evaluation failure를 context drift와 별도 failure mode로 다룬다.
- planner, generator, evaluator는 서로 다른 실패를 줄이는 scaffold로 제시된다.
- 현재 공개 Claude Code 스냅샷만으로는 full evaluator-driven coding loop를 local fact로 단정할 수 없다.

원칙:

- self-grading failure는 별도 harness 문제로 다루는 편이 낫다.
- evaluator는 generator와 구분된 skeptical role이어야 한다.
- scaffold necessity는 model-relative하게 재검증해야 한다.

해석:

- evaluator-driven harness는 evaluation 축을 control 축 안으로 더 깊이 끌어당긴다.
- planner/generator/evaluator 분리는 multi-agent ornament가 아니라 judgment layer 분리다.

권고:

- self-grading leniency 사례를 별도 failure bucket으로 모아라.
- evaluator를 설계할 때 input, criteria, threshold, persona를 분리해 문서화하라.
- 모델이 바뀔 때는 planner, sprint, evaluator scaffold를 하나씩 제거해 보며 load-bearing 여부를 다시 점검하라.

## benchmark 질문

1. 이 하네스는 self-evaluation failure를 별도 failure mode로 다루는가.
2. planner, generator, evaluator가 서로 다른 실패를 줄이는 구조로 설명되는가.
3. subjective quality가 criteria와 threshold로 다시 적혀 있는가.
4. evaluator scaffold가 현재 모델에 대해 여전히 load-bearing한지 재검증하는가.

## 요약

evaluator-driven harness 설계의 핵심은 agent 수를 늘리는 데 있지 않다. 더 중요한 것은 self-grading leniency를 별도 문제로 보고, planner/generator/evaluator를 서로 다른 judgment layer로 분리하며, criteria와 threshold를 explicit하게 적고, 모델이 바뀔 때 그 scaffold를 다시 걷어 볼 수 있게 만드는 데 있다. 이 관점이 있어야 long-running harness의 복잡도가 왜 필요한지, 또 언제 과해지는지를 함께 설명할 수 있다.

## 대표 근거 읽기 순서

1. [appendix/references.md](../00-front-matter/03-references.md)
   2026-03-24 글이 이 책에서 어떤 역할을 맡는지 먼저 고정한다.
2. [context/03-compaction-memory-and-handoff-artifacts.md](../03-context-and-control/03-compaction-memory-and-handoff-artifacts.md)
   context continuity와 reset/compaction 논의를 본다.
3. [evaluation/02-tasks-trials-transcripts-and-graders.md](../07-evaluation-and-synthesis/02-tasks-trials-transcripts-and-graders.md)
   grader input과 rule vocabulary를 확인한다.
4. [evaluation/04-production-traces-feedback-loops-and-optimization.md](../07-evaluation-and-synthesis/04-production-traces-feedback-loops-and-optimization.md)
   calibration과 optimization loop를 본다.
5. [evaluation/06-contract-based-qa-and-skeptical-evaluators.md](../07-evaluation-and-synthesis/06-contract-based-qa-and-skeptical-evaluators.md)
   contract-first QA 구조를 이어서 읽는다.
