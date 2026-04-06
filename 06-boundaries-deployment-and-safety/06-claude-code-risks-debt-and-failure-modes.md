# 06. Claude Code 설계 긴장, 부채, 실패 모드

## 장 요약

설계 긴장과 실패 모드는 특정 큰 파일 목록이 아니라, 장기 실행형 harness가 어떤 능력을 얻기 위해 어떤 유지보수 비용을 감수하는지를 구조적으로 보여 주는 단서다. 이 장은 그 문제를 Claude Code 사례에 적용한다. 이 스냅샷에서 비용의 핵심 렌즈는 boundary density, 즉 하나의 파일이나 실행 표면에 서로 다른 subsystem seam과 state transition이 얼마나 많이 겹쳐 있는가다. Anthropic의 [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing) (2025-10-20)는 더 적은 승인 피로와 더 큰 자율성을 얻기 위해 filesystem isolation과 network isolation을 함께 설계해야 한다고 말한다. Anthropic의 [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (2025-11-26)는 장기 작업에서 clean state와 structured artifact를 남기지 않으면 다음 세션이 바로 흔들린다고 설명한다. Lee et al., [Meta-Harness](https://arxiv.org/abs/2603.28052) (2026-03-30)은 harness 성능이 모델 가중치만이 아니라 harness code 자체에 크게 의존한다고 본다.

이 세 자료를 겹쳐 보면, 유지보수 비용은 우연히 생긴 부산물이 아니라 하네스 성능을 위해 지불하는 구조적 가격으로 읽는 편이 더 정확하다. Claude Code의 긴장점은 다섯 가지로 요약된다. 하나의 operator surface 아래에 너무 많은 boundary가 합쳐져 있다는 점, permission stack이 safety와 usability를 동시에 떠안는다는 점, long-running restore path가 세션 간 continuity를 책임지면서 coupling을 만든다는 점, mode breadth와 feature gates가 traceability 비용을 키운다는 점, 그리고 remote subtree가 적은 파일 수 안에 protocol density를 압축한다는 점이다.

## 왜 tension map이 필요한가

이 코드베이스를 다 읽고 나면 "어떻게 동작하는가"는 어느 정도 설명할 수 있다. 하지만 "어디서 유지보수 비용이 생기는가"는 다른 종류의 질문이다. 이 질문은 파일 크기보다 boundary density를 봐야 답할 수 있다. 예를 들어 `src/screens/REPL.tsx`가 크다고 해서 문제가 되는 것이 아니라, 그 파일이 query, remote, permission, history, cost, task, UI state를 동시에 접합하기 때문에 변경 영향 범위가 커진다.

따라서 이 장은 bug catalogue가 아니라 tension map이다. 어떤 설계 긴장이 어떤 코드 구역에 응축되는지, 그리고 그 긴장이 어떤 failure mode로 돌아오는지를 분리해서 보여 주는 것이 목적이다.

## 이 장의 근거와 범위

이 장의 관찰은 2026-04-02 기준 현재 공개 사본의 다음 대표 발췌 출처에 한정한다.

- `src/main.tsx`
- `src/screens/REPL.tsx`
- `src/query.ts`
- `src/QueryEngine.ts`
- `src/entrypoints/cli.tsx`
- `src/interactiveHelpers.tsx`
- `src/utils/permissions/permissions.ts`
- `src/utils/permissions/pathValidation.ts`
- `src/utils/permissions/permissionSetup.ts`
- `src/utils/permissions/PermissionUpdate.ts`
- `src/remote/RemoteSessionManager.ts`
- `src/remote/SessionsWebSocket.ts`
- `src/history.ts`
- `src/cost-tracker.ts`

외부 프레이밍에는 다음 자료를 사용한다.

- Anthropic, [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing), 2025-10-20
- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), 2026-03-30

Sources / evidence notes:
이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 Part 6 cluster를 따른다. debt catalog와 failure mode framing에는 `S5`, `S6`, `S15`, `S20`, `S30`, `S31`, `S32`를 우선 사용하고, `P2`는 optimization/debt comparison의 보조 프레임으로만 사용한다.

이 장은 다음을 다룬다.

- boundary density가 높은 hotspot
- permission subsystem이 만드는 safety/usability 긴장
- restore path와 hidden session-state coupling
- mode breadth와 feature-gated traceability 비용
- protocol-dense remote code와 file-count-heavy permissions code의 대비

구체적 버그 목록, 리팩터링 처방전, 성능 수치 리포트는 이 장의 범위를 벗어난다.

## 유지보수 비용을 만드는 다섯 가지 긴장

| 긴장 | 얻는 것 | 지불하는 비용 |
| --- | --- | --- |
| unified operator surface vs boundary density | 하나의 REPL에서 많은 기능을 일관되게 제공 | state와 transport 경계가 한 화면 아래 겹친다 |
| autonomy vs permission complexity | 승인 피로를 줄이면서 더 많은 자율성을 제공 | rule ordering, mode transition, persistence path가 복잡해진다 |
| long-running continuity vs restore coupling | 세션을 이어 가며 작업 지속 | transcript, metadata, cost, file history 복원이 서로 엮인다 |
| mode breadth vs traceability | 같은 product shell에서 bridge, direct-connect, ssh, background, headless 지원 | 실행 경로 추적과 regression surface가 넓어진다 |
| remote compactness vs protocol density | 적은 파일 수로 remote adapter를 응축 | lifecycle edge와 message semantics가 몇 개 파일에 과밀해진다 |

이 표의 요점은 복잡도가 단순한 구현 실수라기보다 기능적 가치와 맞바꾼 구조라는 점이다.

이 관찰을 운영 부채 언어로 다시 쓰면 catalog가 더 또렷해진다. docs drift, config sprawl, feature-flag drift, trace privacy debt, eval contamination debt, infrastructure-noise debt는 모두 코드 밖에서만 생기는 문제가 아니라 이 긴장 축이 장기간 누적된 결과로 읽을 수 있다.

## 제품 사실 1: 큰 파일의 문제는 길이가 아니라 boundary density다

현재 공개 사본에서 핵심 조립 파일의 길이는 다음과 같다.

- `src/main.tsx`: 4683줄
- `src/screens/REPL.tsx`: 5005줄
- `src/query.ts`: 1729줄
- `src/QueryEngine.ts`: 1295줄
- `src/interactiveHelpers.tsx`: 365줄

하지만 이 수치만으로는 충분하지 않다. 더 중요한 것은 `src/screens/REPL.tsx`가 실제로 몇 개의 concern을 한곳에 끌어 모으는지다.

```ts
import { useRemoteSession } from '../hooks/useRemoteSession.js';
import { useDirectConnect } from '../hooks/useDirectConnect.js';
import { useSSHSession } from '../hooks/useSSHSession.js';
...
import { getTotalCost, saveCurrentSessionCosts, resetCostState, getStoredSessionCosts } from '../cost-tracker.js';
...
import { addToHistory, removeLastFromHistory, expandPastedTextRefs, parseReferences } from '../history.js';
...
import { applyPermissionUpdate, applyPermissionUpdates, persistPermissionUpdate } from '../utils/permissions/PermissionUpdate.js';
...
import { query } from '../query.js';
```

관찰:

- 이 스냅샷에서 `src/screens/REPL.tsx`는 UI file이라기보다 interactive operator shell의 assembly zone에 가깝다.
- cost, history, permission persistence, remote transport, query loop가 한 파일 import graph 안에 동시에 드러난다.

해석:

- 유지보수 비용의 핵심은 LOC 그 자체가 아니라 boundary density다.
- `src/main.tsx`와 `src/screens/REPL.tsx`는 "큰 파일"이라서 위험한 것이 아니라, 서로 다른 subsystem의 seam이 너무 많이 겹쳐 있기 때문에 위험하다.

대표 failure mode:

- REPL의 resume/submit seam을 건드릴 때 history 입력 버퍼, permission context, cost summary 중 하나만 업데이트 순서에서 어긋나도 "입력 UI 수정이 세션 상태 불일치 regression으로 번지는" 식의 문제가 생길 수 있다.

## 제품 사실 2: permissions는 `utils/` 잡동사니가 아니라 별도 정책 엔진이다

이 분석 범위에서 `src/utils/permissions/`는 24개 파일이고, `remote/`는 4개 파일이다. 파일 수만 보면 permissions 쪽이 훨씬 넓고, 실제 내용은 그보다 더 깊다.

`src/utils/permissions/permissions.ts`는 permission pipeline 일부만 떼어 읽어도 이미 layered decision engine이라는 사실이 드러난다.

```ts
/**
 * Check only the rule-based steps of the permission pipeline
 */
export async function checkRuleBasedPermissions(
  tool: Tool,
  input: { [key: string]: unknown },
  context: ToolUseContext,
): Promise<PermissionAskDecision | PermissionDenyDecision | null> {
```

`src/utils/permissions/pathValidation.ts`는 단순 allow/deny가 아니라 deny rule, internal editable path, safety validation, working dir, internal readable path, sandbox write allowlist 순서로 경계를 해석한다.

```ts
// 1. Check deny rules first
...
// 2. internal editable paths
...
// 2.5. comprehensive safety validations
...
// 3. Check if path is in allowed working directory
...
// 3.7. sandbox write allowlist
```

`src/utils/permissions/permissionSetup.ts`는 모드 전환 때 dangerous allow rule을 strip/restore한다.

```ts
export function stripDangerousPermissionsForAutoMode(
  context: ToolPermissionContext,
): ToolPermissionContext {
```

그리고 `src/utils/permissions/PermissionUpdate.ts`는 최종 사용자 선택이 실제 settings source에 영속화되는 경로를 가진다.

```ts
export function persistPermissionUpdate(update: PermissionUpdate): void {
  if (!supportsPersistence(update.destination)) return
  ...
}
```

관찰:

- permissions는 단순 prompt yes/no를 묻는 UI가 아니라 rule ordering, path safety, mode transition, persistence까지 갖춘 별도 정책 엔진이다.
- safety와 usability가 같은 subtree 안에서 만난다.

해석:

- 이 로컬 관찰은 Anthropic의 sandboxing 글이 설명한 boundary engineering 일반 원리를 빌려 해석할 수 있다. 더 큰 자율성과 더 적은 승인 피로를 주려면, 단순 allowlist가 아니라 복잡한 policy surface가 필요해진다.
- 유지보수 관점에서 permissions는 `utils/` 아래 숨은 helper 모음이 아니라 명시적으로 큰 하위 시스템으로 다뤄야 한다.

대표 failure mode:

- path validation이나 mode transition의 순서를 잘못 건드리면 예상치 못한 auto-allow 또는 불필요한 deny가 발생해 safety/usability 균형이 바로 깨질 수 있다.

## 제품 사실 3: long-running continuity는 hidden session-state coupling을 만든다

장기 실행 하네스가 다음 세션으로 이어지려면 state를 복원해야 한다. 문제는 그 복원이 transcript 하나로 끝나지 않는다는 점이다. `src/screens/REPL.tsx`의 resume 복원 구간만 봐도 file history, agent setting, standalone agent context, read-file state, cost state가 함께 복원된다.

```ts
restoreSessionStateFromLog(log, setAppState);
if (log.fileHistorySnapshots) {
  void copyFileHistoryForResume(log);
}
...
restoreReadFileState(messages, log.projectPath ?? getOriginalCwd());
...
const targetSessionCosts = getStoredSessionCosts(sessionId);
```

`src/history.ts`는 prompt history를 세션과 프로젝트 기준으로 다시 읽고,

```ts
/**
 * Get history entries for the current project, with current session's entries first.
 */
export async function* getHistory(): AsyncGenerator<HistoryEntry> {
```

`src/cost-tracker.ts`는 마지막 세션 비용을 복원한다.

```ts
export function restoreCostStateForSession(sessionId: string): boolean {
  const data = getStoredSessionCosts(sessionId)
  if (!data) {
    return false
  }
```

그리고 `src/query.ts`는 tool call 이후 다음 turn state를 다시 누적한다.

```ts
const next: State = {
  messages: [...messagesForQuery, ...assistantMessages, ...toolResults],
  toolUseContext: toolUseContextWithQueryTracking,
  ...
}
```

관찰:

- 이 스냅샷에서 continuity는 transcript만의 문제가 아니라 file history, agent metadata, cost state, query state accumulation이 함께 맞물리는 문제다.
- resume와 continuation이 강해질수록 hidden coupling도 증가한다.

해석:

- 이 로컬 관찰은 `Effective harnesses for long-running agents`가 말하는 clean state와 structured artifact 원리를 빌려 해석할 수 있다. continuity가 강점이 되려면 다음 세션이 이전 세션의 흔적을 잘 읽어야 하지만, 그만큼 restore path는 취약해진다.
- 유지보수 측면에서 이 영역의 failure mode는 "한 기능이 깨진다"보다 "세션 전환의 믿음성 전체가 흔들린다"는 데 있다.

대표 failure mode:

- transcript, file history, cost state 중 하나만 restore contract에서 어긋나도 resumed session이 실제 이전 상태와 다르게 보이는 drift가 생길 수 있다.

## 제품 사실 4: mode breadth와 feature gates는 traceability 비용을 키운다

이 분석 범위에서 `src/main.tsx`, `src/screens/REPL.tsx`, `src/query.ts`, `src/QueryEngine.ts`, `src/interactiveHelpers.tsx` 다섯 파일에만 `feature(...)` 호출이 171개 있다. 여기에 `src/entrypoints/cli.tsx`의 fast-path fan-out까지 겹치면, 실행 경로를 한 번에 머릿속에 유지하기가 매우 어렵다.

`src/entrypoints/cli.tsx`는 bridge, daemon, background session 같은 경로를 초기 단계에서 분기한다.

```ts
if (feature('BRIDGE_MODE') && ...) {
  ...
  await bridgeMain(args.slice(1))
  return
}
```

`src/interactiveHelpers.tsx`는 trust dialog, MCP approval, external include approval, bypass permissions, auto mode opt-in을 한 함수 아래 묶는다.

```ts
// Always show the trust dialog in interactive sessions
...
await handleMcpjsonServerApprovals(root);
...
if (await shouldShowClaudeMdExternalIncludesWarning()) {
  ...
}
...
if ((permissionMode === 'bypassPermissions' || allowDangerouslySkipPermissions) && !hasSkipDangerousModePermissionPrompt()) {
```

관찰:

- mode breadth는 기능 풍부함을 주지만, regression surface를 크게 넓힌다.
- feature gate는 build-time dead-code elimination에 유리하지만, 코드 독해 시 어떤 경로가 실제로 활성인지 확신하기 어렵게 만든다.
- docs와 benchmark artifact가 이 변화 속도를 따라가지 못하면 설명 부채도 함께 커진다.

해석:

- traceability 비용은 거대한 함수 하나보다 "분기 수 x 상태 수 x 모드 수"의 곱에 더 가깝다.
- 이 프로젝트를 읽거나 수정할 때는 기능별 ownership보다 mode별 activation path를 먼저 분리해야 실수를 줄일 수 있다.

대표 failure mode:

- feature gate나 fast-path 분기를 한 군데서만 보고 수정하면 특정 mode에서는 통과하지만 다른 mode에서는 전혀 다른 activation path를 타는 ambiguity가 생길 수 있다.

## 제품 사실 5: remote는 small subtree지만 protocol-dense하다

`remote/`는 4개 파일뿐이지만, 그 안에는 session client, websocket transport, remote permission bridge, message adapter가 들어 있다. `src/remote/RemoteSessionManager.ts`는 receive/send/permission flow를 한 객체에 모으고,

```ts
/**
 * Manages a remote CCR session.
 *
 * Coordinates:
 * - WebSocket subscription for receiving messages from CCR
 * - HTTP POST for sending user messages to CCR
 * - Permission request/response flow
 */
```

`src/remote/SessionsWebSocket.ts`는 compaction 중 `4001`을 transient session-not-found로 처리한다.

```ts
// 4001 (session not found) can be transient during compaction
if (closeCode === 4001) {
  this.sessionNotFoundRetries++
  ...
}
```

관찰:

- remote는 파일 수는 적지만 protocol과 lifecycle semantics가 압축돼 있다.
- `RemoteSessionManager`가 pending permission request를 추적하고 `SessionsWebSocket`이 compaction 중 `4001`을 특별 취급한다는 점은, 이 subtree가 단순 transport wrapper가 아니라 lifecycle edge와 message-handling seam을 직접 떠안는다는 뜻이다.
- permissions는 file-count-heavy subsystem이고, remote는 protocol-dense subsystem이다.

해석:

- 유지보수 비용 지도를 그릴 때 단순히 "어디 파일이 많은가"만 보면 안 된다.
- 어떤 영역은 breadth 때문에 어렵고, 어떤 영역은 protocol density 때문에 어렵다. Claude Code는 이 두 종류의 비용을 둘 다 가진다.

대표 failure mode:

- 1차 위험은 compaction 시점의 reconnect처럼 lifecycle edge가 겹칠 때 session continuity가 흔들리는 것이다.
- 2차 결과는 permission control request나 message handling이 같은 subtree에 얽혀 있어, 작은 transport 수정도 message-semantic regression으로 이어질 수 있다는 점이다.

## 이 장에서 가져가야 할 benchmark 질문

1. 이 hotspot의 비용은 파일 길이 때문인가, boundary density 때문인가.
2. 이 subsystem이 주로 떠안는 긴장은 다섯 축 중 무엇인가: boundary density, permission complexity, restore coupling, traceability, remote protocol density.
3. 이 경로의 failure mode는 개별 기능 오동작인가, 아니면 예를 들어 permission mode transition, resume restore, remote reconnect 같은 운영 결정 경계의 실패인가.
4. file-count-heavy 영역과 protocol-dense 영역을 같은 유지보수 척도로 보고 있지 않은가.
5. 이 복잡도는 제거해야 할 잡음인가, 아니면 제품 가치와 직접 맞물린 구조적 비용인가.
6. config sprawl, trace privacy debt, eval contamination debt 중 무엇이 이미 code-adjacent risk로 보이는가.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/screens/REPL.tsx`
2. `src/utils/permissions/permissions.ts`
3. `src/utils/permissions/pathValidation.ts`
4. `src/utils/permissions/permissionSetup.ts`
5. `src/query.ts`
6. `src/main.tsx`
7. `src/interactiveHelpers.tsx`
8. `src/remote/RemoteSessionManager.ts`
9. `src/remote/SessionsWebSocket.ts`
10. `src/history.ts`
11. `src/cost-tracker.ts`

## 요약

이 코드베이스의 유지보수 비용은 단순히 "기능이 많다"에서 오지 않는다. 하나의 operator surface 아래에 많은 boundary가 겹치고, permission stack이 자율성과 안전을 동시에 떠안고, long-running restore path가 continuity와 coupling을 함께 만들고, mode breadth가 traceability 비용을 키우고, remote subtree는 적은 파일 수 안에 protocol density를 압축하기 때문에 복잡하다. Claude Code를 사례로 읽을 때 중요한 것은 위험 구역을 막연히 표시하는 것이 아니라, 어떤 가치 때문에 어떤 설계 긴장을 감수하고 있는지 구조적으로 구분하는 일이다.
