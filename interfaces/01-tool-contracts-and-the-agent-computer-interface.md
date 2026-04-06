# 01. tool contract와 agent-computer interface

## 장 요약

tool을 함수 모음으로만 보면 agent harness의 핵심을 놓친다. 모델에게 중요한 것은 실제 구현체보다 name, aliases, search hint, description, schema, result shape, interrupt behavior, read-only/destructive semantics처럼 "어떻게 보이고 어떤 규칙 아래 호출되는가"다. Claude Code의 `src/Tool.ts`는 바로 이 점을 드러낸다. 이 장은 tool을 agent-computer interface, 즉 모델이 컴퓨터와 접촉하는 계약 표면으로 읽는다.

## 범위와 비범위

이 장이 다루는 것:

- tool contract를 구성하는 핵심 요소
- `ToolUseContext`가 왜 단순 helper bag이 아닌지
- implementation quality와 contract quality를 왜 구분해야 하는지

이 장이 다루지 않는 것:

- 개별 tool 구현의 내부 알고리즘 전부
- permission pipeline 전체
- command/skill/plugin/MCP 조합 구조의 전체

이 장은 interfaces 파트의 기초 장이며, [02-tool-shaping-permissions-and-capability-exposure.md](./02-tool-shaping-permissions-and-capability-exposure.md), [03-commands-skills-plugins-and-mcp.md](./03-commands-skills-plugins-and-mcp.md)에서 이어진다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/Tool.ts`
- `src/query.ts`
- `src/utils/permissions/permissions.ts`
- `src/tools/ToolSearchTool/ToolSearchTool.ts`

외부 프레이밍:

- Anthropic, [Writing effective tools for agents — with agents](https://www.anthropic.com/engineering/writing-tools-for-agents), 2025-09-11
- Anthropic, [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system), 2025-06-13
- Anthropic Platform Docs, [Agent SDK overview](https://platform.claude.com/docs/en/agent-sdk/overview), 확인 2026-04-02

함께 읽으면 좋은 장:

- [../context/02-context-classes-boundaries-and-scopes.md](../context/02-context-classes-boundaries-and-scopes.md)
- [../execution/04-human-oversight-trust-and-approval.md](../execution/04-human-oversight-trust-and-approval.md)
- [04-benchmarking-tool-surfaces.md](./04-benchmarking-tool-surfaces.md)

## tool contract는 무엇으로 이뤄지는가

`Tool<T>` 타입을 보면 Claude Code가 tool을 단순 function pointer로 보지 않는다는 사실이 분명해진다.

```ts
export type Tool<...> = {
  aliases?: string[]
  searchHint?: string
  call(...)
  description(...)
  readonly inputSchema: Input
  inputJSONSchema?: ToolInputJSONSchema
  outputSchema?: z.ZodType<unknown>
  inputsEquivalent?(...)
  isConcurrencySafe(...)
  isEnabled()
  isReadOnly(...)
  isDestructive?(...)
  interruptBehavior?(): 'cancel' | 'block'
  ...
}
```

이 contract를 보면 최소한 일곱 가지 층이 보인다.

1. 식별성  
   `name`, `aliases`, `userFacingName`
2. 발견 가능성  
   `searchHint`, `description`
3. 입력 경계  
   `inputSchema`, `inputJSONSchema`
4. 출력 재사용성  
   `outputSchema`, result shape
5. 실행 특성  
   concurrency safety, read-only, destructive, interrupt behavior
6. operator semantics  
   permission prompt, collapse behavior, progress behavior
7. runtime coupling  
   어떤 context 아래 call이 실행되는가

이 층을 모두 합쳐야 비로소 tool이 "모델이 안정적으로 호출할 수 있는 capability"가 된다.

## ToolUseContext는 ACI의 절반이다

도구가 contract의 한쪽 면이라면, `ToolUseContext`는 다른 쪽 면이다. 이 타입은 모델이 컴퓨터와 접촉할 때 어떤 세션 상태와 infrastructure를 같이 건드릴 수 있는지 보여 준다.

```ts
export type ToolUseContext = {
  options: {
    commands: Command[]
    tools: Tools
    mcpClients: MCPServerConnection[]
    mcpResources: Record<string, ServerResource[]>
    mainLoopModel: string
    thinkingConfig: ThinkingConfig
    ...
  }
  abortController: AbortController
  readFileState: FileStateCache
  getAppState(): AppState
  setAppState(...)
  handleElicitation?(...)
  appendSystemMessage?(...)
  addNotification?(...)
  ...
}
```

이 구조는 tool call이 단순 RPC가 아니라는 점을 보여 준다.

- tool은 세션의 현재 command surface와 tool pool을 안다.
- tool은 app state와 notification surface에 접근한다.
- tool은 abort, elicitation, UI-only system message append 같은 side-channel을 가진다.

따라서 ACI를 논할 때 input/output schema만 보면 절반만 본 셈이다. 어떤 context 아래서 호출되는지도 계약의 일부다.

## 왜 구현보다 contract가 먼저인가

좋은 implementation이 항상 좋은 tool surface를 보장하지는 않는다. 모델은 함수 본문을 읽지 않고, name/description/schema/result shape를 바탕으로 선택한다. 그래서 contract quality가 낮으면 implementation quality가 높아도 실제 사용성은 낮다.

대표적인 실패는 다음과 같다.

- name이 다른데 의미가 겹친다
- description이 "무엇을 하는가"만 말하고 "언제 써야 하는가"를 안 말한다
- input schema는 있지만 output reuse expectation이 없다
- read-only/destructive semantics가 contract 밖에 흩어져 있다

이 네 실패는 모두 ACI failure다. 사람은 좋은 도구가 있다고 믿지만 모델은 그것을 안정적으로 선택하지 못한다.

## discoverability는 별도 surface가 필요하다

Claude Code는 deferred tool surface를 위한 `ToolSearchTool`도 별도로 둔다. 이 도구는 search query, exact match, MCP-prefix match, keyword scoring을 통해 모델이 "지금 보이지 않는 capability"를 다시 찾게 한다.

```ts
export const inputSchema = ...({
  query: z.string().describe(
    'Query to find deferred tools. Use "select:<tool_name>" for direct selection, or keywords to search.'
  ),
  max_results: z.number().optional().default(5)
})
```

즉 ACI는 현재 로드된 tool 목록만이 아니라, deferred capability를 어떻게 다시 discover하게 할 것인가까지 포함한다. production harness에서 discoverability가 중요한 이유가 여기에 있다.

## ACI 관점에서 tool result를 봐야 하는 이유

tool result는 "작업이 끝났다"는 신호만이 아니라 다음 turn이 consume할 artifact다. oversized result 처리, collapse summary, permission decision, re-run path 모두 이 result shape에 의존한다. 이 점을 놓치면 tool을 execution primitive로만 보게 되고, agent-computer interface라는 본질을 놓친다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code의 tool contract는 aliases, search hint, schema, metadata, interrupt semantics까지 포함한다.
- `ToolUseContext`는 tool call이 session infrastructure와 어떻게 연결되는지 보여 준다.
- deferred tool discoverability는 별도 surface로 보강된다.

원칙:

- tool surface는 implementation보다 contract부터 설계해야 한다.
- input/output schema만이 아니라 execution semantics도 contract 일부로 드러내야 한다.
- discoverability를 별도 문제로 다뤄야 한다.

해석:

- Anthropic이 말하는 tool quality는 이 코드베이스에서 단순 prompt text가 아니라 strongly-shaped contract로 구체화된다.
- Claude Code의 ACI는 모델이 컴퓨터를 "기능 집합"이 아니라 "계약된 surface"로 접하게 만든다.

권고:

- 새 tool을 만들 때는 함수 본문보다 먼저 `이름`, `언제 써야 하는지`, `실패 시 어떻게 보일지`, `중단 시 어떻게 처리할지`를 적어라.
- tool review checklist에 aliases/search hint/interrupt behavior를 포함하라.
- deferred capability가 있다면 discoverability surface를 별도 설계하라.

## benchmark 질문

1. 이 tool surface는 모델이 실제로 선택하기 좋은 계약 형식인가.
2. execution semantics가 contract 밖의 암묵지로 남아 있지 않은가.
3. discoverability와 deferred capability 문제가 별도 surface로 다뤄지는가.
4. ToolUseContext가 너무 두꺼워 contract를 흐리게 만들고 있지는 않은가.

## 요약

tool은 함수가 아니라 계약이다. Claude Code는 `src/Tool.ts`와 `ToolUseContext`, `ToolSearchTool`을 통해 모델이 컴퓨터와 만나는 표면을 두껍게 설계한다. 이 관점이 있어야 permission, MCP, skill, deferred tool surface까지 같은 언어로 읽을 수 있다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/Tool.ts`
   contract와 context 두 면을 먼저 본다.
2. `src/tools/ToolSearchTool/ToolSearchTool.ts`
   discoverability surface를 확인한다.
3. `src/query.ts`
   tool result가 next-turn artifact가 되는 지점을 본다.
4. `src/utils/permissions/permissions.ts`
   contract와 boundary가 어떻게 맞물리는지 확인한다.
