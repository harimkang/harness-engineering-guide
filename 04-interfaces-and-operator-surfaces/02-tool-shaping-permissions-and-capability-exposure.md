# 02. tool shaping, permission, capability exposure

## 장 요약

좋은 tool system은 "있는 capability를 다 보여 주는가"보다 "무엇을 언제 보여 주고, 언제 다시 심사하고, 어떤 allow rule을 애초에 위험한 것으로 막는가"를 더 중요하게 다룬다. Claude Code는 capability exposure를 한 층으로, call-time permission을 또 다른 층으로, dangerous rule authoring guardrail을 그 앞단의 층으로 나눠 둔다. 이 장은 그 세 층을 함께 읽는다.

## 범위와 비범위

이 장이 다루는 것:

- pre-exposure shaping과 call-time permission의 차이
- bypass/always-allow/ask/deny가 어떻게 ordering되는지
- 위험한 allow rule을 왜 authoring 단계에서 막아야 하는지

이 장이 다루지 않는 것:

- 각 permission prompt UI의 시각적 세부
- sandboxing 메커니즘 전체
- trust dialog 자체의 startup semantics

이 주제들은 [03-human-oversight-trust-and-approval.md](../05-execution-continuity-and-integrations/03-human-oversight-trust-and-approval.md), [02-sandboxing-permissions-and-policy-surfaces.md](../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md)에서 다시 다룬다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/utils/permissions/permissionSetup.ts`
- `src/utils/permissions/permissions.ts`
- `src/Tool.ts`
- `src/components/permissions/PermissionRequest.tsx`
- `src/components/permissions/hooks.ts`

외부 프레이밍:

- Anthropic, [Writing effective tools for agents — with agents](https://www.anthropic.com/engineering/writing-tools-for-agents), 2025-09-11
- Anthropic, [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing), 2025-10-20
- Anthropic Platform Docs, [Agent SDK overview](https://platform.claude.com/docs/en/agent-sdk/overview), 확인 2026-04-02

함께 읽으면 좋은 장:

- [01-tool-contracts-and-the-agent-computer-interface.md](01-tool-contracts-and-the-agent-computer-interface.md)
- [03-commands-skills-plugins-and-mcp.md](03-commands-skills-plugins-and-mcp.md)
- [04-safety-autonomy-benchmark.md](../06-boundaries-deployment-and-safety/04-safety-autonomy-benchmark.md)

## 세 층으로 읽어라

| 층 | 질문 | 대표 코드 |
| --- | --- | --- |
| authoring-time guardrail | 어떤 allow rule은 애초에 너무 위험한가 | `src/utils/permissions/permissionSetup.ts` |
| pre-exposure shaping | 이 세션에서 어떤 capability가 아예 보일 것인가 | tool pool + permission context shaping |
| call-time permission | 지금 이 호출을 allow/ask/deny 중 어떻게 처리할 것인가 | `src/utils/permissions/permissions.ts`, PermissionRequest |

이 셋을 구분하지 않으면 capability exposure와 operator fatigue를 같은 문제로 오해하게 된다.

최신 MCP 문맥에서는 여기에 authorization/privacy 질문도 붙는다. roots나 resource advertisement는 coordination signal일 수 있지만, 그 자체가 보안 경계나 privacy guarantee는 아니다. 어떤 capability를 노출했는가와, 누가 호출을 승인하는가와, 어떤 데이터가 실제로 전송되는가는 분리해서 서술해야 한다.

## 위험한 allow rule은 authoring 단계에서 막아야 한다

`src/utils/permissions/permissionSetup.ts`는 auto mode에서 dangerous Bash/PowerShell permission을 따로 판정한다. 예를 들어 tool-level allow, wildcard, interpreter prefix는 classifier 안전장치를 우회할 수 있어 위험 규칙으로 간주된다.

```ts
/**
 * Dangerous patterns:
 * 1. Tool-level allow (Bash with no ruleContent) - allows ALL commands
 * 2. Prefix rules for script interpreters (python:*, node:*, etc.)
 * 3. Wildcard rules matching interpreters (python*, node*, etc.)
 */
```

이 guardrail은 중요한 설계 메시지를 준다. capability exposure 문제는 call-time permission에서만 해결되지 않는다. 어떤 permission rule은 애초에 너무 넓어서, operator에게 prompt를 띄우기 전에 authoring 단계에서 막아야 한다.

## call-time permission은 단순 yes/no dialog가 아니다

`src/utils/permissions/permissions.ts`는 deny/ask/allow를 한 번에 정하지 않는다. tool implementation의 deny, user-interaction requirement, content-specific ask rule, bypass-immune safety check, mode-based bypass, always-allow rule이 순차적으로 적용된다.

```ts
if (
  toolPermissionResult?.behavior === 'ask' &&
  toolPermissionResult.decisionReason?.type === 'safetyCheck'
) {
  return toolPermissionResult
}
...
const shouldBypassPermissions =
  appState.toolPermissionContext.mode === 'bypassPermissions' ||
  ...
if (shouldBypassPermissions) {
  return {
    behavior: 'allow',
    ...
  }
}
```

이 ordering이 바로 capability exposure와 permission boundary를 구분해야 하는 이유다.

- 어떤 capability는 visible하더라도 safety check 때문에 ask를 강제한다.
- 어떤 capability는 mode/rule 때문에 call-time에 바로 allow된다.
- 어떤 capability는 아예 tool pool shaping 단계에서 안 보일 수도 있다.

## operator experience는 decision reason과 함께 이해해야 한다

`src/utils/permissions/permissions.ts`의 `createPermissionRequestMessage()`는 왜 prompt가 떴는지 decision reason을 operator 언어로 바꿔 준다. rule, hook, mode, permissionPromptTool, safetyCheck 등 서로 다른 원인을 अलग 설명한다.

즉 permission은 단순 동작 제어가 아니라 explanation surface이기도 하다. 좋은 harness는 operator가 "왜 지금 승인하라고 하는지"를 이해하게 해야 한다.

## tool semantics에 맞는 approval surface가 필요하다

`src/components/permissions/PermissionRequest.tsx`는 tool 종류에 따라 다른 permission component를 붙인다.

```ts
switch (tool) {
  case FileEditTool:
    return FileEditPermissionRequest;
  case BashTool:
    return BashPermissionRequest;
  case AskUserQuestionTool:
    return AskUserQuestionPermissionRequest;
  ...
}
```

이 구조는 capability exposure와 approval surface가 같은 층이 아니라는 사실을 다시 보여 준다. 같은 "ask"라도 file edit, shell execution, ask-user-question은 operator에게 다른 맥락과 다른 설명을 요구한다.

## permission fatigue는 shaping과 analytics 양쪽에서 다뤄야 한다

`src/components/permissions/hooks.ts`는 permission prompt가 뜰 때 attribution counter를 올리고 analytics event를 남긴다.

```ts
setAppState(prev => ({
  ...prev,
  attribution: {
    ...prev.attribution,
    permissionPromptCount: prev.attribution.permissionPromptCount + 1,
  },
}))

logEvent('tengu_tool_use_show_permission_request', {
  toolName: sanitizeToolNameForAnalytics(toolUseConfirm.tool.name),
  decisionReasonType: toolUseConfirm.permissionResult.decisionReason?.type,
  sandboxEnabled: SandboxManager.isSandboxingEnabled(),
})
```

즉 permission fatigue는 call-time 경험일 뿐 아니라, later tuning을 위한 measurement surface이기도 하다. 너무 많은 ask를 줄이려면 shaping, authoring guardrail, analytics 세 층을 함께 봐야 한다.

따라서 fatigue 대응은 단순히 prompt 수를 줄이는 문제가 아니다. 반복 승인 감소, 민감 action의 bypass-resistant 유지, explanation quality, masking/redaction, revoke 가능성을 함께 설계해야 한다. approval burden은 operator UX 지표이면서 safety 지표다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 dangerous rule guardrail, shaping, call-time permission을 분리한다.
- bypass mode가 있어도 bypass-immune safety check는 남는다.
- operator explanation과 fatigue analytics가 permission pipeline 안에 내장돼 있다.

원칙:

- capability exposure와 permission decision은 분리해서 설계해야 한다.
- capability exposure, authorization, privacy는 서로 다른 심사 질문이다.
- 위험한 allow rule은 authoring 단계에서 막아야 한다.
- permission 시스템은 decision engine일 뿐 아니라 explanation engine이기도 해야 한다.

해석:

- Anthropic이 말하는 secure autonomy는 prompt 수를 줄이는 문제가 아니라, 어느 층에서 어떤 approval을 남길지 재배치하는 문제라는 점이 이 코드베이스에서 분명해진다.
- Claude Code의 permission layer는 capability exposure를 보정하는 두 번째, 세 번째 경계로 작동한다.

권고:

- 새 harness를 설계할 때는 permission 설계를 `authoring`, `exposure`, `call-time` 세 층으로 나눠 문서화하라.
- bypass mode를 도입하더라도 bypass-immune edge를 명시하라.
- decision reason을 operator가 읽을 수 있는 언어로 바꾸는 surface를 별도로 두라.

## Review scaffold

- 어떤 capability가 숨겨지는지, 어떤 capability가 보이지만 `ask` 상태인지, 어떤 capability가 허용되더라도 데이터는 마스킹되는지 구분해서 적어 보라.
- MCP나 remote surface를 쓴다면 advertised roots와 실제 authorization boundary를 같은 것으로 설명하고 있지 않은지 점검하라.
- approval fatigue를 측정하는 지표가 없다면 permission UX를 아직 설계했다고 보기 어렵다.

## benchmark 질문

1. 이 시스템은 capability exposure와 call-time permission을 한 단계로 뭉개고 있지 않은가.
2. bypass mode가 있어도 남아야 할 safety-critical ask가 정의돼 있는가.
3. dangerous allow rule을 authoring 단계에서 막는가.
4. operator가 왜 prompt를 보게 됐는지 설명할 수 있는가.

## 요약

tool shaping은 단순 allowlist가 아니다. 그것은 어떤 capability를 보여 줄지, 어떤 호출을 다시 심사할지, 어떤 rule은 아예 금지할지를 함께 설계하는 일이다. Claude Code는 이 세 층을 로컬 코드에서 비교적 선명하게 보여 준다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/utils/permissions/permissionSetup.ts`
   authoring-time guardrail을 먼저 본다.
2. `src/Tool.ts`
   tool contract가 어떤 shaping 단서를 가지는지 본다.
3. `src/utils/permissions/permissions.ts`
   call-time decision ordering을 확인한다.
4. `src/components/permissions/PermissionRequest.tsx`
   tool-specific approval surface를 본다.
5. `src/components/permissions/hooks.ts`
   fatigue measurement surface를 확인한다.
