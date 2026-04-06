# 06. QueryEngine와 턴 생애주기

## 장 요약

이 장의 목적은 Claude Code의 control loop를 `한 turn 안에서 무슨 일이 일어나는가`와 `여러 turn에 걸쳐 어떤 상태가 유지되는가`라는 두 질문으로 분해해 읽게 만드는 데 있다. 이 관점에서 핵심은 `src/query.ts`와 `src/QueryEngine.ts`를 같은 종류의 코드로 보지 않는 것이다. `src/query.ts`는 한 turn 안의 loop, recovery, continuation을 다루고, `src/QueryEngine.ts`는 여러 turn에 걸쳐 메시지, usage, permission denial, read-file cache 같은 in-memory state를 보존하며 그 loop를 감싼다. transcript는 그 state의 일부라기보다, `QueryEngine`이 별도로 기록 책임을 지는 persistence 산출물에 가깝다.

해석: Claude Code의 제어 구조는 하나의 거대한 loop로 환원되지 않는다. `src/query.ts`는 turn-local control plane이고, `src/QueryEngine.ts`는 conversation-global state owner다. `src/query/stopHooks.ts`는 모델 응답 뒤의 post-model control branch를 담당하고, interactive REPL은 같은 `query()`를 직접 쓰되 `QueryEngine`을 거치지 않는다. 따라서 이 장은 `공유된 turn loop`와 `분리된 state owner`를 구분하는 사례 장이다.

## 원칙: long-running agent의 control loop는 무엇을 분리해야 하는가

원칙: Anthropic의 [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (2025-11-26)는 long-running agent가 discrete session과 context window 사이를 오가며 작업을 이어가야 한다고 설명한다. 이때 중요한 것은 단순히 다음 모델 호출을 만드는 일이 아니라, 이전 상태를 어떻게 보존하고 언제 다음 turn으로 넘어갈지를 관리하는 일이다.

원칙: [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052) (submitted 2026-03-30)는 모델 성능이 weights뿐 아니라 harness code, 즉 무엇을 저장하고 무엇을 다시 제시할지 결정하는 코드에 달려 있다고 말한다.  
해석: 이 장은 그 관점을 Claude Code의 local control loop에 적용한다. `src/QueryEngine.ts`, `src/query.ts`, `src/query/stopHooks.ts`는 모두 "모델 호출 주변의 상태와 전이를 누가 관리하는가"라는 질문의 일부다.

## 이 장의 직접 근거와 범위

### 직접 근거

#### 제품 사실

- `src/QueryEngine.ts`
- `src/query.ts`
- `src/query/stopHooks.ts`
- `src/screens/REPL.tsx`

#### 공개 설계 원칙

- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26

#### 추가 자료

- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), submitted 2026-03-30

이 장의 관찰은 2026-04-01 기준 현재 공개 사본에 한정한다.

### 이 장의 범위

- `QueryEngineConfig`와 `QueryEngine`이 conversation-global state를 어떻게 잡는지
- `submitMessage()`가 turn 시작 전후에 어떤 준비와 축적을 수행하는지
- `src/query.ts`가 turn-local loop에서 어떤 transition과 recovery를 처리하는지
- `src/query/stopHooks.ts`가 post-model control branch로 어떤 역할을 하는지
- REPL path가 같은 `query()`를 공유하면서도 state owner는 다르게 갖는다는 점

### 이 장에서 다루지 않는 것

- `src/context.ts`의 context assembly 자체
- tool contract와 permission 모델 전체
- background task, remote transport, services 계층 전체

이 비범위는 중요하다. context assembly는 [05-context-assembly-and-query-pipeline.md](./05-context-assembly-and-query-pipeline.md), tool surface와 permission은 [08-tool-system-and-permissions.md](./08-tool-system-and-permissions.md)에서 더 자세히 다룬다.

## 이 장의 네 가지 구분

| 구분 | 이 장에서의 의미 |
| --- | --- |
| conversation-global state | 여러 turn에 걸쳐 유지되는 메시지, usage, denial, read-file cache |
| turn-local loop | 한 turn 안에서 모델 호출, recovery, continuation을 조직하는 loop |
| post-model control branch | 모델 응답 뒤에 continuation을 막거나 수정하는 분기 |
| interactive contrast | 같은 loop를 쓰지만 다른 state owner를 가지는 REPL 경로 |

이 장의 핵심은 `conversation-global state`와 `turn-local loop`를 분리해 읽는 데 있다.

## control-loop topology

```mermaid
sequenceDiagram
    participant Caller as SDK/Headless caller
    participant Engine as QueryEngine
    participant Loop as query.ts
    participant Hooks as query/stopHooks.ts
    participant Consumer as SDK stream consumer

    Caller->>Engine: submitMessage(prompt)
    Engine->>Engine: process input\nupdate mutableMessages\npersist accepted transcript
    alt shouldQuery = false
        Engine-->>Consumer: local command / init output
    else shouldQuery = true
        Engine->>Loop: query(...)
        Loop-->>Engine: stream events / messages
        Loop->>Hooks: handleStopHooks(...) when needed
        Hooks-->>Loop: blocking errors / preventContinuation / summary
        Loop-->>Engine: terminal reason + final messages
        Engine->>Engine: update in-memory state /\nusage / denial reporting / persistence
        Engine-->>Consumer: normalized SDK messages + final result
    end
```

제품 사실: `QueryEngine`은 `query()`를 직접 재구현하지 않는다. turn 실행은 `src/query.ts`에 위임하고, 그 앞뒤에서 input 정규화, in-memory state 갱신, transcript persistence, usage 축적, permission denial 보고, 최종 result emission을 담당한다.  
해석: 이 구조는 "한 conversation의 상태 owner"와 "한 turn의 loop"를 의도적으로 분리해 둔 형태다.

## 제품 사실 1: `QueryEngine`은 conversation-global state owner다

출처:

- `src/QueryEngine.ts`

```ts
export type QueryEngineConfig = {
  cwd: string
  tools: Tools
  commands: Command[]
  mcpClients: MCPServerConnection[]
  agents: AgentDefinition[]
  canUseTool: CanUseToolFn
  getAppState: () => AppState
  setAppState: (f: (prev: AppState) => AppState) => void
  initialMessages?: Message[]
  readFileCache: FileStateCache
  ...
}
```

```ts
export class QueryEngine {
  private config: QueryEngineConfig
  private mutableMessages: Message[]
  private abortController: AbortController
  private permissionDenials: SDKPermissionDenial[]
  private totalUsage: NonNullableUsage
  private hasHandledOrphanedPermission = false
  private readFileState: FileStateCache
```

제품 사실: `QueryEngineConfig`는 단순 flag 묶음이 아니라 `cwd`, `tools`, `commands`, `mcpClients`, `agents`, app state getter/setter, read file cache까지 포함한 runtime context bundle이다. `QueryEngine` 인스턴스는 그 위에 `mutableMessages`, `abortController`, `permissionDenials`, `totalUsage`, `readFileState`를 conversation-global state로 쥔다.  
해석: `QueryEngine`은 helper가 아니라, 한 conversation의 수명 주기를 관리하는 상태 owner에 가깝다.

## 제품 사실 2: `submitMessage()`는 turn 시작 전에 입력 정규화와 transcript 안전성을 먼저 챙긴다

출처:

- `src/QueryEngine.ts`

```ts
const {
  messages: messagesFromUserInput,
  shouldQuery,
  allowedTools,
  model: modelFromUserInput,
  resultText,
} = await processUserInput({
  input: prompt,
  mode: 'prompt',
  ...
  querySource: 'sdk',
})
```

```ts
this.mutableMessages.push(...messagesFromUserInput)
const messages = [...this.mutableMessages]
```

```ts
if (persistSession && messagesFromUserInput.length > 0) {
  const transcriptPromise = recordTranscript(messages)
  if (isBareMode()) {
    void transcriptPromise
  } else {
    await transcriptPromise
    ...
  }
}
```

제품 사실: `submitMessage()`는 곧바로 `query()`로 내려가지 않는다. 먼저 user input을 내부 message 형태로 정규화하고, 그 결과를 `mutableMessages`에 반영한 뒤, API 응답이 오기 전에도 transcript를 먼저 기록한다. 또한 `shouldQuery`가 false면 여기서 loop로 내려가지 않고 local output만 반환할 수 있다.  
해석: `QueryEngine`은 turn 시작을 "모델 호출 시작"으로만 보지 않는다. 입력이 수용된 순간의 in-memory state와 persistence 지점을 먼저 만든 뒤, 필요한 경우에만 loop를 시작한다.

이 ordering은 long-running harness 관점에서 중요하다. 프로세스가 응답 전에 중단되어도, 최소한 accepted user input 지점까지는 resume 가능한 상태를 남기려 하기 때문이다.

## 제품 사실 3: `QueryEngine`은 query loop를 감싸되, 권한 보고와 결과 정규화를 자기 층에서 수행한다

출처:

- `src/QueryEngine.ts`

```ts
const wrappedCanUseTool: CanUseToolFn = async (...) => {
  const result = await canUseTool(...)
  if (result.behavior !== 'allow') {
    this.permissionDenials.push({
      tool_name: sdkCompatToolName(tool.name),
      tool_use_id: toolUseID,
      tool_input: input,
    })
  }
  return result
}
```

```ts
for await (const message of query({
  messages,
  systemPrompt,
  userContext,
  systemContext,
  canUseTool: wrappedCanUseTool,
  toolUseContext: processUserInputContext,
  fallbackModel,
  querySource: 'sdk',
  maxTurns,
  taskBudget,
})) {
```

제품 사실: `QueryEngine`은 `canUseTool`을 직접 감싸 permission denial을 SDK reporting용으로 누적한 뒤, 그 wrapper를 들고 `query()`를 호출한다.  
해석: `src/query.ts`가 turn-local loop를 담당한다 해도, headless/SDK 경로에서 필요한 reporting semantics는 `QueryEngine` 층에서 덧씌워진다.

같은 이유로 `QueryEngine`은 stream을 있는 그대로 흘려보내지 않는다.

```ts
case 'assistant':
  this.mutableMessages.push(message)
  yield* normalizeMessage(message)
  break
...
case 'stream_event':
  if (message.event.type === 'message_stop') {
    this.totalUsage = accumulateUsage(
      this.totalUsage,
      currentMessageUsage,
    )
  }
```

제품 사실: `QueryEngine`은 stream을 소비하면서 `mutableMessages`와 `totalUsage`를 직접 갱신하고, transcript는 별도 record/flush 지점에서 persisted state로 남기며, 외부에는 normalized SDK message 형태로 재노출한다.  
해석: 같은 `query()` loop를 공유하더라도, SDK/headless에서 바깥으로 보이는 life cycle은 `QueryEngine`이 다시 정리한 결과다.

## 제품 사실 4: `src/query.ts`는 turn-local state machine으로 recovery와 continuation을 처리한다

출처:

- `src/query.ts`

```ts
if (lastMessage?.isApiErrorMessage) {
  void executeStopFailureHooks(lastMessage, toolUseContext)
  return { reason: 'completed' }
}

const stopHookResult = yield* handleStopHooks(...)

if (stopHookResult.preventContinuation) {
  return { reason: 'stop_hook_prevented' }
}

if (stopHookResult.blockingErrors.length > 0) {
  ...
  transition: { reason: 'stop_hook_blocking' },
  state = next
  continue
}
```

```ts
const decision = checkTokenBudget(...)
if (decision.action === 'continue') {
  state = {
    messages: [
      ...messagesForQuery,
      ...assistantMessages,
      createUserMessage({
        content: decision.nudgeMessage,
        isMeta: true,
      }),
    ],
    ...
    transition: { reason: 'token_budget_continuation' },
  }
  continue
}
```

제품 사실: `src/query.ts`는 assistant response 뒤에 stop hooks를 돌리고, blocking error가 있으면 그 메시지를 state에 붙여 다시 loop를 계속하며, token budget이 continuation을 요구하면 meta user message를 주입해 다음 iteration으로 넘어간다.  
해석: `src/query.ts`는 단순 "request/response 함수"가 아니라, transition reason을 가진 turn-local state machine에 가깝다.

recovery path도 두껍다.

```ts
if (toolUseContext.abortController.signal.aborted) {
  ...
  return { reason: 'aborted_streaming' }
}
...
if ((isWithheld413 || isWithheldMedia) && reactiveCompact) {
  ...
  state = next
  continue
}
```

제품 사실: abort, prompt-too-long, media-size error, reactive compact retry 같은 recovery path는 정상 종료와 같은 수준의 제어 분기로 존재한다.  
해석: `src/query.ts`의 무게는 "모델을 한 번 더 부른다"는 데 있지 않고, 실패와 continuation을 같은 loop 안에서 흡수하는 데 있다.

## 제품 사실 5: `src/query/stopHooks.ts`는 post-model control branch다

출처:

- `src/query/stopHooks.ts`

```ts
const generator = executeStopHooks(
  permissionMode,
  toolUseContext.abortController.signal,
  undefined,
  stopHookActive ?? false,
  toolUseContext.agentId,
  toolUseContext,
  [...messagesForQuery, ...assistantMessages],
  toolUseContext.agentType,
)
```

```ts
if (result.blockingError) {
  const userMessage = createUserMessage({
    content: getStopHookMessage(result.blockingError),
    isMeta: true,
  })
  blockingErrors.push(userMessage)
  yield userMessage
}
...
if (result.preventContinuation) {
  preventedContinuation = true
  stopReason = result.stopReason || 'Stop hook prevented continuation'
  yield createAttachmentMessage({
    type: 'hook_stopped_continuation',
```

제품 사실: stop hook는 단순 logging이 아니다. post-model phase에서 blocking error를 새 user message로 inject할 수 있고, continuation 자체를 중단시킬 수도 있다.  
해석: 이 장은 `src/query/stopHooks.ts` 전체 중에서도 `handleStopHooks()`의 결과가 다시 `src/query.ts`의 transition에 영향을 주는 부분을 추적한다. 그런 범위에서 보면 `src/query/stopHooks.ts`는 turn-local state machine 안의 control branch다.

이는 `QueryEngine`과의 경계도 분명하게 보여준다. `QueryEngine`은 hook의 내용을 평가하지 않고, hook이 만든 결과를 포함한 turn outcome을 conversation state에 누적한다.

## 제품 사실 6: REPL은 같은 loop를 쓰지만 `QueryEngine`을 거치지 않는다

출처:

- `src/screens/REPL.tsx`

```tsx
const [messages, rawSetMessages] = useState<MessageType[]>(initialMessages ?? []);
const messagesRef = useRef(messages);
const setMessages = useCallback((action: React.SetStateAction<MessageType[]>) => {
  const prev = messagesRef.current;
  const next = typeof action === 'function' ? action(messagesRef.current) : action;
  messagesRef.current = next;
```

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

제품 사실: interactive REPL은 `query()`를 직접 호출하고, 동시에 `messages`/`messagesRef`/`setMessages`로 자체 message state를 관리한다.  
해석: Claude Code는 turn-local loop를 REPL과 SDK/headless 사이에서 공유하지만, 같은 state owner를 쓰지는 않는다. interactive path는 REPL이 자신의 message state를 들고 있고, headless path는 `QueryEngine`이 자신의 in-memory conversation state를 든다.

## control-loop 사례로서의 Claude Code

이 장의 local code만 놓고 보면 Claude Code의 control 구조는 세 층으로 정리할 수 있다.

1. conversation-global state owner  
   `QueryEngine`이 메시지, usage, denial, read file state를 여러 turn에 걸쳐 유지한다.
2. turn-local state machine  
   `src/query.ts`가 recovery, continuation, stop-hook feedback, next-state update를 처리한다.
3. post-model control branch  
   `src/query/stopHooks.ts`가 continuation을 막거나 수정하는 분기를 담당한다.

원칙: long-running agent harness에서 중요한 것은 "한 번의 성공적 응답"보다, 다음 turn으로 어떻게 넘어가고 실패를 어떻게 다시 loop에 넣을지다.  
해석: Claude Code의 local implementation은 그 문제를 `QueryEngine`과 `src/query.ts`의 분리, 그리고 `src/query/stopHooks.ts`의 개입 지점으로 실현한다.

## 점검 질문

- 이 상태는 turn-local인가, conversation-global인가?
- recovery reason과 continuation reason을 명시적으로 구분하고 있는가?
- 모델 응답 뒤의 hook이나 policy 분기를 loop 바깥 부가기능으로 취급하고 있지는 않은가?
- interactive path와 headless path가 같은 loop를 공유하더라도 같은 state owner를 써야 하는가?
- transcript, usage, permission denial 같은 누적 정보는 어느 층에서 책임지는가?

## 마무리

이 장의 결론은 다음과 같다. Claude Code의 control loop는 하나의 함수로 환원되지 않는다. `src/QueryEngine.ts`는 conversation-global state owner이고, `src/query.ts`는 turn-local state machine이며, `src/query/stopHooks.ts`는 post-model control branch다. REPL은 같은 `query()`를 직접 사용하지만 `QueryEngine`을 거치지 않음으로써, `공유된 loop`와 `분리된 state owner`라는 구조를 드러낸다. 따라서 Claude Code의 turn lifecycle은 단순한 API 호출 경로가 아니라, 상태 보존과 회복 분기가 분리된 하네스 제어 구조로 읽는 편이 맞다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/QueryEngine.ts`
   conversation-global state가 무엇을 들고 있는지 먼저 본다.
2. `src/query.ts`
   turn-local state machine과 next-state assembly를 본다.
3. `src/query/stopHooks.ts`
   post-model control branch가 어디서 개입하는지 확인한다.
4. `src/screens/REPL.tsx`
   interactive path가 같은 `query()`를 어떤 state owner 아래서 쓰는지 비교한다.
