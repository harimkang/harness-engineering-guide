# 02. 워크플로, 에이전트, 런타임, 하네스

## 장 요약

하네스 엔지니어링 문서를 읽을 때 가장 먼저 생기는 혼란 중 하나는 `workflow`, `agent`, `runtime`, `harness`, `eval harness`가 같은 말처럼 섞인다는 점이다. 이 장의 목적은 완벽한 사전식 정의를 주는 것이 아니라, 시스템을 읽을 때 어떤 질문을 어디에 던져야 하는지 고정하는 데 있다. Claude Code는 같은 `query()` loop를 공유하면서도 REPL과 QueryEngine의 ownership model이 다르고, task와 permission surface가 별도 artifact로 존재하기 때문에 이 구분을 연습하기 좋은 사례다.

## 범위와 비범위

이 장이 다루는 것:

- workflow, agent, runtime, harness, eval harness의 실용적 구분
- 이 다섯 층을 local artifact에 어떻게 매핑할지
- 같은 시스템을 두고도 왜 다른 층의 언어가 필요한지

이 장이 다루지 않는 것:

- 특정 용어의 유일한 정답 정의
- 외부 SDK 용어와 1:1 대응 표준 확정
- 각 층의 세부 구현 전부

이 장은 foundations의 어휘 정리 장이며, 이후 모든 파트에서 반복 참조하는 좌표계 역할을 한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/query.ts`
- `src/QueryEngine.ts`
- `src/screens/REPL.tsx`
- `src/Tool.ts`
- `src/Task.ts`
- `src/utils/permissions/permissions.ts`

외부 프레이밍:

- Anthropic, [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents), 2024-12-19
- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24

함께 읽으면 좋은 장:

- [01-why-harness-engineering-matters.md](./01-why-harness-engineering-matters.md)
- [03-quality-attributes-of-agent-harnesses.md](./03-quality-attributes-of-agent-harnesses.md)
- [../execution/03-task-orchestration-and-long-running-execution.md](../execution/03-task-orchestration-and-long-running-execution.md)
- [../evaluation/02-tasks-trials-transcripts-and-graders.md](../evaluation/02-tasks-trials-transcripts-and-graders.md)

## 대표 코드 발췌

이 장의 다섯 용어가 추상명사로만 머무르지 않으려면, runtime surface와 state owner가 실제로 어떻게 갈라지는지 먼저 봐야 한다.

```tsx
for await (const event of query({
  messages: messagesIncludingNewMessages,
  systemPrompt,
  userContext,
  systemContext,
  canUseTool,
  toolUseContext,
  querySource: getQuerySourceForREPL()
})) {
  onQueryEvent(event);
}
```

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

첫 번째 발췌는 `src/screens/REPL.tsx`가 interactive runtime에서 `query()`를 붙드는 장면이고, 두 번째 발췌는 `src/QueryEngine.ts`가 headless runtime에서 대화 상태와 usage를 소유하는 장면이다. 이 둘을 함께 봐야 workflow, agent, runtime, harness를 분리해서 읽을 수 있다.

## 용어를 local artifact에 다시 매핑하라

| 용어 | 이 책에서의 실용적 뜻 | Claude Code에서 먼저 볼 곳 |
| --- | --- | --- |
| workflow | 여러 단계와 전이를 특정 순서로 배치한 절차 | startup -> query -> stop hook -> resume 흐름 |
| agent | 다음 행동을 고르고 tool을 쓰는 주체 | `src/query.ts`, `src/QueryEngine.ts` |
| runtime | 그 주체가 실제로 구동되는 owner-facing 환경 | `src/screens/REPL.tsx`, headless QueryEngine, session state |
| harness | workflow + runtime + tools + permissions + memory + operator control을 묶는 운영 시스템 | REPL, permissions, transcript, task, restore를 모두 포함한 전체 |
| eval harness | 위 시스템을 반복 가능하게 비교/채점하기 위한 시험 구조 | transcript/outcome/grader input을 만드는 별도 평가 구조 |

이 표는 언어 게임이 아니라 귀속점 표다. 지금 보고 있는 문제가 절차 문제인지, 주체 문제인지, 실행 환경 문제인지, 전체 운영 구조 문제인지, 평가 구조 문제인지 구분하지 않으면 논의가 금방 뒤섞인다.

## workflow는 순서의 문제다

workflow는 "무엇이 먼저 일어나고 무엇이 다음에 오는가"에 관한 서술이다. 예를 들어 Claude Code의 long-running loop를 workflow로 읽으면 다음 같은 질문이 생긴다.

- query는 언제 시작되는가
- stop hook은 어떤 순서에서 개입하는가
- resume는 어느 시점에서 workflow를 다시 잇는가

workflow 언어는 전이와 순서를 강조한다. 그래서 같은 시스템을 workflow로 읽을 때는 `src/query.ts`의 continue/return 지점, startup trust 이후 initialization 순서, task completion 후 notification 순서가 중요한 evidence가 된다.

## agent는 선택과 tool use의 문제다

agent는 같은 workflow 안에서도 "누가 다음 행동을 결정하는가"를 강조하는 언어다. Claude Code에서 agent라는 말은 주로 `src/query.ts`와 `src/QueryEngine.ts`가 관리하는 sampling/tool-use loop를 가리킨다.

이 층에서 중요한 질문은 다음과 같다.

- agent는 무엇을 context로 보는가
- 어떤 tool contract를 호출할 수 있는가
- 다음 turn continuation은 어떤 규칙 아래 이어지는가

즉 agent language는 절차 전체보다 decision loop에 초점을 둔다.

## runtime은 owner와 surface의 문제다

runtime은 agent loop가 실제로 어떤 환경에서 굴러가는가를 묻는 언어다. Claude Code에서는 REPL runtime과 QueryEngine runtime을 구분하는 것이 중요하다.

- REPL runtime은 operator-facing interactive shell이다.
- QueryEngine runtime은 SDK/headless ownership variant다.

같은 `query()` loop를 공유해도 runtime이 다르면 message persistence, permission handling, transcript visibility, UI coupling이 달라진다. לכן runtime을 agent와 같은 말로 부르면 중요한 설계 차이가 사라진다.

## harness는 그 전체를 묶는 시스템 언어다

harness는 workflow, agent, runtime에 permissions, memory, transcript, task, evaluation artifact까지 얹은 전체 운영 시스템을 가리킨다. Claude Code를 harness로 읽는다는 것은 `src/query.ts`만 보는 것이 아니라, 다음을 함께 보는 것이다.

- operator surface
- task orchestration
- transcript/resume substrate
- permission/trust boundary
- cost/eval artifact

즉 harness는 "모델이 일하는 환경 전체"에 가까운 언어다.

## eval harness는 실행 시스템이 아니라 비교 시스템이다

eval harness는 production harness와 다른 층이다. 이것은 시스템을 반복 가능하게 비교하고 채점하기 위해 task, trial, transcript, outcome, grader를 조직하는 구조다. Claude Code 코드베이스에는 eval harness가 first-class module로 존재하지 않지만, transcript/outcome/trace artifact는 이미 충분히 노출돼 있다.

이 distinction이 중요하다.

- production harness는 사용자가 실제로 일하는 환경이다.
- eval harness는 그 환경을 비교 가능한 trial로 만드는 시험 구조다.

둘을 같은 말처럼 쓰면 문서가 자꾸 "제품 구조"와 "비교 구조"를 혼동하게 된다.

## 흔한 오해

1. workflow와 harness를 같은 것으로 보는 것  
   workflow는 절차이고, harness는 그 절차가 놓이는 전체 운영 시스템이다.
2. agent와 runtime을 같은 것으로 보는 것  
   agent는 decision loop이고, runtime은 그 loop의 owner-facing execution environment다.
3. runtime과 REPL을 같은 것으로 보는 것  
   REPL은 runtime surface 중 하나이며, QueryEngine 같은 다른 runtime variant도 있다.
4. harness와 eval harness를 같은 것으로 보는 것  
   하나는 운영 시스템이고 다른 하나는 비교 시스템이다.

## Claude Code를 이 다섯 층 위에서 읽으면 무엇이 달라지는가

같은 현상도 층을 바꾸면 다른 질문이 된다.

- `/resume`는 workflow로 보면 "어느 단계에서 복귀하는가"의 문제다.
- agent로 보면 "중단된 decision loop를 어떻게 재개하는가"의 문제다.
- runtime으로 보면 "어떤 owner가 restore를 주도하는가"의 문제다.
- harness로 보면 "transcript, worktree, cost state, agent setting을 함께 어떻게 이어 붙이는가"의 문제다.
- eval harness로 보면 "resume 전후 trial을 어떻게 비교 가능한 outcome으로 만들 것인가"의 문제다.

이렇게 층을 나누면 같은 기능을 더 정확하게 설명할 수 있다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 같은 core loop를 여러 ownership surface에서 재사용하므로 용어 구분이 특히 중요하다.
- task, transcript, permissions, cost artifact는 harness와 eval harness를 구분하는 단서가 된다.
- workflow, agent, runtime을 같은 말로 부르면 귀속점이 흐려진다.

원칙:

- 절차를 말할 때는 workflow 언어를, decision loop를 말할 때는 agent 언어를 써야 한다.
- owner와 surface를 설명할 때는 runtime 언어를 써야 한다.
- permissions, memory, operator control까지 묶어 말할 때만 harness라는 단어를 써야 한다.
- 비교 구조를 설계할 때는 eval harness라고 분리해서 불러야 한다.

해석:

- Anthropic의 agent 글과 eval 글을 함께 읽으면, production harness와 eval harness가 서로 다른 문제를 푼다는 사실이 분명해진다.
- Claude Code는 이 둘을 한 codebase 안에서 동시에 관찰하게 해 주는 드문 사례다.

권고:

- 문서를 쓸 때 단락 첫머리에 "지금 나는 어느 층을 설명하는가"를 먼저 자문하라.
- 같은 기능도 workflow/agent/runtime/harness/eval harness 가운데 어느 층에서 보고 있는지 명시하라.
- 팀 내 논의에서 "에이전트가 이걸 못한다"는 표현이 나오면, 그것이 agent 문제인지 runtime/harness 문제인지 재분해하라.

## benchmark 질문

1. 이 시스템에서 workflow, agent, runtime, harness, eval harness를 구분해 설명할 수 있는가.
2. 같은 기능을 서로 다른 층에서 다시 읽을 때 귀속점이 달라지는가.
3. production harness와 eval harness를 혼동하지 않고 각각의 artifact를 적을 수 있는가.
4. owner가 달라질 때 runtime 언어가 실제로 도움이 되는가.

## 요약

이 장의 요점은 다섯 용어를 외우는 데 있지 않다. 더 중요한 것은 시스템을 읽을 때 지금 보고 있는 문제가 절차인지, 주체인지, 실행 환경인지, 전체 운영 구조인지, 비교 구조인지 구분하는 것이다. Claude Code는 그 구분을 실제 code surface로 연습하게 해 주는 사례다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/query.ts`
   agent loop와 workflow transition을 함께 본다.
2. `src/QueryEngine.ts`
   같은 loop가 다른 runtime ownership 아래서 어떻게 쓰이는지 본다.
3. `src/screens/REPL.tsx`
   runtime surface와 operator control을 확인한다.
4. `src/Tool.ts`
   agent가 소비하는 capability contract를 본다.
5. `src/Task.ts`
   harness가 long-running execution object를 어떻게 표상하는지 본다.
6. [../evaluation/02-tasks-trials-transcripts-and-graders.md](../evaluation/02-tasks-trials-transcripts-and-graders.md)
   eval harness 층으로 어떻게 넘어가는지 확인한다.
