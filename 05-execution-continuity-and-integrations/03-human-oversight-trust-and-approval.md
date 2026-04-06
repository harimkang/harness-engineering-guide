# 03. 인간 감독, trust, approval fatigue

## 장 요약

하네스가 자율성을 높일수록 인간 감독은 사라지지 않고 재배치된다. 중요한 것은 "승인을 몇 번 받는가"보다 "어디서 trust를 확정하고, 어디서 action approval을 요청하며, 어떤 예외를 bypass-immune하게 남기고, 승인 피로를 어떻게 계측하는가"다. Claude Code는 trust dialog, bypass mode gate, tool-specific permission request, permission analytics를 서로 다른 층으로 분리해 이 문제를 보여 준다.

## 범위와 비범위

이 장이 다루는 것:

- workspace trust와 action approval을 왜 구분해야 하는지
- bypass mode/auto mode가 approval fatigue를 어떻게 재배치하는지
- tool-specific permission UI와 permission analytics가 어떤 감독 구조를 만드는지

이 장이 다루지 않는 것:

- sandboxing 세부 메커니즘 전부
- 개별 permission request UI 컴포넌트의 모든 시각적 차이
- 조직 정책과 제품 정책의 비기술적 운영 세부
- trace privacy와 evidence pack retention 세부
- prompt caching과 infrastructure noise 세부

이 장은 [01-boundary-engineering-and-autonomy.md](../06-boundaries-deployment-and-safety/01-boundary-engineering-and-autonomy.md), [02-sandboxing-permissions-and-policy-surfaces.md](../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md), [05-ui-transcripts-and-operator-control.md](../04-interfaces-and-operator-surfaces/05-ui-transcripts-and-operator-control.md)와 밀접하게 연결된다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/interactiveHelpers.tsx`
- `src/components/permissions/PermissionRequest.tsx`
- `src/components/permissions/hooks.ts`
- `src/utils/permissions/permissionSetup.ts`
- `src/utils/permissions/permissions.ts`
- `src/setup.ts`
- `src/screens/REPL.tsx`

외부 프레이밍:

- Anthropic, [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing), 2025-10-20
- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24

Sources / evidence notes:
이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 Part 5 cluster를 따른다. 핵심 source ID는 `S5`, `S6`, `S8`, `S9`, `S10`, `S15`, `S28`이다.

함께 읽으면 좋은 장:

- [04-safety-autonomy-benchmark.md](../06-boundaries-deployment-and-safety/04-safety-autonomy-benchmark.md)
- [07-claude-code-tool-system-and-permissions.md](../04-interfaces-and-operator-surfaces/07-claude-code-tool-system-and-permissions.md)
- [05-ui-transcripts-and-operator-control.md](../04-interfaces-and-operator-surfaces/05-ui-transcripts-and-operator-control.md)
- [02-task-orchestration-and-long-running-execution.md](02-task-orchestration-and-long-running-execution.md)
- [08-observability-traces-and-run-artifacts.md](08-observability-traces-and-run-artifacts.md)

## trust boundary는 session 시작에서 열린다

`src/interactiveHelpers.tsx`는 interactive session에서 permission mode와 무관하게 trust dialog를 먼저 강제한다.

```ts
// The trust dialog is the workspace trust boundary ...
// bypassPermissions mode only affects tool execution permissions, not workspace trust.
if (!checkHasTrustDialogAccepted()) {
  const { TrustDialog } = await import('./components/TrustDialog/TrustDialog.js');
  await showSetupDialog(root, done => <TrustDialog commands={commands} onDone={done} />);
}
...
setSessionTrustAccepted(true);
resetGrowthBook();
void initializeGrowthBook();
void getSystemContext();
```

이 흐름이 중요한 이유는 trust가 tool approval보다 더 앞선 층이라는 사실을 명확히 보여 주기 때문이다.

- trust는 "이 workspace를 어떤 가정 아래 열 것인가"를 정한다.
- action approval은 "지금 이 호출을 허용할 것인가"를 정한다.

둘을 같은 yes/no dialog로 취급하면 사용자는 무엇을 승인하는지 이해하기 어렵고, fatigue만 늘어난다.

## bypass와 auto는 감독을 없애는 것이 아니라 재배치한다

Claude Code는 위험 모드를 켤 때도 별도 gate를 둔다.

```ts
if ((permissionMode === 'bypassPermissions' || allowDangerouslySkipPermissions) &&
    !hasSkipDangerousModePermissionPrompt()) {
  const { BypassPermissionsModeDialog } = await import('./components/BypassPermissionsModeDialog.js');
  await showSetupDialog(root, done => <BypassPermissionsModeDialog onAccept={done} />);
}
```

즉 bypass/auto mode는 "승인을 없앴다"가 아니라, 승인의 위치를 바꾸거나 일부 surface를 사전 확정했다는 뜻이다. 이 distinction이 중요하다.

- trust dialog는 남는다.
- 일부 content-specific ask rule과 safety check는 bypass-immune으로 남는다.
- auto mode는 classifier와 safe allowlist를 통해 fatigue를 줄이되, 완전한 무감독 모드가 아니다.

## action approval은 tool semantics에 맞게 shaped된다

`src/components/permissions/PermissionRequest.tsx`는 tool 종류별로 다른 permission component를 붙인다.

```ts
function permissionComponentForTool(tool: Tool): React.ComponentType<PermissionRequestProps> {
  switch (tool) {
    case FileEditTool:
      return FileEditPermissionRequest;
    case BashTool:
      return BashPermissionRequest;
    case ExitPlanModeV2Tool:
      return ExitPlanModePermissionRequest;
    ...
  }
}
```

이 구조는 감독이 generic modal 하나로 해결되지 않는다는 사실을 보여 준다. filesystem edit, shell execution, plan transition, ask-user-question은 각각 다른 위험 모델과 operator 질문을 가진다. 따라서 approval surface도 tool semantics에 맞게 shaped되어야 한다.

## bypass-immune 예외가 있어야 trust가 무너지지 않는다

`src/utils/permissions/permissions.ts`는 일부 ask/deny 경로를 bypassPermissions mode보다 앞에 둔다.

```ts
// Safety checks ... are bypass-immune — they must prompt even in bypassPermissions mode.
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
  return { behavior: 'allow', ... }
}
```

이 ordering은 supervision design에서 핵심이다. bypass mode가 있어도 모든 approval이 사라지는 것이 아니고, safety-critical edge는 그대로 남아 operator를 다시 loop 안으로 불러들인다. 이것이 없으면 trust boundary는 너무 쉽게 무너진다.

## approval fatigue는 계측되어야 한다

감독 설계는 UI 흐름만의 문제가 아니다. `src/components/permissions/hooks.ts`는 permission prompt가 뜰 때 attribution counter를 올리고 analytics event를 남긴다.

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

이것이 중요한 이유는 approval fatigue가 추상적 UX 불만이 아니라 측정 가능한 운영 문제이기 때문이다.

- 어떤 tool이 반복적으로 prompt를 띄우는가
- 어떤 decision reason이 fatigue를 유발하는가
- sandbox가 켜졌을 때 prompt 양상이 어떻게 달라지는가

감독 설계는 결국 이런 trace 없이 개선하기 어렵다.

또한 fatigue를 줄이는 방법은 ask를 무조건 없애는 것이 아니다. 어떤 action은 auto-allow나 classifier-assisted path로 보내고, 어떤 action은 bypass-immune하게 남기며, 어떤 경우에는 내용을 일부 가린 상태로도 승인할 수 있게 해야 한다. 따라서 approval 설계는 trust, explanation quality, masking/redaction, reversible action을 함께 다뤄야 한다.

## 위험한 allow rule을 미리 막는 것도 감독의 일부다

`src/utils/permissions/permissionSetup.ts`는 auto mode에서 위험한 Bash/PowerShell allow rule을 탐지한다. 예를 들어 tool-level allow, wildcard, interpreter prefix 등은 classifier를 우회해 arbitrary code execution을 허용할 수 있으므로 dangerous pattern으로 취급한다.

```ts
/**
 * Dangerous patterns:
 * 1. Tool-level allow (Bash with no ruleContent) - allows ALL commands
 * 2. Prefix rules for script interpreters (python:*, node:*, etc.)
 * 3. Wildcard rules matching interpreters (python*, node*, etc.)
 */
```

이 부분은 중요한 교훈을 준다. 인간 감독은 dialog를 많이 띄우는 것만이 아니라, 애초에 너무 넓은 allow surface가 만들어지지 않게 rule authoring을 제한하는 작업까지 포함한다.

## 관찰, 원칙, 해석, 권고

관찰:

- trust boundary는 session 시작에서 열리고, action approval은 tool execution 경로에서 열린다.
- bypass/auto mode는 감독을 삭제하는 것이 아니라 approval burden을 재배치한다.
- 일부 safety check와 content-specific ask rule은 bypass-immune으로 유지된다.
- permission prompt count와 decision reason은 계측되어 fatigue analysis 입력이 된다.

원칙:

- trust와 approval을 같은 층으로 설계하면 안 된다.
- fatigue management는 approval 제거가 아니라 approval 재배치와 rule shaping의 문제다.
- 위험한 allow rule은 runtime 전에 authoring 단계에서부터 제어해야 한다.
- approval burden은 operator UX 지표이면서 safety 지표다.

해석:

- Anthropic의 sandboxing 글이 강조한 "permission prompt 자체보다 더 구조적인 안전/자율성 설계"는 이 코드베이스에서 trust dialog, bypass-immune safety check, analytics instrumentation으로 구체화된다.
- 인간 감독은 autonomy의 반대말이 아니라, autonomy가 어디서 멈추고 어디서 다시 승인받는지 정의하는 control layer다.

권고:

- 새 하네스를 설계할 때는 반드시 `trust`, `action approval`, `fatigue management`를 별도 표로 정리하라.
- bypass mode가 있더라도 bypass-immune edge를 최소 하나 이상 명시하라.
- permission prompt의 개수만 세지 말고, 어떤 decision reason이 반복되는지도 함께 계측하라.
- approval fatigue 측정값을 trace/diagnostic artifact와 연결해 두어야 나중에 원인을 다시 분해할 수 있다.

## Review scaffold

- trust acceptance, action approval, auto-allow, bypass-immune edge를 한 장표에서 분리해 설명할 수 있어야 한다.
- masking/redaction 없이 approval만 재배치하고 있지 않은지 확인하라.
- approval fatigue를 줄였다는 주장은 prompt 수뿐 아니라 decision reason, revoke 가능성, 설명 품질까지 함께 봐야 한다.

## benchmark 질문

1. trust boundary와 action approval이 명확히 구분되는가.
2. bypass/auto mode가 감독을 없애는 대신 어떻게 재배치하는지 설명할 수 있는가.
3. safety-critical approval은 bypass-immune하게 남아 있는가.
4. approval fatigue를 정량적으로 읽을 signal이 있는가.

## 요약

인간 감독은 자율성과 반대말이 아니다. Claude Code는 trust dialog, bypass gate, tool-specific permission request, permission analytics를 서로 다른 층으로 배치해 이 사실을 잘 보여 준다. 좋은 execution 문서는 승인 횟수가 아니라 승인 구조를 설명해야 한다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/interactiveHelpers.tsx`
   trust boundary와 위험 모드 gate가 어디서 열리는지 본다.
2. `src/components/permissions/PermissionRequest.tsx`
   tool-specific approval surface dispatch를 확인한다.
3. `src/utils/permissions/permissions.ts`
   bypass-immune 예외와 allow/ask ordering을 본다.
4. `src/utils/permissions/permissionSetup.ts`
   위험한 allow rule을 어떻게 막는지 확인한다.
5. `src/components/permissions/hooks.ts`
   approval fatigue가 어떻게 계측되는지 본다.
