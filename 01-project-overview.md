# 01. 프로젝트 개관

## 장 요약

이 장은 `claude-code`를 단순한 CLI 애플리케이션이 아니라, 하네스 엔지니어링 사례로 읽어야 하는 이유를 먼저 설명한다. 표면적으로 보면 이 저장소는 터미널에서 실행하는 도구처럼 보인다. 하지만 실제 코드를 따라가 보면, 이 프로젝트는 여러 실행 경로, startup 정책, interactive 세션, query/control loop, task 실행, 원격 연결, 확장 표면을 한 저장소 안에서 함께 운영한다. 따라서 이 프로젝트를 이해할 때는 "무슨 기능이 있나"보다 "어떤 운영 문제들이 한 런타임 안에 겹쳐 있는가"를 먼저 보는 편이 맞다.

이 장의 목적은 세 가지다. 첫째, Claude Code를 왜 좋은 하네스 사례로 볼 수 있는지 설명한다. 둘째, 이 저장소를 처음 읽는 독자가 무엇을 먼저 볼지, 무엇을 나중으로 미룰지 결정하게 돕는다. 셋째, 이후 장에서 더 자세히 분해할 여섯 개의 축, 즉 실행 모드, startup과 trust, query와 control, 도구/작업 표면, 운영자 제어 표면, 원격/확장 계층을 한 번에 잡게 만든다.

## 왜 이 장이 필요한가

먼저 용어를 짧게 고정하자. 이 책에서 말하는 "하네스 엔지니어링"은 모델을 한 번 호출하는 프롬프트 기법이 아니라, 모델이 도구를 쓰고 세션을 유지하고 사람과 상호작용하며 실패에서 회복하도록 만드는 운영 시스템 설계를 뜻한다. 따라서 하네스는 배선 묶음 같은 일반 용어가 아니라, agent runtime을 둘러싼 구조적 장치를 가리킨다.

Claude Code는 Anthropic이 공개한 터미널 중심 coding/agent harness 소스 스냅샷으로 읽으면 된다. 이 책은 그 공개 스냅샷을 완전한 제품 구현 전체로 취급하지 않고, 공개 범위 안에서 확인 가능한 실행 경계와 운영 구조를 사례로 삼는다.

처음 이 저장소를 열면 보통 `src/main.tsx`, `src/query.ts`, `src/screens/REPL.tsx` 같은 큰 파일이 먼저 눈에 들어온다. 하지만 이 파일들을 바로 읽기 시작하면 어느 파일이 진입점이고, 어느 파일이 조립자이며, 어느 파일이 실제 런타임 정책을 갖는지 구분하기 어렵다. 이 장은 "이 저장소를 단순 CLI로 보면 왜 오해하는가", "복잡도가 어디서 생기는가", "이 사례를 어떤 질문으로 읽어야 하는가"를 먼저 고정해 준다.

Anthropic의 [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)와 [Agent SDK overview](https://platform.claude.com/docs/en/agent-sdk/overview)는 agent를 단순 자동화 스크립트보다 넓은 설계 선택의 집합으로 보게 만든다. Claude Code는 바로 그런 문제들이 공개 코드 안에 동시에 드러나는 사례다. 이 장은 그 점을 입구에서 명확히 한다.

## 이 장의 공개 사본 기준

이 장의 모든 관찰은 2026-04-01 기준 현재 공개 사본을 바탕으로 한다. 이 사본은 커밋 해시 없이 배포될 수 있으므로, 이 장은 우선 날짜와 파일 경로, 그리고 본문에 제시된 재현 가능한 코드 절단면을 기준으로 읽는다. 코드 인용은 모두 이 공개 사본에서 직접 확인 가능한 범위에 한정하며, 이후 시점에 구조가 달라질 수 있다는 점을 독자는 염두에 두어야 한다.

## 이 장의 범위

- Claude Code를 하네스 사례로 읽는 이유
- 공개 스냅샷으로 무엇을 볼 수 있고 무엇을 볼 수 없는지
- 상위 파일/디렉터리 구조가 드러내는 시스템 성격
- 이후 장을 읽기 위한 질문 중심 입구

## 용어 미리 보기

이 장에서 자주 나오는 용어는 아주 짧게 다음처럼 잡아 두면 좋다.

| 용어 | 이 장에서의 의미 |
| --- | --- |
| 하네스 | 모델, 도구, 세션, 정책, UI를 함께 묶는 운영 시스템 |
| 런타임 셸 | 여러 실행 경로와 상태를 조립하는 바깥 구조 |
| 운영자 제어 표면 | 사람이 현재 상태를 읽고 개입하는 표면 |
| MCP | tool/resource/prompt를 노출하는 확장 프로토콜 계층 |

## 이 장의 비범위

- 실행 모드 분기의 세부 로직
- startup/trust 흐름의 세부 정책
- query loop, task lifecycle, remote transport의 상세 구현
- 개별 command/tool/task의 완전한 설명

## 이 저장소를 사례로 읽어야 하는 이유

이 프로젝트가 흥미로운 이유는, 모델 호출부보다 그 주변 운영 구조가 더 두껍기 때문이다. 일반적인 "터미널 기반 LLM 도구"를 상상하면 사용자 입력, 모델 호출, 응답 출력 정도만 떠올리기 쉽다. 하지만 Claude Code의 공개 사본에서는 다음 질문이 모두 코드 수준에서 드러난다.

1. 실행 경로는 하나인가, 여러 개인가
2. startup 단계에서 trust와 policy는 어디에 개입하는가
3. query loop는 단순 요청 함수인가, 상태를 가진 control loop인가
4. tool, command, task, skill, plugin, MCP는 어떤 계층 관계를 가지는가
5. UI는 단순 렌더링인가, 운영자 제어 표면인가
6. remote/bridge/direct-connect는 배포 제약과 경계 설계를 어떻게 바꾸는가

즉, 이 저장소는 "기능 목록"보다 "하네스 운영 문제들의 결합 방식"을 보여주는 사례에 가깝다.

## 먼저 봐야 할 운영 문제 분류

이 장에서 Claude Code를 읽을 때는 기능 이름보다 다음 운영 문제 분류를 먼저 떠올리는 편이 좋다.

| 운영 문제 | 이 저장소에서 드러나는 대표 위치 | 이후 자세히 읽을 장 |
| --- | --- | --- |
| 실행 경로 분기 | `src/entrypoints/cli.tsx`, `src/main.tsx` | [03-runtime-modes-and-entrypoints.md](./03-runtime-modes-and-entrypoints.md), [14-remote-bridge-server-and-upstreamproxy.md](./14-remote-bridge-server-and-upstreamproxy.md) |
| startup과 정책 개입 | `src/main.tsx`, `src/interactiveHelpers.tsx` | [04-session-startup-trust-and-initialization.md](./04-session-startup-trust-and-initialization.md) |
| query/control loop | `src/context.ts`, `src/query.ts`, `src/QueryEngine.ts` | [05-context-assembly-and-query-pipeline.md](./05-context-assembly-and-query-pipeline.md), [06-query-engine-and-turn-lifecycle.md](./06-query-engine-and-turn-lifecycle.md) |
| 운영자 제어 표면 | `src/screens/REPL.tsx`, `src/commands.ts`, `src/tools.ts` | [07-command-system.md](./07-command-system.md), [08-tool-system-and-permissions.md](./08-tool-system-and-permissions.md), [09-state-ui-and-terminal-interaction.md](./09-state-ui-and-terminal-interaction.md) |
| task와 장기 실행 | `src/Task.ts`, `src/tasks.ts` | [12-task-model-and-background-execution.md](./12-task-model-and-background-execution.md) |
| 원격/확장 계층 | `services/`, `bridge/`, `remote/`, `server/` | [10-services-and-integrations.md](./10-services-and-integrations.md), [11-agent-skill-plugin-mcp-and-coordination.md](./11-agent-skill-plugin-mcp-and-coordination.md), [14-remote-bridge-server-and-upstreamproxy.md](./14-remote-bridge-server-and-upstreamproxy.md) |

이 표를 먼저 잡고 읽으면, 뒤에서 만나는 큰 파일들이 "덩치가 큰 이유"를 기능 수가 아니라 운영 문제 수로 이해할 수 있다.

## 이 책을 관통하는 러닝 예시

처음 읽는 독자라면 아래의 한 장면을 계속 붙들고 가는 편이 좋다.

1. 사용자가 `claude`를 실행한다.
2. CLI는 어떤 runtime family로 갈지 분기한다.
3. interactive path라면 startup/trust gate를 지난다.
4. REPL이 열리고 사용자가 첫 prompt를 입력한다.
5. query loop가 context를 조립하고, 필요하면 tool과 permission 경계를 통과한다.
6. 결과가 다시 UI와 transcript로 돌아온다.

이 러닝 예시는 뒤의 장에서 다음처럼 다시 나타난다.

- [02-architecture-map.md](./02-architecture-map.md): 이 흐름을 여섯 파일 구조로 압축한다.
- [03-runtime-modes-and-entrypoints.md](./03-runtime-modes-and-entrypoints.md): 1-2단계를 자세히 본다.
- [04-session-startup-trust-and-initialization.md](./04-session-startup-trust-and-initialization.md): 3단계를 자세히 본다.
- [05-context-assembly-and-query-pipeline.md](./05-context-assembly-and-query-pipeline.md)와 [06-query-engine-and-turn-lifecycle.md](./06-query-engine-and-turn-lifecycle.md): 4-5단계를 자세히 본다.
- [17-end-to-end-scenarios.md](./17-end-to-end-scenarios.md): 전체를 다시 시간 순서로 합친다.

이 장의 역할은 이 여섯 단계 중 어디에 어떤 운영 문제가 숨어 있는지 미리 보여 주는 것이다.

## 사례를 읽는 세 개의 렌즈

이 장에서는 Claude Code를 다음 세 렌즈로 읽는 것이 좋다고 제안한다.

### 1. 런타임 셸

관찰:

- 이 프로젝트는 단일 요청 처리기가 아니라 여러 실행 모드와 진입 경로를 가진다.

해석:

- Claude Code는 단일 도구가 아니라 런타임 셸로 읽는 편이 자연스럽다.

### 2. 정책 개입 시스템

관찰:

- Claude Code는 startup과 query 사이에 trust, permission, approval, managed settings 같은 정책 표면을 둔다.

해석:

- 모델 품질만으로는 설명할 수 없는 운영 제약이 구조 안에 녹아 있다.

### 3. 운영자 제어 표면으로서의 하네스

관찰:

- 이 프로젝트의 핵심 표면은 API보다 터미널과 세션에 가깝다.

해석:

- Claude Code는 “agent를 어떻게 운영 가능한 상태로 만들 것인가”를 보여주는 사례로 읽는 편이 맞다.

## 공개 스냅샷으로 볼 수 있는 것과 없는 것

이 장에서 다루는 사실은 모두 현재 공개 사본에서 직접 확인 가능한 범위에 한정된다.

### 볼 수 있는 것

- 공개 사본 source tree의 파일 구조와 디렉터리 규모
- 진입점과 조립 지점
- feature gate와 runtime 분기
- 상태 전이, recovery path, permission path 같은 설계 흔적

### 이 장에서 보지 않는 것

- 저장소 외부 백엔드 구현
- 완전한 CI/CD 파이프라인
- 과거 커밋 의도
- 공개 스냅샷에 없는 운영 지표

즉, 이 장은 "공개된 구조가 무엇을 시사하는가"까지만 다루며, 보이지 않는 내부 구현을 추정하지 않는다.

## 핵심 증거 1: CLI는 모든 경로의 단일 시작점이 아니다

다음 코드는 `src/entrypoints/cli.tsx`의 early fast-path 일부다.

```ts
if (args.length === 1 && (args[0] === '--version' || args[0] === '-v' || args[0] === '-V')) {
  console.log(`${MACRO.VERSION} (Claude Code)`);
  return;
}
```

같은 파일 안에는 아래처럼 bridge mode와 daemon mode로 빠지는 별도 분기도 존재한다.

```ts
if (feature('BRIDGE_MODE') && (args[0] === 'remote-control' || args[0] === 'rc' || args[0] === 'remote' || args[0] === 'sync' || args[0] === 'bridge')) {
  await bridgeMain(args.slice(1));
  return;
}
if (feature('DAEMON') && args[0] === 'daemon') {
  await daemonMain(args.slice(1));
  return;
}
```

관찰:

- `--version` 계열 인자가 들어오면 이 분기는 즉시 종료한다.
- bridge mode와 daemon mode도 entrypoint 수준에서 빠르게 갈라진다.
- `src/main.tsx`는 모든 실행 경로의 유일한 시작점이 아니다.

해석:

- 이 저장소는 단일 interactive path 하나로 환원되지 않는다.
- entrypoint 수준의 빠른 종료 경로 자체가 설계 대상이다.

이 블록은 Claude Code를 단순 REPL 앱으로 읽으면 부족하다는 점을 보여준다.

설계 함의:

- 이 프로젝트의 entrypoint는 "하나의 main flow"보다 "여러 운영 경로를 dispatch하는 shell"에 가깝다.

## 핵심 증거 2: startup은 비용을 먼저 관리하는 조립 단계다

다음 코드는 `src/main.tsx` 상단 일부다.

```ts
profileCheckpoint('main_tsx_entry');
startMdmRawRead();
startKeychainPrefetch();
```

관찰:

- `src/main.tsx`는 무거운 초기화 이전에 profiling과 사전 준비 작업을 시작한다.
- startup 자체가 latency와 초기 준비 비용을 다루는 구간으로 보인다.

해석:

- 이 파일은 단순 옵션 파서가 아니라 runtime assembly 파일에 가깝다.
- Claude Code는 "모델 호출" 이전 단계부터 이미 하네스 문제를 푼다.

설계 함의:

- startup 비용을 줄이는 일은 하네스 설계에서 별도 최적화 대상이 될 수 있다.

## 핵심 증거 3: startup 정책은 실제 코드 경로 안에 들어와 있다

다음 코드는 `src/main.tsx`의 startup 일부다.

```ts
const onboardingShown = await showSetupScreens(
  root,
  permissionMode,
  allowDangerouslySkipPermissions,
  commands,
  enableClaudeInChrome,
  devChannels,
);
```

관찰:

- interactive startup은 실제로 `showSetupScreens()`를 통과한다.
- setup과 trust, approval 계열의 정책 개입이 별도 문서가 아니라 런타임 경로 안에 존재한다.

해석:

- Claude Code는 정책 개입 시스템으로 읽는 편이 맞다.

설계 함의:

- trust와 approval은 UI 바깥의 문서 절차가 아니라 실제 runtime path 안에 들어갈 수 있다.

다음 코드는 `src/entrypoints/cli.tsx`의 remote control policy limit 일부다.

```ts
await waitForPolicyLimitsToLoad();
if (!isPolicyAllowed('allow_remote_control')) {
  exitWithError("Error: Remote Control is disabled by your organization's policy.");
}
```

관찰:

- 정책 제한은 실제 코드 경로에서 차단 조건으로 작동한다.

해석:

- 정책 개입은 설명 문구가 아니라 실제 enforce 지점을 가진다.

## 핵심 증거 4: 원격 연결은 별도 transport와 세션 경로를 가진다

다음 코드는 `src/main.tsx`의 direct connect 일부다.

```ts
const session = await createDirectConnectSession({
  serverUrl: _pendingConnect.url,
  authToken: _pendingConnect.authToken,
  cwd: getOriginalCwd(),
  dangerouslySkipPermissions: _pendingConnect.dangerouslySkipPermissions
});
```

관찰:

- 원격 연결은 별도 세션 생성 경로를 가진다.
- local interactive path와 동일한 단일 흐름으로 환원되지 않는다.

해석:

- remote/bridge/direct-connect는 단순 옵션 차이가 아니라 배포 경계와 권한 모델을 바꾸는 축이다.

설계 함의:

- 원격 연결 계열은 “같은 기능의 다른 진입 방식”이 아니라, 별도 세션 생성과 권한 모델을 갖는 경계 문제로 읽어야 한다.

## 핵심 증거 5: REPL은 단순 UI가 아니라 세션 orchestrator다

다음 코드는 `src/screens/REPL.tsx`의 query 진입 일부다.

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

관찰:

- REPL은 query loop의 event stream을 직접 소비한다.
- UI와 query orchestration이 분리돼 있으면서도 매우 가깝게 연결돼 있다.

해석:

- 이 프로젝트의 UI는 단순 렌더링 계층이 아니라 운영자 제어 표면에 가까운 런타임 셸이다.
- Claude Code를 이해하려면 REPL을 화면이 아니라 제어 표면으로 읽어야 한다.

설계 함의:

- agent product에서 UI는 결과 표시가 아니라 세션 제어와 상태 가시성의 일부가 될 수 있다.

## 핵심 증거 6: 확장 계층은 별도 부가 기능이 아니라 조립 일부다

다음 코드는 `src/main.tsx` 상단의 import 일부다.

```ts
import { getMcpToolsCommandsAndResources, prefetchAllMcpResources } from './services/mcp/client.js';
import { initBundledSkills } from './skills/bundled/index.js';
```

관찰:

- MCP와 bundled skills는 별도 부가 기능이 아니라 초기 조립 경로 안에 나타난다.

해석:

- tool/task surface와 extension 계층은 선택적 후처리가 아니라 runtime shell 일부로 읽는 편이 맞다.

## 상위 구조가 말해주는 것

현재 공개 사본 기준으로 source tree의 큰 영역은 다음과 같다. 아래 수치는 2026-04-01 기준 공개 사본에서 각 디렉터리의 파일 수를 집계한 값이다. 집계는 각 디렉터리 아래의 파일 수를 세는 단순 파일 수 기준이다.

| 디렉터리 | 파일 수 | 시사점 |
| --- | ---: | --- |
| `utils/` | 564 | 횡단 helper와 runtime support가 복잡도 대부분을 흡수한다 |
| `components/` | 389 | terminal UI 계층이 크다는 뜻이다 |
| `commands/` | 207 | 운영자 command surface가 넓다 |
| `tools/` | 184 | 모델이 호출하는 action surface가 넓다 |
| `services/` | 130 | 외부 API와 integration 계층이 두껍다 |
| `hooks/` | 104 | UI와 runtime을 잇는 glue layer가 크다 |
| `ink/` | 96 | terminal rendering과 input 제어가 독립 계층으로 존재한다 |

이 숫자들은 이 저장소가 "모델 한 번 호출하는 CLI"보다, "여러 surface와 service layer가 결합된 terminal system"에 더 가깝다는 점을 정량적으로 뒷받침한다.

## 이 장에서 잡아야 할 핵심 질문

이후 장을 읽을 때는 아래 질문을 계속 들고 가면 좋다.

1. 이 구조는 어떤 운영 문제를 해결하려는가
2. 이 문제는 runtime, policy, UI, tool, task, remote 중 어느 축에 속하는가
3. 지금 읽는 문장은 관찰인가, 해석인가, 권고인가
4. 내 하네스를 설계한다면 여기서 무엇을 그대로 가져가고 무엇을 다르게 할 것인가

이 질문을 쓸 때는 다음 순서를 권장한다.

1. 먼저 관찰을 적는다.
2. 그다음 그 관찰이 어떤 운영 문제를 가리키는지 해석한다.
3. 마지막으로 그 해석에서 설계 함의를 뽑는다.

이 질문이 있어야 사례 장이 기능 설명으로 흩어지지 않고, 하네스 설계 교재의 일부로 연결된다.

## 다음에 읽을 곳

이 장에서 구조적 감각을 잡았다면 다음 순서가 자연스럽다.

1. [02-architecture-map.md](./02-architecture-map.md)
   방금 잡은 운영 문제 분류를 전체 구조 지도로 다시 본다.
2. [03-runtime-modes-and-entrypoints.md](./03-runtime-modes-and-entrypoints.md)
   여러 실행 경로가 실제로 어떻게 갈라지는지 세부적으로 본다.
3. [04-session-startup-trust-and-initialization.md](./04-session-startup-trust-and-initialization.md)
   startup과 정책 개입이 실제로 어디에 삽입되는지 본다.
4. [05-context-assembly-and-query-pipeline.md](./05-context-assembly-and-query-pipeline.md)
   하네스의 핵심 자원인 context와 query preparation이 실제로 어떻게 조립되는지 본다.

## 요약

Claude Code는 단순한 CLI 앱이 아니라, 여러 실행 경로, 정책 경계, query loop, command/tool/task surface, UI state, remote/extension 계층이 한 저장소 안에 겹쳐 있는 하네스 사례다. 이 장의 목적은 그 사실을 먼저 고정해 두는 것이다. 이 저장소를 "기능 목록"으로 읽기 시작하면 길을 잃기 쉽다. 반대로 "운영 문제들의 결합 방식"으로 읽기 시작하면 이후 장 전체가 더 잘 연결된다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/entrypoints/cli.tsx`
   `--version`, bridge, daemon 같은 fast-path가 얼마나 이른 단계에서 갈라지는지 먼저 본다.
2. `src/main.tsx`
   startup prefetch와 interactive assembly가 어떻게 배치되는지 본다.
3. `src/screens/REPL.tsx`
   interactive operator surface가 query, task, remote를 어떤 방식으로 끌어안는지 확인한다.
4. `src/query.ts`
   "한 턴이 실제로 어디서 조립되고 이어지는가"를 확인한다.
5. 필요할 때만 `services/`, `bridge/`, `remote/`
   이 장의 목적은 세부 구현 전수조사가 아니라, 어떤 하위 계층이 존재하는지 감을 잡는 데 있다.
