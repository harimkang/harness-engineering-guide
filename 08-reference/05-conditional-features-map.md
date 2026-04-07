# Appendix. Conditional Features Map

> Why this chapter exists: feature-gated path와 conditional branch를 별도로 고정해 "코드에 보임"과 "항상 활성"을 구분하게 만든다.
> Reader path tags: `reviewer` / `volatile re-check`
> Last verified: 2026-04-06
> Freshness class: volatile
> Source tier focus: Tier 6 observed artifact map, with Tier 1 release-note and product-doc re-check for drift-prone features
> Volatile topics: release-note-heavy feature gates, runtime default state, remote/bridge/auth-adjacent toggles

## 장 요약

이 부록은 구조 이해에 직접 영향을 주는 주요 feature-gated 또는 conditional path를 정리한다. 목적은 "코드에 보인다고 항상 활성인 것은 아니다"라는 점을 본문 전체에서 일관되게 유지하는 것이다.

Part 8의 두 축 중 이 파일은 `Claude Code source atlas`에서 drift-sensitive feature gate만 따로 추적하는 지도다.

## 읽는 규칙

1. build-time feature는 아예 dead-code elimination 대상일 수 있다.
2. runtime gate는 코드가 존재해도 현재 세션에서 꺼져 있을 수 있다.
3. 본문 장에서는 "존재한다"와 "항상 켜진다"를 구분해서 서술해야 한다.

이 부록은 feature gate와 conditional path만 따로 추적하는 지도다. 일반 구조는 [directory-map.md](03-directory-map.md), 핵심 파일 탐색은 [key-file-index.md](02-key-file-index.md)와 역할이 다르다.

이 부록의 `영향받는 장` 표기는 현재 장 구조 기준 shorthand를 쓴다. `reference`는 narrative chapter보다 reference appendix에서 같이 봐야 의미가 닫히는 항목이라는 뜻이다.

## Reader-path suggestions

- `reviewer`: Part 2, Part 5, Part 6을 읽다가 "이 코드가 항상 켜져 있는가"가 궁금해질 때 연다.
- `volatile re-check`: default state나 product availability를 reader-facing 문장으로 확정할 때는 release notes와 관련 product docs를 먼저 다시 연다.

## 대표 코드 발췌

```ts
if (feature('BRIDGE_MODE') && (args[0] === 'remote-control' || args[0] === 'rc' || args[0] === 'remote' || args[0] === 'sync' || args[0] === 'bridge')) {
  profileCheckpoint('cli_bridge_path');
  const { enableConfigs } = await import('../utils/config.js');
  enableConfigs();
  // ... bridge-specific auth and policy checks ...
}
```

이 발췌는 `src/entrypoints/cli.tsx`의 conditional fast-path 일부다. feature flag는 단지 설정 표가 아니라 실제 dispatch depth와 import cost를 바꾸는 구조라는 점을 보여 준다.

## 주요 조건부 기능

| 기능/flag | 활성화 지점 | 영향받는 장 | 추적 시 주의점 | 대표 근거 파일 |
| --- | --- | --- | --- | --- |
| `BRIDGE_MODE` | `src/entrypoints/cli.tsx`의 `remote-control` fast-path | `runtime-modes`, `remote-bridge`, `risks-debt` | build-time `feature()`와 runtime gate를 함께 봐야 한다 | `src/entrypoints/cli.tsx`, `src/bridge/bridgeEnabled.ts`, `src/bridge/bridgeMain.ts` |
| `DAEMON` | daemon fast-path와 `--daemon-worker` 분기 | `runtime-modes`, `task-model`, `risks-debt` | 실제 daemon 구현 모듈은 현재 snapshot에 포함되지 않으므로, 이 문서에서는 entrypoint call site 기준으로만 추적한다 | `src/entrypoints/cli.tsx` |
| `BG_SESSIONS` | `ps`, `logs`, `attach`, `kill`, `--bg` 경로 | `runtime-modes`, `task-model`, `end-to-end` | session-level background path와 개별 task를 혼동하기 쉽다 | `src/entrypoints/cli.tsx`, `src/query.ts` |
| `TEMPLATES` | template job command, stop hook classifier | `runtime-modes`, `context-assembly`, `reference` | job command와 stop hook 양쪽에 걸친다 | `src/entrypoints/cli.tsx`, `src/query/stopHooks.ts` |
| `VOICE_MODE` | voice UI, command, input enablement | `state-ui-terminal`, `risks-debt` | UI에 코드가 보여도 항상 활성이라고 보면 안 된다 | `src/voice/voiceModeEnabled.ts`, `src/services/voice.ts` |
| `WEB_BROWSER_TOOL` | browser panel/tool surface | `tool-system`, `state-ui-terminal`, `risks-debt` | tool surface와 UI surface를 같이 따라가야 한다 | `tools/`, `src/screens/REPL.tsx` |
| `COORDINATOR_MODE` | coordinator prompt/user context helper | `extension-coordination`, `risks-debt` | `src/QueryEngine.ts`에서 lazy import로 들어오는 점이 중요하다 | `src/coordinator/coordinatorMode.ts`, `src/QueryEngine.ts`, `src/main.tsx` |
| `KAIROS` | assistant mode, channels, related UX | `runtime-modes`, `state-ui-terminal`, `extension-coordination`, `risks-debt` | assistant 관련 코드가 `src/main.tsx`와 dialog/startup에 넓게 퍼져 있다 | `src/main.tsx`, `assistant/`, `components/` |
| `CONTEXT_COLLAPSE` | query loop의 context collapse recovery path | `context-assembly`, `risks-debt` | 세부 구현 모듈은 현재 snapshot에 없으므로, `feature('CONTEXT_COLLAPSE')`가 query loop에 끼어드는 지점만 추적한다 | `src/query.ts` |
| `HISTORY_SNIP` | transcript/history snip path | `context-assembly`, `turn-lifecycle`, `risks-debt` | REPL과 SDK/headless 경로의 차이를 같이 봐야 한다 | `src/query.ts`, `src/QueryEngine.ts` |
| `WORKFLOW_SCRIPTS` | workflow command/tool/task 계열 | `command-system`, `task-model`, `reference` | command surface와 task surface에 걸친다 | `commands/`, `tasks/` |
| `AGENT_TRIGGERS` | scheduled task/cron 관련 path | `task-model`, `risks-debt` | task 모델과 background execution 장에서 함께 봐야 한다 | `tasks/`, `src/query.ts` |
| `MONITOR_TOOL` | monitor tool/task path | `tool-system`, `task-model` | tool과 task 두 장의 경계에 걸친다 | `tools/`, `tasks/` |
| `UDS_INBOX` | peer/bridge messaging variants | `extension-coordination`, `remote-bridge` | messaging 변형이 bridge/network 설명 없이 나오면 맥락을 놓치기 쉽다 | `bridge/`, `src/tools/SendMessageTool/` |
| `FORK_SUBAGENT` | forked subagent path | `extension-coordination`, `reference` | agent flow와 tool/prompt가 동시에 바뀔 수 있다 | `src/tools/AgentTool/`, `commands/` |

## 구조 해석 팁

### build-time feature와 runtime gate는 다르다

예를 들어 `feature('BRIDGE_MODE')`는 빌드 산출물 수준의 dead code elimination과 연결된다. 반면 `getBridgeDisabledReason()` 같은 runtime check는 코드가 존재하는 상태에서 현재 사용자나 정책에 따라 기능을 막는다. 두 층을 섞어 읽으면 "코드에 있으니 항상 쓸 수 있다"는 잘못된 결론에 도달하기 쉽다.

### 조건부 기능은 장 간 경계를 흔든다

`COORDINATOR_MODE`, `KAIROS`, `BG_SESSIONS` 같은 기능은 한 장에만 갇히지 않는다. command, startup, query, task, UI, remote 흐름을 동시에 건드릴 수 있으므로, 본문 장에서는 해당 기능을 "주 장 + 보조 장" 조합으로 따라가는 편이 좋다.

## 관련 장

- 실행 모드 관점: [05-claude-code-runtime-modes-and-entrypoints.md](../02-runtime-and-session-start/05-claude-code-runtime-modes-and-entrypoints.md)
- startup/trust 관점: [06-claude-code-session-startup-trust-and-initialization.md](../02-runtime-and-session-start/06-claude-code-session-startup-trust-and-initialization.md)
- extension/coordination 관점: [05-claude-code-agent-skill-plugin-mcp-and-coordination.md](../05-execution-continuity-and-integrations/05-claude-code-agent-skill-plugin-mcp-and-coordination.md)
- 구조 리스크 관점: [06-claude-code-risks-debt-and-failure-modes.md](../06-boundaries-deployment-and-safety/06-claude-code-risks-debt-and-failure-modes.md)

## Sources / evidence notes

- 이 appendix는 Tier 6 observed artifact map이지만, feature availability나 default-state claim은 release notes와 product docs를 다시 확인한 뒤 적는 편이 맞다.
- drift 가능성이 큰 항목은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S10`, `S12`, `S14`, `S15`와 함께 다시 본다.
