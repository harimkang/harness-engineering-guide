# 01. 왜 하네스 엔지니어링이 중요한가

## 장 요약

하네스 엔지니어링은 "모델을 한 번 더 잘 부르게 만드는 프롬프트 기술"이 아니다. 그것은 장기 실행형 agent가 도구를 쓰고, 사람과 상호작용하고, 실패에서 회복하며, 다시 측정 가능한 run을 남기도록 만드는 운영 시스템 설계다. Claude Code 공개 사본은 바로 이 점을 잘 보여 준다. 모델 호출 하나보다, startup, operator surface, permission boundary, transcript, task, recovery가 함께 성능을 결정한다.

## 범위와 비범위

이 장이 다루는 것:

- 왜 하네스를 별도 설계 영역으로 봐야 하는지
- 모델 호출 바깥의 어떤 결정이 실제로 load-bearing한지
- Claude Code가 왜 좋은 교육용 사례인지

이 장이 다루지 않는 것:

- Claude Code의 모든 하위 시스템 세부
- 특정 모델의 base capability 자체
- 구현 레벨 benchmark 절차 전부

이 장은 이 책 전체의 문제 설정 장이다. 자세한 context/tool/execution/safety/evaluation 논의는 이후 파트에서 각각 확장한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/main.tsx`
- `src/screens/REPL.tsx`
- `src/query.ts`
- `src/QueryEngine.ts`
- `src/Task.ts`
- `src/utils/sessionStorage.ts`

외부 프레이밍:

- Anthropic, [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents), 2024-12-19
- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24

함께 읽으면 좋은 장:

- [02-workflows-agents-runtimes-and-harnesses.md](02-workflows-agents-runtimes-and-harnesses.md)
- [../context/01-context-as-an-operational-resource.md](../03-context-and-control/01-context-as-an-operational-resource.md)
- [../execution/01-ui-transcripts-and-operator-control.md](../04-interfaces-and-operator-surfaces/05-ui-transcripts-and-operator-control.md)
- [../evaluation/01-model-evals-vs-harness-evals.md](../07-evaluation-and-synthesis/01-model-evals-vs-harness-evals.md)

## 왜 별도 설계 영역인가

하네스를 별도 설계 영역으로 봐야 하는 이유는 모델 호출이 실제 제품 성능의 충분조건이 아니기 때문이다. coding agent 제품은 최소한 다음 질문에 답해야 한다.

1. 세션은 어떤 조건 아래에서 열리는가
2. 모델은 무엇을 보고 무엇을 할 수 있는가
3. 사람이 언제 개입하고 언제 시스템이 계속 이어 가는가
4. 세션이 끊기면 무엇이 남고 어떻게 복구되는가
5. run이 끝나면 무엇을 측정하고 비교할 수 있는가

이 다섯 질문은 prompt engineering만으로는 풀리지 않는다. runtime topology, operator surface, permission policy, persistence substrate, evaluation artifact가 모두 필요하다. 그래서 하네스는 모델 호출의 주변부가 아니라, 모델 호출이 성능을 낼 수 있게 만드는 load-bearing layer다.

## 모델 wrapper와 운영 시스템의 차이

| 질문 | 단순 wrapper의 답 | 하네스 엔지니어링의 답 |
| --- | --- | --- |
| 입력을 어떻게 만들까 | prompt template | context seed, overlay, compaction, recovery |
| 모델이 무엇을 할까 | completion 생성 | tool use, permission, task orchestration |
| 사람이 어떻게 개입할까 | 없음 또는 단일 stop | transcript, approval, backgrounding, mode switch |
| 실패 후 어떻게 이어 갈까 | 재시도 | resume, transcript, worktree, restore state |
| 무엇을 측정할까 | final text quality | turn count, cost, denial, transcript, diagnostics |

이 표는 하네스가 단순 wrapper보다 훨씬 넓은 문제를 푼다는 점을 압축한다. production coding harness에서는 오른쪽 열이 제품 경험을 더 많이 좌우한다.

## Claude Code 사례가 좋은 이유

### 1. operator surface가 load-bearing하다

`src/screens/REPL.tsx`는 단순 terminal renderer가 아니라 prompt/transcript mode, permission queue, background task, viewed task, remote session, agent definition을 한 surface에서 다룬다. 즉, 사람과 시스템이 만나는 층이 별도 설계 영역으로 드러난다.

### 2. long-running continuity가 first-class다

`src/query.ts`, `src/utils/sessionStorage.ts`, `src/utils/sessionRestore.ts`는 compaction, transcript, resume, restored worktree/state를 통해 continuity 문제를 직접 다룬다. 이는 "답변 하나 생성"보다 "작업을 이어 가는 것"이 더 중요한 harness 세계를 보여 준다.

### 3. permission과 trust가 모델 바깥에 있다

`src/interactiveHelpers.tsx`와 `utils/permissions/*`는 trust dialog, bypass gate, ask/deny/allow ordering을 다룬다. 모델이 똑똑하다고 해서 이 문제가 사라지지 않으며, 오히려 자율성이 커질수록 더 중요한 설계 영역이 된다.

### 4. evaluation artifact가 제품 안에 있다

`src/QueryEngine.ts`, `src/cost-tracker.ts`, `src/services/api/logging.ts`, transcript chain은 run-level outcome을 남긴다. 즉, 하네스는 실행만 하는 것이 아니라 자신의 성능을 다시 읽게 만드는 증거도 생산한다.

## 대표 코드 절단면

다음 절단면은 하네스 엔지니어링이 왜 prompt 바깥의 문제인지 직관적으로 보여 준다.

```ts
for await (const event of query({
  messages: messagesIncludingNewMessages,
  systemPrompt,
  userContext,
  systemContext,
  canUseTool,
  toolUseContext,
  querySource: getQuerySourceForREPL()
})) {
  onQueryEvent(event)
}
```

```ts
export type TaskStateBase = {
  id: string
  type: TaskType
  status: TaskStatus
  description: string
  outputFile: string
  outputOffset: number
  notified: boolean
}
```

첫 번째 코드 절단면은 모델 호출이 operator-facing loop 안에 놓여 있다는 점을 보여 준다. 두 번째는 long-running execution이 process handle이 아니라 task artifact로 모델링된다는 점을 보여 준다. 둘 다 "좋은 프롬프트를 쓰면 된다"는 설명으로는 포착되지 않는다.

## 하네스가 다루는 대표 trade-off

하네스 엔지니어링이 별도 설계 영역이라는 말은, 별도의 trade-off 집합이 있다는 뜻이기도 하다.

- autonomy vs oversight  
  더 오래 자율적으로 일하게 만들수록 더 정교한 approval과 trust 설계가 필요하다.
- continuity vs simplicity  
  resume, transcript, task artifact를 강화할수록 상태 공간은 복잡해진다.
- observability vs noise  
  transcript와 telemetry를 늘릴수록 분석은 쉬워지지만 operator 부담도 커진다.
- flexibility vs reproducibility  
  feature gate와 dynamic config를 넓힐수록 benchmark drift를 통제하기 어려워진다.

이 trade-off를 모델 품질의 일부로 오해하면, 문제의 귀속점이 계속 흐려진다.

## 하네스 실패는 모델 실패와 다르다

대표적인 harness failure는 이런 것들이다.

- 모델은 충분하지만 permission policy가 과하게 막아서 일이 진행되지 않는다.
- 모델은 충분하지만 transcript/resume contract가 약해 긴 작업 continuity가 무너진다.
- 모델은 충분하지만 operator surface가 상태를 잘 드러내지 못해 사용자가 개입할 타이밍을 놓친다.
- 모델은 충분하지만 evaluation artifact가 빈약해 개선 루프가 닫히지 않는다.

이 실패들은 모델 eval 점수만으로는 거의 보이지 않는다. 하네스 엔지니어링을 별도 설계 영역으로 봐야 하는 이유가 바로 여기에 있다.

## self-evaluation은 별도 하네스 문제다

Anthropic의 [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) (2026-03-24)는 long-running coding harness의 실패를 단순한 base model capability 부족으로만 읽지 않는다. 특히 agent가 자기 산출물을 스스로 평가할 때 나타나는 관대함은 별도 failure mode로 취급된다. subjective task에서는 이 문제가 더 쉽게 드러나지만, verifiable task에서도 "문제가 있긴 하지만 승인해도 되겠다"는 식의 lenient judgment가 남을 수 있다.

이 관점이 중요한 이유는, 여기서 실패의 귀속점이 다시 바뀌기 때문이다.

- generator는 산출물을 만든다.
- evaluator는 산출물과 실행 과정을 판정한다.
- 둘을 같은 persona에 맡기면 self-grading leniency가 생기기 쉽다.

즉 evaluation은 결과를 나중에 채점하는 부속 절차가 아니라, 실행 도중의 judgment quality를 보정하는 scaffold가 될 수 있다.

## 외부 evaluator는 왜 load-bearing scaffold가 되는가

위 글의 핵심 교훈 중 하나는 evaluator가 항상 필요한 것은 아니지만, 필요한 순간에는 매우 load-bearing하다는 점이다. planner, generator, evaluator를 분리하면 각각 다른 실패를 줄일 수 있다.

- planner는 under-scoping과 premature implementation을 줄인다.
- generator는 실제 build를 수행한다.
- evaluator는 spec drift, self-justification, shallow QA를 줄인다.

여기서 중요한 것은 evaluator를 단순 reviewer avatar로 두는 것이 아니라, criteria, threshold, contract를 가진 별도 실행 surface로 다루는 일이다. 특히 모델이 raw capability만으로는 안정적으로 넘지 못하는 경계 근처에서는, skeptical evaluator가 cost 이상의 lift를 주는 경우가 있다. 반대로 모델이 충분히 좋아져 그 경계가 이동하면, evaluator나 sprint scaffold 일부는 과잉 복잡도가 될 수 있다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 operator surface, continuity, permission, evaluation artifact를 codebase 안에 직접 드러낸다.
- long-running coding harness의 핵심 문제는 모델 호출 안보다 바깥에 더 많이 있다.
- run-level success는 prompt, tool, policy, UI, persistence의 조합 결과다.

원칙:

- 모델 호출 바깥의 load-bearing decision을 별도 설계 대상으로 다뤄야 한다.
- continuity와 oversight가 중요한 제품일수록 harness engineering 비중이 커진다.
- evaluation artifact는 구현 마지막에 덧붙이는 것이 아니라, 설계 초반부터 함께 계획해야 한다.
- self-evaluation failure는 별도 harness failure mode로 취급하는 편이 낫다.

해석:

- Anthropic의 agent/harness 글이 말하는 workflow, scaffold, handoff, eval 문제는 Claude Code에서 하나의 운영 시스템으로 만나고 있다.
- 하네스 엔지니어링을 별도 분야로 보지 않으면, 실제 제품 문제의 절반 이상이 "모델이 왜 이랬지?"로 잘못 번역된다.
- evaluator-driven loop는 evaluation을 사후 판정이 아니라 실행 제어 구조로 끌어올린다.

권고:

- 새로운 coding harness를 설계할 때는 모델 호출 diagram보다 먼저 operator surface, permission boundary, transcript/resume, task artifact를 그려 보라.
- 모델 품질 개선과 harness 구조 개선을 같은 backlog에 섞지 말고 귀속점을 따로 적어라.
- "이 기능은 모델 바깥에서만 해결 가능하다"는 질문을 설계 초기에 명시적으로 던져라.
- self-grading failure 사례를 따로 수집하고, generator와 evaluator의 artifact를 섞지 말라.

## benchmark 질문

1. 이 시스템에서 모델 호출 바깥의 load-bearing decision은 무엇인가.
2. operator surface, permission boundary, continuity substrate를 각각 설명할 수 있는가.
3. 모델 성능이 같아도 harness 구조 때문에 결과가 달라질 수 있음을 artifact로 보여 줄 수 있는가.
4. 개선 루프를 닫기 위한 transcript/outcome evidence가 제품 안에 있는가.

## 요약

하네스 엔지니어링은 프롬프트 작성술이 아니라 운영 시스템 설계다. Claude Code 사례는 operator surface, continuity, permissions, evaluation artifact가 실제 성능을 좌우한다는 사실을 한 저장소 안에서 선명하게 보여 준다. 이 책의 나머지 장은 바로 그 구조를 분해해 읽는 작업이다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/screens/REPL.tsx`
   operator surface가 왜 load-bearing한지 먼저 본다.
2. `src/query.ts`와 `src/QueryEngine.ts`
   모델 호출이 어떤 control plane 안에 놓이는지 확인한다.
3. `src/Task.ts`
   long-running execution이 어떤 artifact model을 가지는지 본다.
4. `src/utils/sessionStorage.ts`
   continuity substrate를 확인한다.
5. `src/utils/permissions/permissions.ts`
   자율성과 감독의 경계가 어디서 생기는지 본다.
