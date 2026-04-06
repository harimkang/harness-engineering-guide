# Appendix. Glossary

## 장 요약

이 부록은 본문 전반에서 반복해서 등장하는 핵심 용어를 정리한다. 각 항목은 단순 번역보다 "어디서 등장하는지", "비슷한 개념과 무엇이 다른지", "어떤 발췌 provenance가 이 용어를 대표하는지"까지 함께 제공한다. 독자는 이 부록을 단독 사전처럼 읽어도 되지만, 실제로는 [00-how-to-read-this-book.md](../00-how-to-read-this-book.md), [source-analysis-method.md](./source-analysis-method.md), [references.md](./references.md)와 함께 보면 가장 유용하다.

여기서 가장 중요한 것은 파일명이 아니라 `정의`와 `비슷한 용어와 차이`다. `대표 근거 라벨`은 용어를 다시 source provenance와 연결하기 위한 메모일 뿐, 독자에게 별도 파일 접근을 요구하는 항목이 아니다.

## 이 용어집을 읽는 법

- `정의`는 이 책에서 그 용어를 어떤 작업 개념으로 쓰는지 설명한다.
- `비슷한 용어와 차이`는 헷갈리기 쉬운 인접 개념과의 경계를 고정한다.
- `대표 근거 라벨`은 본문에 인용된 발췌가 어떤 구현 단면에서 왔는지 보여 주는 provenance 메모다.

## 대표 코드 발췌

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

이 발췌는 `runtime shell`, `REPL`, `query pipeline`, `tool` 같은 용어가 실제로 한 지점에서 만나는 예다. 이 용어집의 항목들은 이런 load-bearing seam을 다시 찾기 위한 좌표라고 보면 된다.

## Harness

- 정의: 모델 호출, 도구 사용, 상태 유지, 인간 개입, 안전 경계, 평가 루프를 함께 운영하는 시스템
- 등장 장: `README`, foundations 전반, `01`, `16`, `17`
- 비슷한 용어와 차이: 단순 앱 wrapper나 prompt template보다 넓고, runtime 하나보다도 넓다
- 대표 근거 라벨: `src/main.tsx`, `src/query.ts`, `src/screens/REPL.tsx`

## Agent Harness

- 정의: 모델이 여러 턴에 걸쳐 도구를 쓰고 환경에서 피드백을 받아 작업을 계속하게 만드는 하네스
- 등장 장: foundations 전반, `05`, `06`, `12`, `17`
- 비슷한 용어와 차이: `Workflow`는 더 고정된 경로를 가질 수 있지만, `Agent Harness`는 모델이 다음 행동을 더 많이 결정한다
- 대표 근거 라벨: `src/query.ts`, `src/QueryEngine.ts`, `tools/`

## Evaluation Harness

- 정의: task, trial, transcript, grader, outcome을 조합해 시스템 성능을 측정하는 실행 틀
- 등장 장: evaluation 전반, `15`
- 비슷한 용어와 차이: model eval은 모델 자체를 본다면, evaluation harness는 runtime scaffolding과 도구 계약까지 포함해 본다
- 대표 근거 라벨: 본문은 주로 문서적 비교를 수행하며, 구현 기준점은 [evaluation/05-claude-code-benchmark-framework.md](../evaluation/05-claude-code-benchmark-framework.md)에 모여 있다

## Context Engineering

- 정의: 어떤 정보를 언제 context에 넣고, 언제 compact하거나 외부 artifact로 남길지를 설계하는 일
- 등장 장: Part II 전반, `05`, `13`, `17`
- 비슷한 용어와 차이: prompt engineering보다 넓으며, retrieval, compaction, handoff artifact까지 포함한다
- 대표 근거 라벨: `src/context.ts`, `src/query.ts`, `src/query/tokenBudget.ts`

## Boundary Engineering

- 정의: 모델 자율성을 유지하면서도 filesystem, network, trust, approval 경계를 안전하게 배치하는 설계 작업
- 등장 장: safety 전반, `04`, `08`, `14`, `16`
- 비슷한 용어와 차이: 단순 permission prompt 설계보다 넓고, sandbox와 deployment topology까지 포함한다
- 대표 근거 라벨: `src/utils/permissions/`, `bridge/`, `remote/`, `server/`

## Runtime Shell

- 정의: 여러 실행 모드와 상태를 조립해 하나의 제품 표면으로 묶는 바깥 구조
- 등장 장: `01`, `02`, `03`, `14`
- 비슷한 용어와 차이: 단일 event loop나 UI file보다 넓고, dispatch와 assembly까지 포함한다
- 대표 근거 라벨: `src/entrypoints/cli.tsx`, `src/main.tsx`

## REPL

- 정의: interactive 세션의 메인 terminal UI이자 여러 runtime subsystems를 묶는 composition root
- 등장 장: `03`, `09`, `15`, `16`
- 비슷한 용어와 차이: 단순 shell prompt가 아니라 command/tool/task/remote/state를 함께 다루는 애플리케이션 화면이다
- 대표 근거 라벨: `src/screens/REPL.tsx`, `src/replLauncher.tsx`

## Tool

- 정의: 모델이 agentic turn 중 호출하는 실행 단위
- 등장 장: `05`, `08`, `12`
- 비슷한 용어와 차이: `Command`는 사용자가 `/name`으로 호출하고, `Tool`은 모델이 tool-call loop 안에서 호출한다
- 대표 근거 라벨: `src/Tool.ts`, `src/tools.ts`, `tools/`

## Command

- 정의: 사용자가 슬래시 명령 형식으로 직접 호출하는 surface
- 등장 장: `07`, `09`
- 비슷한 용어와 차이: `Tool`은 모델 호출 surface, `Command`는 사용자 입력 surface다
- 대표 근거 라벨: `src/commands.ts`, `commands/`

## Skill

- 정의: markdown/frontmatter 기반의 프롬프트형 확장 단위
- 등장 장: `11`
- 비슷한 용어와 차이: `Plugin`은 번들 단위이고, `Skill`은 그 안에서 제공될 수 있는 개별 guidance unit이다
- 대표 근거 라벨: `src/skills/loadSkillsDir.ts`, `src/skills/bundledSkills.ts`

## Plugin

- 정의: skill, hook, MCP 설정, command 등을 제공할 수 있는 확장 번들
- 등장 장: `10`, `11`
- 비슷한 용어와 차이: `Skill`보다 넓고, `MCP`보다 로컬 확장 번들 성격이 강하다
- 대표 근거 라벨: `src/plugins/builtinPlugins.ts`, `src/services/plugins/`

## MCP

- 정의: Model Context Protocol. tool/resource/prompt 확장 프로토콜
- 등장 장: `04`, `08`, `10`, `11`
- 비슷한 용어와 차이: `Plugin`이 로컬 번들이라면 `MCP`는 프로토콜과 서버 연결 구조에 가깝다
- 대표 근거 라벨: `src/services/mcp/client.ts`, `src/services/mcp/config.ts`, `src/services/mcp/MCPConnectionManager.tsx`

## Bridge

- 정의: 로컬 환경을 원격 제어 세션과 연결하는 계층
- 등장 장: `03`, `14`
- 비슷한 용어와 차이: `Direct Connect`는 직접 연결 경로고, `Bridge`는 remote-control용 중간 계층이다
- 대표 근거 라벨: `src/bridge/bridgeMain.ts`, `src/bridge/replBridge.ts`

## CCR

- 정의: Claude Code가 붙는 원격 세션/서비스 계열을 가리키는 본문 약칭
- 등장 장: `14`, `17`
- 비슷한 용어와 차이: product/service 이름 전체가 아니라, remote session stream과 관련된 서버 측 경로를 지칭하는 축약 표현이다
- 대표 근거 라벨: `src/remote/SessionsWebSocket.ts`, `src/remote/RemoteSessionManager.ts`

## Assistant Viewer

- 정의: 로컬 REPL을 원격 assistant session의 viewer client로 붙이는 실행 형태
- 등장 장: `14`, `17`
- 비슷한 용어와 차이: 일반 interactive REPL은 로컬 query owner이고, assistant viewer는 원격에서 이미 돌고 있는 agent loop를 보는 client에 가깝다
- 대표 근거 라벨: `src/main.tsx`, `src/screens/REPL.tsx`

## Teleport

- 정의: 원격 세션 생성 또는 재개와 연관된 remote/resume family
- 등장 장: `03`, `14`, `17`
- 비슷한 용어와 차이: `Assistant Viewer`처럼 단순 attach가 아니라, 원격 세션 생성, checkout, resume 흐름이 함께 걸릴 수 있다
- 대표 근거 라벨: `src/main.tsx`, `src/utils/teleport.tsx`, `src/utils/teleport/api.ts`

## Direct Connect

- 정의: 특정 서버와 직접 세션을 여는 경로
- 등장 장: `03`, `14`
- 비슷한 용어와 차이: `Bridge`와 달리 relay/remote-control 환경이 아니라 직접 세션 생성에 가깝다
- 대표 근거 라벨: `src/server/createDirectConnectSession.ts`

## Task

- 정의: shell, agent, workflow, remote 등 비동기 실행 단위
- 등장 장: `08`, `12`
- 비슷한 용어와 차이: `Tool`은 호출 surface이고, `Task`는 실행 단위와 lifecycle 모델이다
- 대표 근거 라벨: `src/Task.ts`, `src/tasks.ts`, `tasks/`

## Startup / Trust

- 정의: interactive 세션 시작 전에 실행되는 onboarding, trust, approval, environment 적용 흐름
- 등장 장: `03`, `04`
- 비슷한 용어와 차이: permission mode와 trust boundary는 겹치지 않는다. trust는 workspace 경계, permission은 tool execution 경계다
- 대표 근거 라벨: `src/interactiveHelpers.tsx`, `src/setup.ts`

## Preflight Setup

- 정의: 화면 렌더링 전에 `src/setup.ts`가 수행하는 non-UI startup 단계
- 등장 장: `03`, `04`, `13`
- 비슷한 용어와 차이: startup UI보다 앞에서 일어나는 준비 작업이며, dialog 흐름과는 구분된다
- 대표 근거 라벨: `src/setup.ts`

## Query Pipeline

- 정의: context 조립, token budget, compact, tool orchestration을 포함한 모델 호출 전후 경로
- 등장 장: `05`, `06`
- 비슷한 용어와 차이: `QueryEngine`이 conversation state wrapper라면 `Query Pipeline`은 실제 호출 orchestration 그 자체에 가깝다
- 대표 근거 라벨: `src/query.ts`, `src/query/config.ts`, `src/query/tokenBudget.ts`, `src/query/stopHooks.ts`

## QueryEngine

- 정의: SDK/headless 경로에서 query pipeline을 감싸는 conversation 상태 관리자
- 등장 장: `06`
- 비슷한 용어와 차이: `src/query.ts`가 pipeline이라면 `QueryEngine`은 turn 단위 상태 기계다
- 대표 근거 라벨: `src/QueryEngine.ts`

## Source Of Truth

- 정의: 특정 규칙이나 상태 전이가 실제로 정의되는 파일이나 계층
- 등장 장: `15`, `17`
- 비슷한 용어와 차이: `integration seam`은 여러 source of truth를 연결하는 층이고, source of truth는 규칙 자체가 놓인 자리다
- 대표 근거 라벨: `src/query.ts`, `src/utils/sessionRestore.ts`, `src/Tool.ts`

## Integration Seam

- 정의: 여러 source of truth를 조합하고 route하여 한 세션 표면으로 연결하는 경계
- 등장 장: `15`, `17`
- 비슷한 용어와 차이: source of truth가 규칙을 소유한다면, integration seam은 그 규칙을 조립해 실제 실행 경로로 연결한다
- 대표 근거 라벨: `src/main.tsx`, `src/screens/REPL.tsx`, `src/commands.ts`

## Control Plane

- 정의: 한 turn 또는 한 세션 안에서 상태 전이, 후속 호출, continuation, 승인을 조율하는 제어 계층
- 등장 장: `02`, `05`, `06`, `14`, `17`
- 비슷한 용어와 차이: 단순 데이터 경로나 UI와 달리, 무엇을 다음에 할지 결정하는 규칙과 상태 전이를 뜻한다
- 대표 근거 라벨: `src/query.ts`, `src/utils/sessionRestore.ts`, `src/bridge/bridgeMain.ts`

## State Owner / Ownership Model

- 정의: 특정 실행 모드에서 여러 단계에 걸친 상태를 실제로 보존하고 갱신하는 주체
- 등장 장: `02`, `06`, `15`, `17`
- 비슷한 용어와 차이: 단순 caller와 다르다. 어떤 객체나 파일이 session state, turn state, UI state를 책임지는지에 대한 구조적 역할을 뜻한다
- 대표 근거 라벨: `src/screens/REPL.tsx`, `src/QueryEngine.ts`, `src/query.ts`

## Bootstrapper

- 정의: 세션 실행 전에 필요한 config나 계약 artifact를 발급해 다음 단계로 넘기는 adapter
- 등장 장: `14`, `17`
- 비슷한 용어와 차이: 이미 존재하는 세션에 붙는 `session client`와 달리, bootstrapper는 attach 이전의 초기 계약을 만든다
- 대표 근거 라벨: `src/server/createDirectConnectSession.ts`

## Supervisor

- 정의: 여러 세션이나 work item을 운영하면서 heartbeat, reconnect, spawn 같은 제어를 맡는 상위 owner
- 등장 장: `14`, `17`
- 비슷한 용어와 차이: 단일 세션 client보다 control-plane 책임이 넓다
- 대표 근거 라벨: `src/bridge/bridgeMain.ts`

## Relay

- 정의: 상위 agent loop가 아니라 lower-level network traffic이나 session bytes를 중계하는 adapter
- 등장 장: `14`
- 비슷한 용어와 차이: `session client`가 메시지 의미를 다루는 반면, relay는 더 낮은 transport 경계에 가깝다
- 대표 근거 라벨: `src/upstreamproxy/relay.ts`

## Compaction

- 정의: 긴 세션에서 context pressure를 줄이기 위해 transcript나 context를 압축·요약·정리하는 경로
- 등장 장: `05`, `06`, `16`, `17`
- 비슷한 용어와 차이: 단순 truncation과 달리, 다음 turn이 계속 진행될 수 있도록 상태를 남기며 줄이는 작업이다
- 대표 근거 라벨: `src/query.ts`, `src/QueryEngine.ts`

## Handoff Artifact

- 정의: 한 owner에서 다른 owner로 넘어갈 때 같이 전달되는 상태 묶음 또는 계약 데이터
- 등장 장: `05`, `14`, `17`
- 비슷한 용어와 차이: 일반 message보다 넓고, runtime을 이어 붙이는 config/state bundle을 가리킨다
- 대표 근거 라벨: `src/server/createDirectConnectSession.ts`, `src/utils/conversationRecovery.ts`, `src/utils/sessionRestore.ts`

## AppState

- 정의: UI와 runtime이 공유하는 전역 상태 모델
- 등장 장: `09`, `12`
- 비슷한 용어와 차이: 단일 React local state가 아니라 session-level state store에 가깝다
- 대표 근거 라벨: `src/state/AppState.tsx`, `src/state/AppStateStore.ts`

## Background Session

- 정의: 세션 전체를 foreground REPL 밖에서 유지하고 제어하는 실행 형태
- 등장 장: `03`, `12`, `17`
- 비슷한 용어와 차이: 개별 `Task`와 달리 session 전체를 background로 운용한다
- 대표 근거 라벨: `src/entrypoints/cli.tsx`, `src/tasks/`, `src/query.ts`

## Feature Flag

- 정의: build-time 또는 runtime 조건에 따라 기능을 켜고 끄는 분기
- 등장 장: `03`, `11`, `16`, appendix
- 비슷한 용어와 차이: 코드에 존재한다고 해서 항상 활성은 아니다
- 대표 근거 라벨: `src/entrypoints/cli.tsx`, `src/main.tsx`, `src/services/analytics/growthbook.ts`
