# Appendix. Directory Map

> Why this chapter exists: top-level 디렉터리를 semantic grouping으로 다시 묶어, 누락되기 쉬운 영역도 본문과 연결되게 만든다.
> Reader path tags: `advanced` / `reference`
> Last verified: 2026-04-06
> Freshness class: medium
> Source tier focus: Tier 6 observed artifact map

## 장 요약

이 부록은 원 upstream 공개 사본 source tree의 top-level 디렉터리 35개가 어떤 책임을 가지며, 본문 문서 어디에서 주로 해설되는지 보여준다. 목적은 파일 수가 적은 디렉터리나 조건부 기능 디렉터리가 문서화 과정에서 "조용히 누락"되는 일을 막는 것이다.

top-level 루트 파일은 [root-file-map.md](04-root-file-map.md)에 따로 정리한다.

이 부록은 원 upstream 공개 사본 source tree의 디렉터리 관점 지도다. "어느 폴더가 어떤 문제 영역과 연결되는가"를 보고 싶을 때 먼저 읽는다. 개별 구현 단면의 provenance를 다시 보고 싶다면 [key-file-index.md](02-key-file-index.md), 루트 조립 계열만 보고 싶다면 [root-file-map.md](04-root-file-map.md)가 더 빠르다.

이 표 역시 파일 탐색표가 아니라 semantic grouping으로 읽는 편이 맞다. 디렉터리명은 provenance label이고, 실제 의미는 `역할 요약`과 `배정 이유`가 담당한다.

## Reader-path suggestions

- `advanced`: 구조 전체를 다시 그릴 때 [key-file-index.md](02-key-file-index.md)보다 넓은 지도가 필요하면 먼저 연다.
- `reference`: top-level 폴더의 narrative impact를 빠르게 복기할 때 쓴다.

## 대표 코드 발췌

```ts
import { getSystemContext, getUserContext } from './context.js';
import { launchRepl } from './replLauncher.js';
import { getMcpToolsCommandsAndResources } from './services/mcp/client.js';
import { initBundledSkills } from './skills/bundled/index.js';
import { createDirectConnectSession } from './server/createDirectConnectSession.js';
```

이 발췌는 `src/main.tsx`가 여러 top-level 디렉터리를 가로질러 runtime assembly를 수행하는 장면의 일부다. 그래서 이 부록은 디렉터리 수를 세는 표가 아니라, 어떤 폴더가 어떤 문제 축에 매달려 있는지 읽기 위한 지도다.

## 읽는 법

- `주요 장`은 가장 중심적으로 다루는 장을 뜻한다.
- `배정 이유`는 왜 그 장에서 읽는 것이 가장 자연스러운지 설명한다.
- `대표 근거 라벨`은 그 디렉터리의 성격을 대표하는 발췌 출처 메모다.

## 디렉터리 대응표

| 디렉터리 | 파일 수 | 역할 요약 | 주요 장 | 배정 이유 | 대표 근거 라벨 |
| --- | ---: | --- | --- | --- | --- |
| `assistant/` | 1 | assistant mode 관련 조건부 축 | `11`, `conditional-features-map.md` | 항상 활성이라 보기 어렵고 extension/coordination 장과 함께 읽어야 하기 때문 | `src/assistant/sessionHistory.ts` |
| `bootstrap/` | 1 | 세션 전역 상태와 early bootstrap state | `03`, `13` | entrypoint가 건드리는 전역 상태와 persistence 관점이 동시에 중요하기 때문 | `src/bootstrap/state.ts` |
| `bridge/` | 31 | remote-control bridge transport와 session control | `14` | network/remote 축의 핵심 구현이 집중된 디렉터리이기 때문 | `src/bridge/bridgeMain.ts` |
| `buddy/` | 6 | companion/buddy 시각 보조 UI | `09` | terminal UI와 interaction 계층의 일부로 읽는 편이 자연스럽기 때문 | `src/buddy/companion.ts` |
| `cli/` | 19 | headless CLI 보조 handler와 structured I/O | `03`, `14` | entrypoint에서 분기된 후 어떤 headless surface가 열리는지 설명할 때 필요하기 때문 | `src/cli/structuredIO.ts` |
| `commands/` | 207 | slash command 구현 | `07` | 사용자가 직접 호출하는 command surface의 중심이기 때문 | `src/commands/add-dir/add-dir.tsx` |
| `components/` | 389 | Ink/React UI 컴포넌트 | `09` | 화면과 dialog, message rendering이 가장 많이 모이는 UI 계층이기 때문 | `src/components/App.tsx` |
| `constants/` | 21 | 상수, prompt/resource limit, 공통 문자열 | `13`, appendix | persistence/config와 여러 장의 보조 reference 성격이 강하기 때문 | `src/constants/prompts.ts` |
| `context/` | 9 | React context provider 모음 | `09` | UI 계층에서 state와 overlay, stats, voice context를 묶는 역할을 하기 때문 | `src/context/modalContext.tsx` |
| `coordinator/` | 1 | coordinator mode 전용 logic | `11`, `conditional-features-map.md` | extension/coordination 주제이면서 동시에 feature-gated 구조이기 때문 | `src/coordinator/coordinatorMode.ts` |
| `entrypoints/` | 8 | CLI, SDK, MCP 등 초기 진입점 타입과 entry surface | `03` | 실행 모드 분기와 가장 직접 연결되기 때문 | `src/entrypoints/cli.tsx` |
| `hooks/` | 104 | UI와 runtime을 이어주는 hook 계층 | `09`, `10` | 단순 UI helper를 넘어서 service/state/runtime을 연결하는 경계이기 때문 | `src/hooks/useCommandQueue.ts` |
| `ink/` | 96 | terminal rendering 기반 계층 | `09` | 렌더링/입력/화면 업데이트라는 terminal UI의 기반 구현이기 때문 | `src/ink/Ansi.tsx` |
| `keybindings/` | 14 | keybinding schema와 provider setup | `09` | terminal interaction을 가장 직접적으로 드러내기 때문 | `src/keybindings/KeybindingProviderSetup.tsx` |
| `memdir/` | 8 | memory file 경로와 로딩 로직 | `05`, `13` | query context 주입과 persistence 경계에 동시에 걸쳐 있기 때문 | `src/memdir/memdir.ts` |
| `migrations/` | 11 | 설정/상태 migration | `13` | persistence 장에서 version transition을 설명하는 핵심 근거이기 때문 | `src/migrations/migrateAutoUpdatesToSettings.ts` |
| `moreright/` | 1 | 입력 관련 보조 hook | appendix | 파일 수가 적고 독립 장의 주제가 되지 않지만 누락 방지용 reference가 필요하기 때문 | `src/moreright/useMoreRight.tsx` |
| `native-ts/` | 4 | low-level TS utility | appendix | 특정 장의 중심이라기보다 reference 성격이 강하기 때문 | `src/native-ts/color-diff/index.ts` |
| `outputStyles/` | 1 | output style 로딩 지점 | `09` | terminal rendering 결과 스타일링 경계이기 때문 | `src/outputStyles/loadOutputStylesDir.ts` |
| `plugins/` | 2 | builtin plugin surface | `11` | skill/MCP/command 확장을 묶는 extension 축의 일부이기 때문 | `src/plugins/builtinPlugins.ts` |
| `query/` | 4 | query pipeline 보조 모듈 | `05` | `src/query.ts`를 분해해 읽을 때 필요한 config/budget/hook 절단면이기 때문 | `src/query/tokenBudget.ts` |
| `remote/` | 4 | remote session transport와 bridge | `14` | bridge와 함께 원격 세션 축을 형성하기 때문 | `src/remote/RemoteSessionManager.ts` |
| `schemas/` | 1 | schema 정의 | appendix | 특정 흐름 장보다 reference 용도가 강하기 때문 | `src/schemas/hooks.ts` |
| `screens/` | 3 | 상위 화면 entrypoint | `03`, `09` | 실행 모드가 어떤 화면으로 들어가고, REPL이 어떻게 composition root가 되는지 설명할 때 필요하기 때문 | `src/screens/REPL.tsx` |
| `server/` | 3 | direct connect server 축 | `14` | remote/network 장에서 bridge와 대비되는 직접 연결 경로를 설명할 때 필요하기 때문 | `src/server/createDirectConnectSession.ts` |
| `services/` | 130 | 외부 연동과 runtime services | `10` | service 계층과 integration 구조가 가장 밀집해 있기 때문 | `src/services/api/client.ts` |
| `skills/` | 20 | skill 로딩과 bundled skill 정의 | `11` | extension/coordination 장의 핵심 근거이기 때문 | `src/skills/loadSkillsDir.ts` |
| `state/` | 6 | app state 저장소와 상태 변화 처리 | `09` | UI와 interaction 계층의 상태 모델을 설명할 때 핵심이기 때문 | `src/state/AppStateStore.ts` |
| `tasks/` | 12 | foreground/background/local/remote task 구현 | `12` | task abstraction과 lifecycle을 직접 구현하는 디렉터리이기 때문 | `src/tasks/LocalShellTask/LocalShellTask.tsx` |
| `tools/` | 184 | 모델이 호출하는 tool 구현 | `08` | tool surface와 permission 경계를 설명할 때 중심이 되기 때문 | `src/tools/AgentTool/AgentTool.tsx` |
| `types/` | 11 | 공통 타입 정의 | appendix | 여러 장에서 참조되지만 독립 장의 중심은 아니기 때문 | `src/types/command.ts` |
| `upstreamproxy/` | 2 | websocket relay와 upstream proxy 진입점 | `14` | remote/bridge와 다른 relay 성격을 설명하는 데 필요하기 때문 | `src/upstreamproxy/relay.ts` |
| `utils/` | 564 | 횡단 유틸리티와 helper 집합 | `02`, `05`, `06`, `13`, `16` | 구조 복잡도가 가장 많이 스며든 영역이라 한 장에 고정하기보다 여러 장의 근거로 읽어야 하기 때문 | `src/utils/config.ts` |
| `vim/` | 5 | vim-style 입력 처리 | `09` | terminal interaction과 input model 설명에 직접 연결되기 때문 | `src/vim/motions.ts` |
| `voice/` | 1 | voice mode enablement | `09`, `conditional-features-map.md` | terminal interaction의 일부이면서 feature-gated 가능성이 크기 때문 | `src/voice/voiceModeEnabled.ts` |

## 관찰 포인트

### `components/`, `hooks/`, `utils/`는 파일 수가 많지만 역할이 다르다

세 디렉터리 모두 대형이지만, `components/`는 화면 조각, `hooks/`는 연결 로직, `utils/`는 횡단 helper라는 차이를 가진다. 이 차이를 놓치면 UI 장이 너무 넓어지거나, 모든 복잡도를 `utils/` 탓으로만 읽게 된다.

### 파일 수가 적다고 중요도가 낮은 것은 아니다

`assistant/`, `coordinator/`, `outputStyles/`, `voice/`처럼 파일 수가 적은 디렉터리도 runtime mode나 feature gate를 이해할 때는 중요하다. 그래서 이 부록은 파일 수가 적은 디렉터리도 빠짐없이 포함한다.

## 관련 부록

- 루트 조립 파일은 [root-file-map.md](04-root-file-map.md)
- 조건부 기능은 [conditional-features-map.md](05-conditional-features-map.md)
- 핵심 파일만 빠르게 보고 싶다면 [key-file-index.md](02-key-file-index.md)

## Sources / evidence notes

- 이 appendix는 Tier 6 observed artifact 기준의 semantic map이다.
- feature-gated 디렉터리는 [conditional-features-map.md](05-conditional-features-map.md)와 함께 읽어야 drift risk를 줄일 수 있다.
