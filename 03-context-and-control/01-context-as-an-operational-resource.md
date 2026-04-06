# 01. context는 프롬프트가 아니라 운영 자원이다

## 장 요약

이 책에서 context는 "모델에게 넘기는 텍스트"보다 더 넓은 개념이다. Claude Code의 실제 구현을 보면 context는 conversation 동안 캐시되고, turn 시작 시 다시 조립되며, query loop 안에서 토큰 예산과 compaction 정책에 따라 계속 재배치된다. 따라서 하네스 설계자가 물어야 할 핵심은 "무슨 문장을 넣을까"보다 "무엇을 어떤 lifetime으로 들고 있고, 압력이 오면 무엇을 줄이며, 세션 경계를 넘을 때 무엇을 외부화할까"에 가깝다. 이때 context는 품질 자원일 뿐 아니라 latency, cache hit, token spend를 좌우하는 경제 자원이기도 하다.

## 범위와 비범위

이 장이 다루는 것:

- `src/context.ts`가 system/user context를 어떻게 conversation-scoped seed로 만든는가
- `src/screens/REPL.tsx`와 `src/QueryEngine.ts`가 turn 시작마다 context를 어떻게 다시 조립하는가
- `src/query.ts`가 `messagesForQuery`를 어떤 압력 제어 단계 아래서 계속 바꾸는가
- context를 prompt 작성 기술이 아니라 budget, ownership, recovery가 있는 운영 자원으로 읽어야 하는 이유

이 장이 다루지 않는 것:

- retrieval ranking이나 search quality 자체의 세부 알고리즘
- memory 파일의 taxonomy와 auto-memory 작성 규칙의 상세 설계
- tool surface와 permission 정책의 세부 계약

위 세 주제는 각각 [03-compaction-memory-and-handoff-artifacts.md](03-compaction-memory-and-handoff-artifacts.md), [../interfaces/01-tool-contracts-and-the-agent-computer-interface.md](../04-interfaces-and-operator-surfaces/01-tool-contracts-and-the-agent-computer-interface.md), [../safety/02-sandboxing-permissions-and-policy-surfaces.md](../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md)에서 더 깊게 다룬다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/context.ts`
- `src/query.ts`
- `src/query/config.ts`
- `src/QueryEngine.ts`
- `src/screens/REPL.tsx`
- `src/services/compact/autoCompact.ts`

외부 프레이밍:

- Anthropic, [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), 2025-09-29
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Anthropic Docs, [Prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching), verified 2026-04-06
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

함께 읽으면 좋은 장:

- [../05-context-assembly-and-query-pipeline.md](05-claude-code-context-assembly-and-query-pipeline.md)
- [../06-query-engine-and-turn-lifecycle.md](06-claude-code-query-engine-and-turn-lifecycle.md)
- [../execution/03-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md)
- [../appendix/references.md](../00-front-matter/03-references.md)

Sources / evidence notes:
이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S4`, `S6`, `S33`을 따른다.

## 왜 "운영 자원"이라고 불러야 하는가

프롬프트 관점은 보통 문장 구성과 지시 품질에 초점을 둔다. 하지만 Claude Code 같은 장기 실행형 하네스에서는 context가 다음 네 질문에 동시에 답해야 한다.

1. 무엇이 지금 turn에 필요한가
2. 무엇은 conversation 전체 동안 유지해야 하는가
3. 토큰 압력이 생기면 무엇을 줄이거나 외부화할 것인가
4. 세션이 끊기거나 owner가 바뀌면 무엇을 다시 불러와야 하는가

이 네 질문은 모두 텍스트 품질이 아니라 자원 관리 문제다. 그래서 context engineering은 prompt authoring의 하위 작업이 아니라 runtime design의 일부가 된다.

같은 이유로 context는 경제 자원이기도 하다. Anthropic의 prompt caching 문서는 안정적인 prompt prefix를 재사용하면 처리 시간과 비용을 줄일 수 있고, 이 방식이 긴 multi-turn conversation에도 특히 유용하다고 설명한다. 같은 문서에서 cache read는 base input token보다 훨씬 저렴하고, cache write는 별도 가격 계층을 가진다고 밝힌다. 여기서 중요한 일반 원칙은 숫자 자체보다 구조다.

- conversation-scoped seed가 안정적일수록 cacheable prefix를 만들기 쉽다.
- query-scoped churn이 많을수록 cache hit가 줄고 context economics가 나빠진다.
- context engineering은 무엇을 넣을지뿐 아니라 어떤 부분을 안정적으로 유지해 reuse할지까지 설계해야 한다.

## Claude Code에서 context가 형성되는 세 단계

### 1. conversation-scoped seed를 만든다

`src/context.ts`는 system/user context를 한 번 계산해 conversation 동안 재사용한다. 이 구조는 "prompt를 매 turn 처음부터 새로 짠다"가 아니라, 상대적으로 안정적인 seed를 먼저 고정한다는 뜻이다.

```ts
export const getSystemContext = memoize(async (): Promise<{ [k: string]: string }> => {
  const gitStatus =
    isEnvTruthy(process.env.CLAUDE_CODE_REMOTE) ||
    !shouldIncludeGitInstructions()
      ? null
      : await getGitStatus()

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

여기서 중요한 점은 seed 자체가 이미 운영 정책을 포함한다는 것이다.

- remote 환경에서는 git status를 빼서 불필요한 I/O와 stale snapshot 비용을 줄인다.
- `--bare`나 memory disable 조건에서는 `CLAUDE.md` 탐색을 건너뛴다.
- user context에는 프로젝트 규칙뿐 아니라 날짜 같은 runtime-sensitive 정보가 함께 들어간다.

즉, context는 "사용자 입력 앞에 붙는 글"이 아니라 환경과 정책에 따라 계산되는 conversation seed다.

### 2. turn 시작마다 다시 조립한다

seed가 있다고 해서 모든 turn이 같은 context를 쓰는 것은 아니다. REPL과 QueryEngine은 turn 시작 시점에 system prompt, user context, system context를 다시 합쳐 query 입력을 만든다.

```ts
const [defaultSystemPrompt, baseUserContext, systemContext] = await Promise.all([
  getSystemPrompt(...),
  getUserContext(),
  getSystemContext(),
])
const userContext = {
  ...baseUserContext,
  ...getCoordinatorUserContext(...),
  ...(proactiveModule?.isProactiveActive() && !terminalFocusRef.current
    ? { terminalFocus: 'The terminal is unfocused — the user is not actively watching.' }
    : {}),
}
```

REPL 경로는 여기에 coordinator overlay와 terminal focus 신호를 더한다. 반면 `src/QueryEngine.ts`는 headless/SDK path에서 `fetchSystemPromptParts()`를 통해 기본 조각을 가져오고, 필요하면 memory mechanics prompt까지 추가한다. 같은 제품이라도 owner가 REPL인지 SDK인지에 따라 같은 context seed가 다른 조립 규칙 아래 쓰인다는 뜻이다.

### 3. query loop 안에서 계속 압력 제어를 건다

turn이 시작된 뒤에도 context는 고정되지 않는다. `src/query.ts`는 compact boundary 뒤의 메시지를 잘라 시작한 뒤, tool result budget, snip, microcompact, auto-compact 단계를 차례로 거친다.

```ts
let messagesForQuery = [...getMessagesAfterCompactBoundary(messages)]

messagesForQuery = await applyToolResultBudget(
  messagesForQuery,
  toolUseContext.contentReplacementState,
  persistReplacements ? records => void recordContentReplacement(records, toolUseContext.agentId) : undefined,
  ...
)

const microcompactResult = await deps.microcompact(
  messagesForQuery,
  toolUseContext,
  querySource,
)
messagesForQuery = microcompactResult.messages
```

이 파이프라인은 두 가지를 보여 준다.

- context의 기본 단위는 "문자열 한 덩어리"가 아니라 `messagesForQuery` 같은 mutable working set이다.
- budget pressure는 예외 상황에서만 개입하는 안전장치가 아니라 정상 경로의 일부다.

## query-time snapshot과 working set을 분리하는 이유

`src/query/config.ts`는 query 시작 시점에 변하지 않아야 할 값을 `QueryConfig`로 snapshot한다. session ID와 env/statsig gate가 여기에 들어가고, 반대로 feature-gated branching은 tree-shaking 때문에 loop 안에 그대로 남겨 둔다.

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

이 분리는 context를 운영 자원으로 읽게 만드는 핵심 단서다. 좋은 하네스는 "계속 바뀌는 것"과 "turn 동안 고정되어야 하는 것"을 같은 객체에 뒤섞지 않는다. immutable snapshot이 있어야 loop는 재진입 가능하고, 이후 recovery 설명도 일관성을 갖는다.

경제 관점에서도 이 분리는 중요하다. cacheable prefix 후보는 conversation-scoped seed와 비교적 안정적인 snapshot 쪽에 가깝고, 매 iteration마다 churn하는 working set은 비용과 latency의 변동 원인에 가깝다. 즉 cache, budget, compaction은 모두 context architecture의 부산물이 아니라 핵심 설계 결과다.

## 압력 제어는 context engineering의 일부다

많은 문서가 compaction을 비상 탈출구처럼 다루지만, Claude Code는 그렇게 읽히지 않는다. `src/services/compact/autoCompact.ts`는 먼저 session memory compaction을 시도하고, 실패하면 legacy compaction으로 넘어간다.

```ts
const sessionMemoryResult = await trySessionMemoryCompaction(
  messages,
  toolUseContext.agentId,
  recompactionInfo.autoCompactThreshold,
)
...
const compactionResult = await compactConversation(
  messages,
  toolUseContext,
  cacheSafeParams,
  true,
  undefined,
  true,
  recompactionInfo,
)
```

여기서 중요한 것은 "압력이 생기면 줄인다"가 아니라 "줄이는 방법도 여러 층이고, 그 결과를 다음 loop가 바로 소비한다"는 점이다. 즉 context engineering은 retrieval, summarization, history pruning, tool-result replacement, transcript persistence를 함께 묶는 운영 문제다.

## 관찰, 원칙, 해석, 권고

관찰:

- system/user context는 `memoize`로 conversation-scoped seed를 만들고, REPL/QueryEngine은 turn entry에서 이를 다시 조립한다.
- query loop는 compact boundary 이후의 working set을 기준으로 tool-result replacement, microcompact, auto-compact를 순차 적용한다.
- 같은 제품 안에서도 REPL path와 SDK path는 owner가 달라 context overlay가 다르다.
- prompt caching 관점에서 보면 stable prefix와 high-churn working set이 분리되어야 context economics를 설명할 수 있다.

원칙:

- context 정책은 반드시 owner, lifetime, pressure path를 함께 정의해야 한다.
- "무엇을 넣을까"보다 "무엇을 언제 갱신하고 언제 버릴까"를 먼저 설계해야 한다.
- recovery를 고려하는 하네스라면 query-time working set과 durable artifact를 분리해야 한다.

해석:

- Claude Code의 context layer는 prompt assembly 서브루틴이 아니라 scheduling layer와 강하게 연결된 control subsystem이다.
- Anthropic의 context engineering 글이 말하는 finite resource 관점은 이 코드베이스에서 추상적 비유가 아니라 실제 구현 원리로 확인된다.
- prompt caching 문서가 말하는 time/cost 절감은 Claude Code 같은 하네스에서 "어떤 context를 안정적으로 유지할 것인가"라는 설계 문제로 다시 돌아온다.

권고:

- 새 하네스를 설계할 때는 context를 최소한 seed, overlay, working set, durable artifact 네 층으로 나눠 inventory를 만들어 보라.
- context 압력 제어를 나중에 붙이는 최적화로 취급하지 말고, 처음부터 query loop 설계의 일부로 포함하라.
- REPL, SDK, background agent처럼 owner가 다른 경로가 있다면 어떤 overlay가 각 경로에만 붙는지 문서화하라.
- cache hit, compaction 빈도, continuation 수를 별도 지표로 두고 context economics를 관찰하라.

## benchmark 질문

1. 이 시스템은 context를 immutable seed와 mutable working set으로 구분하는가.
2. context 조립은 turn entry에서 다시 수행되는가, 아니면 오래된 문자열을 재사용하는가.
3. tool 결과, compaction, transcript persistence가 모두 같은 context 정책 아래 설명되는가.
4. owner가 바뀔 때 context overlay가 어떻게 달라지는지 코드 수준에서 추적할 수 있는가.

## 요약

Claude Code의 context layer를 제대로 읽으려면 prompt text가 아니라 운영 자원으로 보아야 한다. `src/context.ts`는 seed를 만들고, REPL과 QueryEngine은 turn마다 그것을 다시 조립하며, `src/query.ts`는 압력 제어 아래 working set을 계속 재정렬한다. 이 관점이 잡혀야 이후 장의 class 구분, memory/handoff, stop hook, recovery 논의가 모두 설계 언어로 이어진다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/context.ts`
   system/user context seed가 무엇인지 먼저 본다.
2. `src/screens/REPL.tsx`
   interactive owner가 turn마다 어떤 overlay를 붙이는지 본다.
3. `src/QueryEngine.ts`
   headless owner가 같은 seed를 어떻게 다른 조립 규칙 아래 쓰는지 비교한다.
4. `src/query/config.ts`
   query entry에서 고정되는 값과 loop 안에서 바뀌는 값을 분리해 본다.
5. `src/query.ts`
   `messagesForQuery`가 실제로 어떻게 budget pressure 아래 재배열되는지 추적한다.
6. `src/services/compact/autoCompact.ts`
   압력 제어가 context subsystem의 일부라는 사실을 확인한다.
