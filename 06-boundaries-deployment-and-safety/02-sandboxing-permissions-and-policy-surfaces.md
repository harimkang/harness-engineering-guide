# 02. sandboxing, permissions, policy surface

## 장 요약

permission prompt만 보고 안전을 설명하면 대부분 틀린다. 실제 제품에서는 trust dialog, permission mode, dangerous rule stripping, sandbox runtime config, MCP trust check, channel permission relay, elicitation queue가 서로 다른 층에서 동시에 작동한다. 이 장의 목적은 그 policy surface를 한꺼번에 보이게 만드는 데 있다.

## 범위와 비범위

이 장이 다루는 것:

- sandbox와 permission이 왜 다른 층인지
- policy surface가 startup, settings, call-time, deployment에서 어떻게 펼쳐지는지
- MCP 관련 side-channel 정책 surface가 왜 별도 관심사인지

이 장이 다루지 않는 것:

- sandbox runtime 내부 구현 전부
- 모든 MCP auth/transport 세부
- trust dialog UX 자체의 시각적 상세
- governance translation layer 전체

이 장은 safety 파트의 구조 장이며, [01-boundary-engineering-and-autonomy.md](01-boundary-engineering-and-autonomy.md) 위에서 읽고 [03-local-remote-bridge-and-direct-connect.md](03-local-remote-bridge-and-direct-connect.md)로 이어지는 것이 좋다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/interactiveHelpers.tsx`
- `src/utils/permissions/permissionSetup.ts`
- `src/utils/permissions/permissions.ts`
- `src/utils/sandbox/sandbox-adapter.ts`
- `src/services/mcp/headersHelper.ts`
- `src/services/mcp/channelPermissions.ts`
- `src/services/mcp/elicitationHandler.ts`

외부 프레이밍:

- Anthropic, [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing), 2025-10-20
- Anthropic, [Writing effective tools for agents — with agents](https://www.anthropic.com/engineering/writing-tools-for-agents), 2025-09-11
- Anthropic Docs, [Claude Agent SDK overview](https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-overview), verified 2026-04-06
- NIST, [AI RMF Generative AI Profile](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence), verified 2026-04-06

Sources / evidence notes:
이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 Part 6 cluster를 따른다. 핵심 source ID는 `S5`, `S9`, `S15`, `S16`, `S17`, `S20`, `S25`, `S30`, `S31`이다. `S3`와 `S13`은 tool-writing 및 SDK surface를 비교하는 보조 프레임으로만 사용한다.

함께 읽으면 좋은 장:

- [03-human-oversight-trust-and-approval.md](../05-execution-continuity-and-integrations/03-human-oversight-trust-and-approval.md)
- [04-safety-autonomy-benchmark.md](04-safety-autonomy-benchmark.md)
- [../08-tool-system-and-permissions.md](../04-interfaces-and-operator-surfaces/07-claude-code-tool-system-and-permissions.md)
- [07-governance-risk-and-compliance-mapping.md](07-governance-risk-and-compliance-mapping.md)

## policy surface의 다섯 층

| 층 | 핵심 질문 | 대표 코드 |
| --- | --- | --- |
| startup trust | 이 workspace를 열어도 되는가 | `src/interactiveHelpers.tsx` |
| settings/policy authoring | 어떤 rule은 애초에 위험한가 | `src/utils/permissions/permissionSetup.ts` |
| call-time permission | 지금 이 action을 allow/ask/deny 중 어떻게 처리할까 | `src/utils/permissions/permissions.ts` |
| sandbox runtime | 허용된 action도 어느 filesystem/network 범위 안에서만 실행될까 | `src/utils/sandbox/sandbox-adapter.ts` |
| protocol side-channel | MCP와 remote path에서 추가로 필요한 policy는 무엇인가 | `src/services/mcp/headersHelper.ts`, `src/services/mcp/channelPermissions.ts`, `src/services/mcp/elicitationHandler.ts` |

이 다섯 층을 한 policy layer로 뭉개면 operator 경험도, architecture 설명도 곧바로 흐려진다.

최신 MCP authorization 문맥을 붙이면 한 가지 주의점이 더 필요하다. roots나 resource advertisement는 coordination signal일 수 있지만, 그 자체가 sandbox도 아니고 authorization boundary도 아니다. sandbox, permission, remote auth를 같은 표면으로 뭉개면 정책 책임을 잘못 배치하게 된다.

## sandbox는 permission과 다른 질문에 답한다

`src/utils/sandbox/sandbox-adapter.ts`는 Claude Code의 settings format을 sandbox runtime config로 변환한다. 이때 filesystem/network restriction, managed domains, path resolution semantics를 별도로 다룬다.

```ts
export function convertToSandboxRuntimeConfig(
  settings: SettingsJson,
): SandboxRuntimeConfig {
  const permissions = settings.permissions || {}
  ...
  for (const ruleString of permissions.allow || []) {
    const rule = permissionRuleValueFromString(ruleString)
    if (
      rule.toolName === WEB_FETCH_TOOL_NAME &&
      rule.ruleContent?.startsWith('domain:')
    ) {
      allowedDomains.push(rule.ruleContent.substring('domain:'.length))
    }
  }
}
```

이 코드는 sandbox가 permission prompt의 다른 UI 버전이 아니라는 점을 보여 준다. sandbox는 filesystem/network envelope를 다루고, permission은 action decision을 다룬다. 둘은 겹치지만 동일하지 않다.

## call-time permission은 explanation surface까지 포함한다

`src/utils/permissions/permissions.ts`는 deny/ask/allow를 결정할 뿐 아니라, 왜 그런 결정을 했는지 operator에게 설명하는 message도 만든다.

```ts
return `Permission rule '${ruleString}' from ${sourceString} requires approval for this ${toolName} command`
...
return `Current permission mode (${modeTitle}) requires approval for this ${toolName} command`
```

policy surface를 설계할 때 이 점이 중요하다. policy는 enforcement만이 아니라 explanation도 해야 한다. 설명할 수 없는 policy는 결국 operator fatigue와 mistrust를 만든다.

## startup trust 이후에야 일부 policy surface가 열린다

`src/interactiveHelpers.tsx`는 trust가 확정된 뒤에만 일부 MCP approval과 environment application을 진행한다.

```ts
// Now that trust is established ...
await handleMcpjsonServerApprovals(root)
...
applyConfigEnvironmentVariables()
...
setImmediate(() => initializeTelemetryAfterTrust())
```

이 ordering이 중요한 이유는 policy surface가 단순 "tool permission"보다 훨씬 넓다는 사실을 보여 주기 때문이다. environment variables, MCP headers helper, telemetry initialization도 trust boundary 뒤에서만 열리는 policy surface다.

## MCP는 별도의 side-channel policy를 추가한다

MCP 관련 policy는 일반 local tool path보다 한 단계 더 복잡하다.

### headersHelper trust check

`src/services/mcp/headersHelper.ts`는 project/local settings에서 온 headers helper가 trust 확인 전에는 실행되지 않도록 막는다.

```ts
if (!hasTrust) {
  ...
  logEvent('tengu_mcp_headersHelper_missing_trust', {})
  return null
}
```

### channel permission relay

`src/services/mcp/channelPermissions.ts`는 structured channel event로 permission reply를 주고받는 separate relay surface를 정의한다.

```ts
export type ChannelPermissionResponse = {
  behavior: 'allow' | 'deny'
  fromServer: string
}
```

### elicitation queue

`src/services/mcp/elicitationHandler.ts`는 URL/browser-confirmation류의 explicit elicitation을 AppState queue에 넣고, hook이나 UI response로 resolve한다.

```ts
client.setRequestHandler(ElicitRequestSchema, async (request, extra) => {
  ...
  setAppState(prev => ({
    ...prev,
    elicitation: {
      queue: [
        ...prev.elicitation.queue,
        { serverName, requestId: extra.requestId, params: request.params, ... }
      ],
    },
  }))
})
```

이 세 surface는 MCP가 단순 tool injection이 아니라 독자적인 policy side-channel을 동반한다는 점을 보여 준다.

즉 remote MCP를 설명할 때는 transport, authn/authz, elicitation, local approval relay를 따로 적는 편이 낫다. remote policy surface는 local tool policy의 부록이 아니라 별도 위험 표면이다.

## bypass와 auto mode는 policy surface를 평평하게 만들지 않는다

dangerous rule stripping, bypass-immune safety check, sandbox environment, MCP trust check를 함께 보면, bypass/auto mode가 policy surface를 완전히 평평하게 만들지 않는다는 점이 분명하다. 일부 경계는 자동화되고, 일부 경계는 오히려 더 강해진다.

좋은 안전 문서는 이 재배치를 드러내야 한다.

## 관찰, 원칙, 해석, 권고

관찰:

- sandbox와 permission은 서로 다른 층의 정책 surface다.
- trust 이후에야 열리는 MCP/env/telemetry surface가 존재한다.
- MCP는 headers helper, channel permission, elicitation 같은 별도 policy channel을 추가한다.

원칙:

- policy surface는 startup, authoring, call-time, environment, protocol 층으로 나눠 문서화해야 한다.
- sandbox는 permission을 대체하지 않고 보완해야 한다.
- remote/protocol surface가 생기면 local policy model만으로는 충분하지 않다.
- roots나 advertised scope를 security boundary처럼 설명하지 말아야 한다.

해석:

- Anthropic의 sandboxing 원칙은 이 코드베이스에서 prompt surface 밖의 settings/runtime/protocol policy로 구체화된다.
- Claude Code는 permission-centric safety 설명을 넘어, policy surface 전체를 읽게 만드는 사례다.

권고:

- 새 하네스를 설계할 때는 sandbox 정책과 permission 정책을 따로 표로 정리하라.
- MCP나 외부 protocol을 붙일 때는 headers, elicitation, reply relay 같은 side-channel policy를 별도 장으로 문서화하라.
- trust 이후에 열리는 민감 surface가 무엇인지 명확히 적어라.
- architecture review를 염두에 둔다면 control objective와 supporting evidence도 같이 적어라.

## Review scaffold

- sandbox, permission, remote auth/authz, elicitation을 서로 다른 통제로 분리해 설명할 수 있어야 한다.
- roots나 resource advertisement를 enforcement boundary처럼 쓰고 있지 않은지 확인하라.
- policy surface마다 control objective와 evidence artifact가 연결되는지 점검하라.

## benchmark 질문

1. sandbox와 permission을 같은 층으로 오해하고 있지 않은가.
2. startup 이후에만 열려야 할 policy surface가 정의돼 있는가.
3. MCP/remote protocol이 추가될 때 새로운 policy side-channel이 설명되는가.
4. bypass/auto mode가 policy surface를 어떻게 재배치하는지 말할 수 있는가.

## 요약

안전은 prompt 승인 하나로 끝나지 않는다. Claude Code의 policy surface는 trust, permission, sandbox, MCP side-channel까지 겹친 다층 구조다. 이 구조를 같이 읽어야만 자율성과 안전을 실제 운영 언어로 설명할 수 있다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/interactiveHelpers.tsx`
   startup trust 이후에 열리는 surface를 본다.
2. `src/utils/permissions/permissionSetup.ts`
   settings/policy authoring guardrail을 확인한다.
3. `src/utils/permissions/permissions.ts`
   call-time permission reasoning을 본다.
4. `src/utils/sandbox/sandbox-adapter.ts`
   environment envelope를 확인한다.
5. `src/services/mcp/headersHelper.ts`, `src/services/mcp/channelPermissions.ts`, `src/services/mcp/elicitationHandler.ts`
   protocol side-channel policy를 비교한다.
