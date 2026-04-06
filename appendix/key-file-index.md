# Appendix. Key File Index

## 장 요약

이 부록은 "어떤 구현 단면이 어떤 개념을 대표하는가"라는 질문에 답하기 위한 빠른 인덱스다. 각 항목은 역할 요약, 관련 장 번호, 대표 발췌 포인트, 주의할 점을 함께 적는다.

appendix를 하나만 먼저 연다면 이 파일이 가장 실용적이다. `Directory Map`이 폴더 관점의 지도라면, 이 부록은 본문에 등장하는 핵심 발췌의 provenance label을 빠르게 다시 묶어 주는 인덱스다. `Root File Map`은 루트 조립 파일 계열만 빠르게 보고 싶을 때 참고하는 보조 표다.

이 부록을 읽을 때는 파일명보다 `역할 요약`과 `대표 발췌 포인트`를 먼저 읽는 편이 좋다. 여기의 경로 라벨은 독자가 source를 열기 위한 링크가 아니라, 본문에서 이미 설명된 구현 단면의 provenance 메모다. 경로는 원 upstream 공개 사본 기준으로 `src/` 경로 표기를 사용한다.

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

이 발췌는 왜 이 부록이 단순 파일 목록이 아니라 "핵심 구현 단면의 provenance index" 역할을 하는지 보여 준다. `src/screens/REPL.tsx` 같은 항목은 UI 파일이어서가 아니라, 실제로 query loop를 붙드는 load-bearing seam이기 때문에 색인에 올라온다.

## Runtime And Startup

### `src/entrypoints/cli.tsx`

- 역할 요약: fast-path와 실행 모드 분기의 첫 관문
- 관련 장 번호: `01`, `03`
- 대표 발췌 포인트: `main()` 초반의 `--version`, `--daemon-worker`, `remote-control`, `daemon`, `--bg` 분기
- 주의할 점: `src/main.tsx`로 항상 내려간다고 가정하면 안 된다

### `src/main.tsx`

- 역할 요약: 공통 초기화와 runtime assembly의 중심
- 관련 장 번호: `02`, `03`, `04`, `16`
- 대표 발췌 포인트: top-level side-effect, `main()` orchestration, GrowthBook/telemetry/init 경로
- 주의할 점: 너무 큰 파일이라 장별 절단면으로 읽어야 한다

### `src/setup.ts`

- 역할 요약: Ink root 생성 전 preflight startup
- 관련 장 번호: `03`, `04`, `13`
- 대표 발췌 포인트: cwd/worktree/hooks/prefetch 관련 helper
- 주의할 점: UI startup과 preflight를 같은 단계로 읽으면 구조가 흐려진다

### `src/interactiveHelpers.tsx`

- 역할 요약: onboarding, trust, approval dialog 허브
- 관련 장 번호: `04`
- 대표 발췌 포인트: `showSetupScreens()`
- 주의할 점: bypass permissions와 trust acceptance는 다른 경계다

### `src/screens/REPL.tsx`

- 역할 요약: interactive 세션의 composition root
- 관련 장 번호: `02`, `03`, `09`, `16`
- 대표 발췌 포인트: state, command, tool, remote, task를 연결하는 handler 구역
- 주의할 점: 단순 렌더링 컴포넌트가 아니다

## Query And Conversation

### `src/context.ts`

- 역할 요약: system/user context 조립
- 관련 장 번호: `05`
- 대표 발췌 포인트: `getGitStatus()`, `getSystemContext()`, `getUserContext()`
- 주의할 점: memoize snapshot 성격이 강하다

### `src/query.ts`

- 역할 요약: interactive query loop orchestration
- 관련 장 번호: `05`, `06`
- 대표 발췌 포인트: `query()`, `queryLoop()`, budget tracker, tool orchestration
- 주의할 점: `src/QueryEngine.ts`가 없어도 핵심 호출 정책은 이미 여기에 있다

### `src/query/config.ts`

- 역할 요약: query config snapshot 구성
- 관련 장 번호: `05`
- 대표 발췌 포인트: `buildQueryConfig()`
- 주의할 점: feature-gated 상태를 전부 여기서 읽는 것은 아니다

### `src/query/tokenBudget.ts`

- 역할 요약: token budget 체크와 tracker 생성
- 관련 장 번호: `05`
- 대표 발췌 포인트: tracker 생성과 budget check 함수
- 주의할 점: API task budget과 같은 개념이 아니다

### `src/query/stopHooks.ts`

- 역할 요약: stop hook 처리와 후속 제어
- 관련 장 번호: `05`
- 대표 발췌 포인트: `handleStopHooks()`
- 주의할 점: `TEMPLATES` 같은 조건부 경로와 함께 읽어야 한다

### `src/QueryEngine.ts`

- 역할 요약: SDK/headless conversation state engine
- 관련 장 번호: `06`
- 대표 발췌 포인트: `QueryEngine` constructor, `submitMessage()`
- 주의할 점: REPL path와 1:1로 동일한 실행 경로는 아니다

## Commands And Tools

### `src/commands.ts`

- 역할 요약: slash command registry와 registration surface
- 관련 장 번호: `07`
- 대표 발췌 포인트: command 등록 구조와 helper
- 주의할 점: 구현은 `commands/` 하위에 흩어져 있다

### `src/Tool.ts`

- 역할 요약: tool 인터페이스와 lookup helper
- 관련 장 번호: `08`
- 대표 발췌 포인트: type 정의, `findToolByName()`
- 주의할 점: permission과 실행은 별도 계층에서 완성된다

### `src/tools.ts`

- 역할 요약: tool registry와 session tool set 구성
- 관련 장 번호: `08`
- 대표 발췌 포인트: `getTools()`
- 주의할 점: 구현 세부는 이 부록보다 [08-tool-system-and-permissions.md](../08-tool-system-and-permissions.md)와 [11-agent-skill-plugin-mcp-and-coordination.md](../11-agent-skill-plugin-mcp-and-coordination.md)에서 더 잘 닫힌다

## State And UI

### `src/state/AppState.tsx`

- 역할 요약: AppState provider와 state exposure
- 관련 장 번호: `09`
- 대표 발췌 포인트: provider 구성
- 주의할 점: 실제 store mechanics는 `src/state/AppStateStore.ts` 쪽이 더 중요하다

### `src/state/AppStateStore.ts`

- 역할 요약: 기본 AppState shape와 store helper
- 관련 장 번호: `09`, `12`
- 대표 발췌 포인트: default state와 핵심 field
- 주의할 점: task/status와 UI concerns가 함께 섞여 있다

### `src/ink.ts`

- 역할 요약: render/createRoot facade
- 관련 장 번호: `09`
- 대표 발췌 포인트: Ink export와 render helper
- 주의할 점: plain re-export로 보면 역할을 과소평가하기 쉽다

## Terminal Interaction

### `src/keybindings/KeybindingProviderSetup.tsx`

- 역할 요약: keybinding provider setup
- 관련 장 번호: `09`
- 대표 발췌 포인트: provider wiring
- 주의할 점: `src/screens/REPL.tsx`의 input handling과 함께 읽어야 한다

### `vim/`

- 역할 요약: vim input model 관련 구현
- 관련 장 번호: `09`
- 대표 발췌 포인트: motions와 입력 모드 전환
- 주의할 점: 단독으로 보기보다 text input 컴포넌트와 함께 봐야 한다

### `src/voice/voiceModeEnabled.ts`

- 역할 요약: voice mode enablement gate
- 관련 장 번호: `09`, appendix
- 대표 발췌 포인트: enablement 판단
- 주의할 점: feature-gated or environment-dependent 가능성을 항상 고려해야 한다

### `src/outputStyles/loadOutputStylesDir.ts`

- 역할 요약: output style 디렉터리 로딩
- 관련 장 번호: `09`
- 대표 발췌 포인트: style discovery/loader
- 주의할 점: 작은 파일이지만 UI 출력 층의 확장 포인트다

## Services And Integrations

### `src/services/api/client.ts`

- 역할 요약: API client surface
- 관련 장 번호: `10`
- 대표 발췌 포인트: request construction 관련 helper
- 주의할 점: 실사용 경로는 `src/services/api/claude.ts`, `src/services/api/bootstrap.ts`, `src/services/api/withRetry.ts`와 연결된다

### `src/services/mcp/client.ts`

- 역할 요약: MCP tools/resources/client orchestration
- 관련 장 번호: `10`, `11`
- 대표 발췌 포인트: MCP fetch helper와 resource/tool wiring
- 주의할 점: protocol 설명과 product integration 설명이 같이 섞일 수 있다

### `src/services/oauth/index.ts`

- 역할 요약: OAuth support entry
- 관련 장 번호: `10`
- 대표 발췌 포인트: auth code listener와 profile lookup으로 이어지는 흐름
- 주의할 점: auth helper는 `utils/`와도 많이 얽힌다

### `src/services/compact/autoCompact.ts`

- 역할 요약: auto compact policy
- 관련 장 번호: `05`, `10`
- 대표 발췌 포인트: compact trigger tracking
- 주의할 점: `src/query.ts`와 분리해서 읽어도 전체 흐름은 닫히지 않는다

### `src/services/lsp/manager.ts`

- 역할 요약: LSP server manager init point
- 관련 장 번호: `10`
- 대표 발췌 포인트: manager initialization
- 주의할 점: passive feedback, registry, instance와 함께 봐야 한다

### `src/services/plugins/PluginInstallationManager.ts`

- 역할 요약: plugin installation manager
- 관련 장 번호: `10`, `11`
- 대표 발췌 포인트: install/update/remove surface
- 주의할 점: builtin plugin과 installed plugin을 혼동하면 안 된다

## Agents, Skills, Plugins

### `src/skills/loadSkillsDir.ts`

- 역할 요약: skill 디렉터리 로더
- 관련 장 번호: `11`
- 대표 발췌 포인트: directory scan과 parse flow
- 주의할 점: bundled skills와 외부 skill dir의 차이를 함께 봐야 한다

### `src/skills/bundledSkills.ts`

- 역할 요약: 내장 skill 목록
- 관련 장 번호: `11`
- 대표 발췌 포인트: exported bundled skill set
- 주의할 점: 실제 load path는 `src/skills/loadSkillsDir.ts`와 결합해 읽어야 한다

### `src/plugins/builtinPlugins.ts`

- 역할 요약: builtin plugin 정의
- 관련 장 번호: `11`
- 대표 발췌 포인트: built-in plugin metadata
- 주의할 점: services/plugins와 책임이 다르다

### `src/coordinator/coordinatorMode.ts`

- 역할 요약: coordinator mode 전용 logic
- 관련 장 번호: `11`, appendix
- 대표 발췌 포인트: exported helper와 prompt context 관련 함수
- 주의할 점: feature gate 없이 항상 활성로 읽으면 안 된다

## Tasks

### `src/Task.ts`

- 역할 요약: task abstraction 공통 타입
- 관련 장 번호: `12`
- 대표 발췌 포인트: core type/interface
- 주의할 점: lifecycle 설명은 [12-task-model-and-background-execution.md](../12-task-model-and-background-execution.md)의 registry/lifecycle 절에서 보완된다

### `src/tasks.ts`

- 역할 요약: task registry와 helper
- 관련 장 번호: `12`
- 대표 발췌 포인트: registry/creation helper
- 주의할 점: local shell, local agent, remote agent의 차이는 [12-task-model-and-background-execution.md](../12-task-model-and-background-execution.md)의 비교 표와 시나리오 설명을 함께 읽어야 닫힌다

### `src/entrypoints/agentSdkTypes.ts`

- 역할 요약: SDK/headless message/status type surface
- 관련 장 번호: `06`, `12`
- 대표 발췌 포인트: SDK status/message types
- 주의할 점: QueryEngine 결과물과 연결해서 읽어야 의미가 생긴다

## Persistence

### `src/utils/settings/settings.ts`

- 역할 요약: settings load/merge/read surface
- 관련 장 번호: `04`, `13`
- 대표 발췌 포인트: settings source merge
- 주의할 점: global config, managed settings, policy settings를 함께 봐야 한다

### `src/utils/config.ts`

- 역할 요약: global config와 session-adjacent config helper
- 관련 장 번호: `04`, `13`
- 대표 발췌 포인트: trust acceptance, updater, remote control at startup 관련 helper
- 주의할 점: settings와 config가 같은 계층이 아니다

### `src/utils/sessionStorage.ts`

- 역할 요약: transcript/session persistence helper
- 관련 장 번호: `06`, `13`
- 대표 발췌 포인트: record/flush helpers
- 주의할 점: prompt history와 같은 저장소가 아니다

### `src/history.ts`

- 역할 요약: input history and pasted content ref
- 관련 장 번호: `09`, `13`
- 대표 발췌 포인트: search/restore helper
- 주의할 점: transcript와 다른 성격의 저장소다

### `src/projectOnboardingState.ts`

- 역할 요약: project-level onboarding status
- 관련 장 번호: `04`, `13`
- 대표 발췌 포인트: state read/write helper
- 주의할 점: global onboarding과 혼동하지 않는다

### `src/cost-tracker.ts`

- 역할 요약: cost and usage accumulation
- 관련 장 번호: `13`
- 대표 발췌 포인트: usage/cost aggregation
- 주의할 점: runtime metrics와 persistence helper가 함께 섞인다

### `src/costHook.ts`

- 역할 요약: exit-time cost hook
- 관련 장 번호: `13`
- 대표 발췌 포인트: hook registration point
- 주의할 점: UI 종료 흐름과 함께 읽어야 의미가 선명해진다

### `src/memdir/memdir.ts`

- 역할 요약: memory directory prompt/mechanics helper
- 관련 장 번호: `05`, `13`
- 대표 발췌 포인트: memory prompt loading
- 주의할 점: query context 주입과 persistence 두 장 모두에서 등장한다

## Remote And Bridge

### `src/remote/RemoteSessionManager.ts`

- 역할 요약: remote session manager
- 관련 장 번호: `14`
- 대표 발췌 포인트: config/session creation helper
- 주의할 점: bridge와 direct connect 중 어느 경로인지 분리해서 읽어야 한다

### `src/remote/SessionsWebSocket.ts`

- 역할 요약: remote websocket session transport
- 관련 장 번호: `14`
- 대표 발췌 포인트: websocket message transport
- 주의할 점: relay와 direct connect를 혼동하기 쉽다

### `src/bridge/bridgeMain.ts`

- 역할 요약: bridge mode main entry
- 관련 장 번호: `03`, `14`
- 대표 발췌 포인트: bridge command entry
- 주의할 점: runtime gate와 auth/policy gate를 함께 읽어야 한다

### `src/server/createDirectConnectSession.ts`

- 역할 요약: direct connect session creation
- 관련 장 번호: `14`
- 대표 발췌 포인트: direct connect handshake/session creation
- 주의할 점: bridge path와 별개로 읽어야 한다

### `src/upstreamproxy/relay.ts`

- 역할 요약: CONNECT-over-WebSocket relay
- 관련 장 번호: `14`
- 대표 발췌 포인트: relay transport logic
- 주의할 점: network/transport 설명이 없으면 코드만 보고 맥락을 잡기 어렵다
