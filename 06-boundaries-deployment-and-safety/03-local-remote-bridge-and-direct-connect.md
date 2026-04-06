# 03. local, remote, bridge, direct-connect

## 장 요약

겉으로 보기에는 모두 "원격 실행"처럼 보이지만, 실제로는 전혀 같은 경로가 아니다. local session, remote session attach, direct-connect bootstrap, bridge/assistant viewer family는 서로 다른 ownership model과 서로 다른 안전 경계를 가진다. Claude Code는 이 경로를 각기 다른 manager와 hook, command family로 드러내기 때문에 deployment-aware safety 문서의 좋은 사례가 된다.

## 범위와 비범위

이 장이 다루는 것:

- local과 remote execution family를 구분해야 하는 이유
- direct-connect와 remote attach의 계약 차이
- bridge/assistant viewer path가 왜 별도 family인지
- deployment family가 safety/approval contract에 어떤 차이를 만드는지

이 장이 다루지 않는 것:

- remote server backend 구현 전부
- WebSocket/SSE transport 내부 세부
- bridge runtime의 모든 subcommand

이 장은 deployment family의 경계 문서이며, [01-boundary-engineering-and-autonomy.md](01-boundary-engineering-and-autonomy.md), [02-sandboxing-permissions-and-policy-surfaces.md](02-sandboxing-permissions-and-policy-surfaces.md)와 함께 읽는 것이 좋다.
또한 여기서 말하는 family 구분은 현재 공개 build에서 확인 가능한 command wiring과 feature gate를 기준으로 하며, `DIRECT_CONNECT`, `KAIROS`, bridge 관련 진입점이 바뀌면 함께 재검증해야 한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/remote/RemoteSessionManager.ts`
- `src/remote/SessionsWebSocket.ts`
- `src/hooks/useRemoteSession.ts`
- `src/hooks/useDirectConnect.ts`
- `src/main.tsx`
- `src/remote/sdkMessageAdapter.ts`

외부 프레이밍:

- Anthropic, [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing), 2025-10-20
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

함께 읽으면 좋은 장:

- [../execution/02-state-resumability-and-session-ownership.md](../05-execution-continuity-and-integrations/01-state-resumability-and-session-ownership.md)
- [04-safety-autonomy-benchmark.md](04-safety-autonomy-benchmark.md)
- [../14-remote-bridge-server-and-upstreamproxy.md](05-claude-code-remote-bridge-server-and-upstream-proxy.md)

## 네 가지 family를 구분하라

| family | 핵심 owner | 대표 질문 |
| --- | --- | --- |
| local | local REPL / local process | 모든 state와 approval이 로컬에 있는가 |
| remote session attach | remote session client | 이미 존재하는 원격 세션에 어떻게 붙는가 |
| direct-connect | bootstrapper + local REPL | 원격 server가 session contract를 어떻게 발급하는가 |
| bridge / assistant viewer | bridge supervisor + viewer client | 누가 fleet-level/session-viewer contract를 담당하는가 |

이 분류가 중요한 이유는 naming보다 boundary placement 때문이다. client, bootstrapper, supervisor, viewer는 모두 다른 안전 계약을 가진다.

## remote session attach는 “기존 세션에 붙는 client”다

`RemoteSessionManager`는 remote CCR session을 관리하는 session-scoped client다. 코드 주석도 그 책임을 명시한다.

```ts
/**
 * Coordinates:
 * - WebSocket subscription for receiving messages from CCR
 * - HTTP POST for sending user messages to CCR
 * - Permission request/response flow
 */
export class RemoteSessionManager { ... }
```

이 class가 뜻하는 바는 분명하다. remote attach family의 핵심은 새 세션을 만드는 것이 아니라, 이미 존재하는 session stream과 permission flow를 local UI에 연결하는 것이다.

## SessionsWebSocket은 transport safety contract를 가진다

`src/remote/SessionsWebSocket.ts`는 reconnection, permanent close code, session-not-found retry budget을 정의한다.

```ts
const MAX_SESSION_NOT_FOUND_RETRIES = 3
const PERMANENT_CLOSE_CODES = new Set([
  4003, // unauthorized
])
```

이 코드는 deployment family마다 recovery contract가 다르다는 사실을 보여 준다. local REPL에서는 없는 문제인 reconnect budget, auth rejection, transient session-not-found는 remote attach family의 고유한 boundary다.

## direct-connect는 “session contract를 먼저 받는 bootstrap”이다

`src/main.tsx`의 `claude connect <url>` 경로는 먼저 `createDirectConnectSession()`을 호출해 session contract를 받고, 그 결과를 REPL launch에 넘긴다.

```ts
const session = await createDirectConnectSession({
  serverUrl: _pendingConnect.url,
  authToken: _pendingConnect.authToken,
  cwd: getOriginalCwd(),
  dangerouslySkipPermissions: _pendingConnect.dangerouslySkipPermissions
});
...
directConnectConfig = session.config;
```

`src/hooks/useDirectConnect.ts`는 그 contract(`wsUrl`, sessionId 등)를 바탕으로 `DirectConnectSessionManager`를 만들고, remote permission request를 local `ToolUseConfirm` queue로 변환한다.

```ts
const manager = new DirectConnectSessionManager(config, {
  onPermissionRequest: (request, requestId) => {
    ...
    const toolUseConfirm: ToolUseConfirm = { ... }
    setToolUseConfirmQueue(queue => [...queue, toolUseConfirm])
  },
  ...
})
```

즉 direct-connect family의 핵심은 attach가 아니라 bootstrap contract다. local UI는 여전히 foreground owner지만, session contract는 remote server가 발급한다.

## bridge / assistant viewer family는 viewer contract를 가진다

`src/main.tsx`는 `remote-control`을 bridge family로, `assistant [sessionId]`를 running bridge session에 붙는 viewer family로 다룬다.

```ts
// If somehow reached, delegate to bridgeMain.
const { bridgeMain } = await import('./bridge/bridgeMain.js');
await bridgeMain(process.argv.slice(3));
...
program.command('assistant [sessionId]')
  .description('Attach the REPL as a viewer client to a running bridge session...')
```

이 구조는 bridge/viewer family가 단순 remote attach와 다르다는 점을 보여 준다.

- bridge는 supervisor/control-plane 성격이 더 강하다.
- assistant viewer는 running bridge session을 보는 client 성격이 더 강하다.

둘을 같은 "원격 실행"으로만 부르면 fleet-level control plane과 session-scoped client를 혼동하게 된다.

## deployment family가 달라지면 approval contract도 달라진다

local path에서는 permission prompt가 local tool execution 앞에서 열린다. remote attach와 direct-connect에서는 remote request가 local queue로 bridge되고, local operator가 응답한 뒤 remote manager가 response를 돌려준다.

즉 same UI surface라 해도 safety contract는 family마다 다르다.

- local: local tool boundary
- remote attach: session-scoped remote permission relay
- direct-connect: bootstrap contract + remote permission relay
- bridge/viewer: viewer/supervisor semantics

이 차이를 모르면 deployment-aware safety 설명이 모두 흐려진다.

## 관찰, 원칙, 해석, 권고

관찰:

- remote session attach, direct-connect, bridge/viewer는 서로 다른 ownership model을 가진다.
- SessionsWebSocket은 remote family의 reconnect/auth contract를 드러낸다.
- direct-connect는 attach보다 bootstrap contract가 핵심이다.

원칙:

- deployment family를 먼저 구분한 뒤 safety/approval contract를 설명해야 한다.
- client, bootstrapper, supervisor, viewer를 같은 remote label로 묶지 말아야 한다.
- remote family에서는 reconnect와 permission relay도 safety artifact로 다뤄야 한다.

해석:

- Claude Code는 "원격 기능"을 하나로 뭉개지 않고, 서로 다른 contract family로 유지한다.
- deployment-aware safety 문서가 필요한 이유가 바로 여기에 있다.

권고:

- 새 하네스를 설명할 때 local/remote/bridge/direct-connect 계열을 먼저 표로 분리하라.
- remote UI가 같아 보여도 session contract를 누가 발급하는지, permission을 누가 최종 승인하는지 따로 적어라.
- reconnect budget과 auth rejection을 transport 세부가 아니라 safety/recovery contract로 취급하라.

## benchmark 질문

1. 이 경로는 local owner, remote client, bootstrapper, supervisor, viewer 중 무엇인가.
2. session contract를 누가 발급하고 누가 소비하는가.
3. permission approval이 어느 family에서 어디로 relay되는가.
4. reconnect/auth failure가 어떤 boundary로 설명되는가.

## 요약

deployment family를 구분하지 않으면 안전 경계도 흐려진다. Claude Code는 local, remote attach, direct-connect, bridge/viewer를 서로 다른 contract family로 드러내기 때문에, deployment-aware safety 문서를 쓰기에 좋은 사례다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/remote/RemoteSessionManager.ts`
   session-scoped remote client contract를 본다.
2. `src/remote/SessionsWebSocket.ts`
   reconnect/auth boundary를 확인한다.
3. `src/main.tsx`
   direct-connect와 bridge/viewer entry를 본다.
4. `src/hooks/useDirectConnect.ts`
   bootstrap contract가 local UI queue로 어떻게 이어지는지 확인한다.
5. `src/hooks/useRemoteSession.ts`
   remote attach family의 client behavior를 비교한다.
