# 02. context의 종류, 경계, 스코프

## 장 요약

모든 context를 한 덩어리로 부르면 독해는 쉬워지지만 설계는 곧바로 흐려진다. Claude Code의 실제 구조를 보면 system context, user context, tool context, task context, environment context는 출처도 다르고 owner도 다르며 lifetime도 다르다. 이 장은 그 차이를 분리해, 어떤 정보가 모델에게 보이는 맥락이고 어떤 정보가 owner가 바깥에서 강제하는 실행 조건인지 구별하게 만든다.

## 범위와 비범위

이 장이 다루는 것:

- context를 class별로 나눠야 하는 이유
- 각 class가 어떤 owner와 lifetime을 가지는지
- REPL과 QueryEngine이 같은 query loop를 서로 다른 ownership model 아래 어떻게 감싸는지
- context leakage가 어떤 지점에서 발생하는지

이 장이 다루지 않는 것:

- 개별 tool의 schema 설계 세부
- background task 실행 모델 전반
- sandbox 정책과 approval 정책의 상세 비교

이 세 주제는 [../interfaces/02-tool-shaping-permissions-and-capability-exposure.md](../04-interfaces-and-operator-surfaces/02-tool-shaping-permissions-and-capability-exposure.md), [../execution/03-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md), [../safety/02-sandboxing-permissions-and-policy-surfaces.md](../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md)에서 확장한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/context.ts`
- `src/Tool.ts`
- `src/query/config.ts`
- `src/QueryEngine.ts`
- `src/screens/REPL.tsx`
- `src/Task.ts`
- `src/utils/sessionStorage.ts`

외부 프레이밍:

- Anthropic, [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), 2025-09-29
- Anthropic Platform Docs, [Agent SDK overview](https://platform.claude.com/docs/en/agent-sdk/overview), 확인 2026-04-02
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

함께 읽으면 좋은 장:

- [01-context-as-an-operational-resource.md](01-context-as-an-operational-resource.md)
- [../execution/02-state-resumability-and-session-ownership.md](../05-execution-continuity-and-integrations/01-state-resumability-and-session-ownership.md)
- [../interfaces/01-tool-contracts-and-the-agent-computer-interface.md](../04-interfaces-and-operator-surfaces/01-tool-contracts-and-the-agent-computer-interface.md)
- [../12-task-model-and-background-execution.md](../05-execution-continuity-and-integrations/06-claude-code-task-model-and-background-execution.md)

## 다섯 가지 class를 먼저 구분하라

| class | owner | 대표 구조 | lifetime | 잘못 읽었을 때 생기는 오류 |
| --- | --- | --- | --- | --- |
| system context | conversation owner | `getSystemContext()` | conversation-scoped | runtime gate를 단순 prompt text로 오해 |
| user context | conversation owner + workspace | `getUserContext()` | conversation-scoped | 프로젝트 규칙과 사용자 입력을 혼동 |
| tool context | query owner | `ToolUseContext` | turn-scoped 중심, 일부 thread-scoped | owner-enforced policy와 model-visible context를 혼동 |
| task context | task owner | `TaskStateBase` | task-scoped | 장기 실행 artifact를 대화 메모리처럼 오독 |
| environment context | session/runtime owner | `QueryConfig`, transcript/worktree/session metadata | session-scoped 또는 query-scoped | cwd, permission, remote boundary를 단순 문자열처럼 취급 |

이 표의 요지는 "context의 종류"가 파일 분류가 아니라 ownership 분류라는 점이다. 어떤 정보가 어디에 실려 있는지보다, 누가 그것을 만들고 언제까지 유지하는지가 더 중요하다.
또한 이 다섯 class는 코드에 선언된 공식 enum이 아니라, 분산된 타입과 runtime state를 읽기 쉽게 묶은 분석 프레임이라는 점을 분명히 해 둘 필요가 있다.

## system context와 user context는 conversation seed다

`src/context.ts`에서 system context와 user context는 모두 `memoize()`로 감싼 async factory다. 둘 다 conversation 동안 상대적으로 안정적인 seed이며, 매 turn의 query loop 안에서 직접 mutable하게 바뀌지 않는다.

```ts
export const getSystemContext = memoize(async (): Promise<{ [k: string]: string }> => {
  ...
  return {
    ...(gitStatus && { gitStatus }),
    ...(feature('BREAK_CACHE_COMMAND') && injection
      ? { cacheBreaker: `[CACHE_BREAKER: ${injection}]` }
      : {}),
  }
})
```

```ts
export const getUserContext = memoize(async (): Promise<{ [k: string]: string }> => {
  const claudeMd = shouldDisableClaudeMd
    ? null
    : getClaudeMds(filterInjectedMemoryFiles(await getMemoryFiles()))

  return {
    ...(claudeMd && { claudeMd }),
    currentDate: `Today's date is ${getLocalISODate()}.`,
  }
})
```

여기서 system/user는 "모델이 보는 첫 문맥"이라는 점에서는 비슷하지만, 책임은 다르다.

- system context는 git status나 cache-breaker처럼 하네스 운영자가 통제하는 runtime snapshot에 가깝다.
- user context는 `CLAUDE.md`와 날짜처럼 workspace와 사용자 작업면에 더 가까운 입력이다.

이 둘을 섞어 부르면 나중에 stale context가 발생했을 때 어느 층이 문제인지 설명하기 어렵다.

## tool context는 prompt 일부가 아니라 실행 계약이다

`ToolUseContext`는 단순 helper bag가 아니다. 이 구조는 tool 호출이 어떤 state와 정책 아래 실행되는지 보여 주는 실제 실행 계약이다.

```ts
export type ToolUseContext = {
  ...
  messages: Message[]
  queryTracking?: QueryChainTracking
  requestPrompt?: (...)
  toolUseId?: string
  contentReplacementState?: ContentReplacementState
  renderedSystemPrompt?: SystemPrompt
}
```

이 필드들을 보면 tool context는 적어도 세 층을 동시에 가진다.

- 모델이 방금까지 본 대화(`messages`)
- owner가 실행 중에 강제하는 상호작용 계약(`requestPrompt`, permission context, notification callbacks)
- turn을 넘어 이어지는 thread-local bookkeeping(`queryTracking`, `contentReplacementState`)

따라서 tool context를 system prompt 일부로 부르면 안 된다. 어떤 제약은 모델에게 설명되는 것이 아니라 owner가 바깥에서 강제한다. 이 차이가 흐려지면 permission 정책과 capability exposure를 잘못 문서화하게 된다.

## task context는 장기 실행 단위의 맥락이다

`src/Task.ts`는 task를 conversation 안의 메시지가 아니라 독립된 실행 단위로 모델링한다.

```ts
export type TaskStateBase = {
  id: string
  type: TaskType
  status: TaskStatus
  description: string
  startTime: number
  endTime?: number
  outputFile: string
  outputOffset: number
  notified: boolean
}
```

이 구조는 task context가 "모델이 기억하는 것"이 아니라 "owner가 추적하는 작업 상태"라는 사실을 보여 준다. task의 output file, lifecycle status, notification 여부는 conversation memory와는 전혀 다른 차원의 맥락이다. background execution이나 subagent resume를 설명하려면 이 task-scoped context를 분리해서 읽어야 한다.

## environment context는 문자열이 아니라 실행 위치와 정책의 묶음이다

`src/query/config.ts`는 query entry에서 고정해야 할 environment-sensitive 값을 snapshot으로 만든다.

```ts
export function buildQueryConfig(): QueryConfig {
  return {
    sessionId: getSessionId(),
    gates: {
      streamingToolExecution: checkStatsigFeatureGate_CACHED_MAY_BE_STALE(...),
      emitToolUseSummaries: isEnvTruthy(process.env.CLAUDE_CODE_EMIT_TOOL_USE_SUMMARIES),
      isAnt: process.env.USER_TYPE === 'ant',
      fastModeEnabled: !isEnvTruthy(process.env.CLAUDE_CODE_DISABLE_FAST_MODE),
    },
  }
}
```

`src/utils/sessionStorage.ts`의 transcript path 계산도 같은 종류의 정보를 다룬다.

```ts
export function getTranscriptPath(): string {
  const projectDir = getSessionProjectDir() ?? getProjectDir(getOriginalCwd())
  return join(projectDir, `${getSessionId()}.jsonl`)
}
```

environment context의 핵심은 이것이다. cwd, session ID, feature gate, project directory, remote 여부는 모델이 길게 설명받아야 할 서술문이 아니라 owner가 runtime에서 일관되게 적용해야 하는 상태다.

## REPL과 QueryEngine은 같은 loop를 다른 owner 아래서 감싼다

REPL은 interactive owner다. turn마다 `getSystemPrompt()`, `getUserContext()`, `getSystemContext()`를 불러서 user focus, coordinator overlay 등을 붙이고, 이어서 `query()`를 호출한다. 반면 QueryEngine은 SDK/headless owner로서 `fetchSystemPromptParts()`를 통해 같은 seed를 가져오되, transcript durability와 permission denial reporting을 더 강하게 책임진다.

```ts
const {
  defaultSystemPrompt,
  userContext: baseUserContext,
  systemContext,
} = await fetchSystemPromptParts(...)
const userContext = {
  ...baseUserContext,
  ...getCoordinatorUserContext(...),
}
...
const systemPrompt = asSystemPrompt([
  ...(customPrompt !== undefined ? [customPrompt] : defaultSystemPrompt),
  ...(memoryMechanicsPrompt ? [memoryMechanicsPrompt] : []),
  ...(appendSystemPrompt ? [appendSystemPrompt] : []),
])
```

이 차이는 단지 UI 유무 차이가 아니다. 같은 `query()` loop라도 owner가 바뀌면 어떤 context overlay를 붙이고, 어떤 artifact를 먼저 기록하고, 어떤 resume contract를 보장해야 하는지가 달라진다.

## leakage risk는 class를 섞을 때 생긴다

대표적인 leakage는 세 가지다.

1. environment context를 prompt content와 같은 것으로 부르는 것  
   예: permission mode나 cwd를 모델 서술문과 같은 층으로 설명하는 경우
2. tool context를 system prompt의 일부로 오해하는 것  
   예: owner-enforced policy와 model-visible instruction을 구분하지 않는 경우
3. task context를 conversation memory와 혼동하는 것  
   예: background task output file과 long-lived memory file을 같은 artifact family로 설명하는 경우

이 세 leakage는 모두 ownership 혼동에서 온다. 어떤 state를 누가 소유하는지 먼저 말하지 않으면, context class는 계속 섞인다.

## 관찰, 원칙, 해석, 권고

관찰:

- system/user context는 conversation seed다.
- `ToolUseContext`는 메시지 배열, query tracking, prompt callback, content replacement state를 함께 가지는 실행 계약이다.
- task와 environment는 모델이 "기억"하는 맥락이 아니라 owner가 runtime에서 유지하는 맥락이다.

원칙:

- context 분류의 기준은 정보 종류가 아니라 owner와 lifetime이어야 한다.
- owner-enforced state와 model-visible state를 같은 층으로 설명하지 말아야 한다.
- 같은 query loop를 재사용하더라도 REPL, SDK, subagent는 서로 다른 context class 조합을 갖는다고 가정해야 한다.

해석:

- Anthropic이 말하는 context engineering의 핵심은 더 많은 정보를 넣는 기법이 아니라, 정보의 class와 boundary를 설계하는 작업에 가깝다.
- Claude Code는 이 구분을 타입과 resume artifact 수준에서 드러내기 때문에 교육용 사례로 적합하다.

권고:

- 문서화할 때는 system/user/tool/task/environment를 최소 단위로 나눠 ownership 표를 먼저 만들라.
- permission, cwd, session, worktree, transcript 같은 정보는 prompt content로만 설명하지 말고 owner state로도 함께 문서화하라.
- background agent나 SDK surface가 있는 하네스라면 REPL 기준 분류를 그대로 복사하지 말고 owner별 variant를 별도로 적어라.

## benchmark 질문

1. 이 시스템은 context class를 owner와 lifetime 기준으로 설명할 수 있는가.
2. tool context와 prompt content를 문서상에서 분리해 보여 주는가.
3. task-scoped artifact와 conversation memory를 혼동하지 않는가.
4. REPL/SDK/subagent가 서로 다른 overlay를 가진다는 사실이 코드와 문서 양쪽에서 드러나는가.

## 요약

context class를 구분한다는 것은 label을 붙이는 일이 아니라 ownership model을 세우는 일이다. Claude Code에서는 system/user가 conversation seed를 이루고, tool context가 실행 계약을 담당하며, task/environment context가 장기 실행과 resume를 떠받친다. 이 구분이 서지 않으면 이후 장의 compaction, handoff, permission, task orchestration 설명도 모두 흐려진다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/context.ts`
   system/user seed의 경계를 본다.
2. `src/Tool.ts`
   tool context가 어떤 실행 계약을 품는지 본다.
3. `src/query/config.ts`
   environment snapshot을 어떤 값으로 고정하는지 본다.
4. `src/Task.ts`
   task context가 conversation과 별개의 상태 공간임을 확인한다.
5. `src/screens/REPL.tsx`
   interactive owner의 overlay를 본다.
6. `src/QueryEngine.ts`
   headless owner가 같은 core loop를 어떻게 다른 contract 아래서 쓰는지 비교한다.
7. `src/utils/sessionStorage.ts`
   environment context가 durable artifact로 어떻게 이어지는지 확인한다.
