# 01. boundary engineering과 autonomy

> Why this chapter exists: autonomy를 더 키울수록 boundary를 덜 두는 것이 아니라 더 정밀하게 설계해야 한다는 점을 고정한다.
> Reader level: advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: medium

## Core claim

autonomy와 safety는 단일 슬라이더가 아니다. trust, permission, sandbox, remote/MCP, deployment boundary를 서로 다른 층으로 설계해야 높은 autonomy와 reviewable control을 함께 만들 수 있다.

## What this chapter is not claiming

- approval prompt 수만 줄이면 autonomy 설계가 끝난다는 주장
- sandbox 하나로 boundary engineering이 충분하다는 주장
- governance/compliance가 기술 설계를 대체할 수 있다는 주장

## 장 요약

자율성을 높인다고 해서 경계를 지울 수는 없다. 실제로는 그 반대다. 더 많은 autonomy를 허용할수록, 무엇을 어느 층에서 열고 닫을지 더 정밀하게 설계해야 한다. Claude Code는 trust dialog, dangerous-rule stripping, call-time permission, sandbox runtime, MCP trust checks, remote permission relay 같은 여러 경계를 겹쳐 autonomy를 조절한다. 이 장은 그 구조를 boundary engineering이라는 이름으로 읽는다.

## Mental model / diagram

이 장의 핵심 mental model은 `trust -> authoring -> exposure -> call-time -> environment -> deployment` 여섯 boundary 층이다. 아래 boundary table을 이 장의 중심 도식으로 읽으면 된다.

## Design implications

- autonomy 설계 문서는 approval mode 하나가 아니라 trust, exposure, sandbox, deployment boundary를 분리해 보여줘야 한다.
- bypass mode가 있어도 bypass-immune edge를 명시하지 않으면 operator는 실제 safety contract를 오해한다.
- local, remote, direct-connect 경로는 같은 capability라도 다른 approval owner를 가질 수 있으므로 boundary matrix를 path별로 점검해야 한다.

## 범위와 비범위

이 장이 다루는 것:

- autonomy를 가능하게 만드는 layered boundary의 필요성
- trust, permission, sandbox, remote/MCP 경계가 왜 서로 다른 층인지
- boundary engineering을 설계 언어로 쓰는 이유

이 장이 다루지 않는 것:

- sandbox runtime 내부 메커니즘 전부
- 개별 permission prompt UI의 세부
- 법적/조직적 governance 구조

이 장은 safety 파트의 problem-setting 장이며, [02-sandboxing-permissions-and-policy-surfaces.md](02-sandboxing-permissions-and-policy-surfaces.md), [03-local-remote-bridge-and-direct-connect.md](03-local-remote-bridge-and-direct-connect.md)에서 각 boundary를 더 구체적으로 다룬다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/interactiveHelpers.tsx`
- `src/utils/permissions/permissionSetup.ts`
- `src/utils/permissions/permissions.ts`
- `src/utils/sandbox/sandbox-adapter.ts`
- `src/services/mcp/headersHelper.ts`
- `src/hooks/useDirectConnect.ts`
- `src/remote/RemoteSessionManager.ts`

외부 프레이밍:

- Anthropic, [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing), 2025-10-20
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

## Sources / evidence notes

이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 Part 6 cluster를 따른다. 핵심 source ID는 `S5`, `S9`, `S15`, `S20`, `S25`, `S30`, `S31`이며, `P1`은 boundary artifact 비교의 보조 프레임으로만 사용한다.

함께 읽으면 좋은 장:

- [03-human-oversight-trust-and-approval.md](../05-execution-continuity-and-integrations/03-human-oversight-trust-and-approval.md)
- [02-sandboxing-permissions-and-policy-surfaces.md](02-sandboxing-permissions-and-policy-surfaces.md)
- [03-local-remote-bridge-and-direct-connect.md](03-local-remote-bridge-and-direct-connect.md)
- [04-safety-autonomy-benchmark.md](04-safety-autonomy-benchmark.md)

## autonomy가 커질수록 boundary는 더 많아진다

autonomy를 "approval을 줄이는 것"으로만 이해하면 거의 항상 틀린다. 실제 시스템은 autonomy를 높이기 위해 오히려 경계를 더 세분화한다.

| boundary 층 | 질문 | Claude Code 예시 |
| --- | --- | --- |
| trust boundary | 이 workspace/session을 어떤 가정 아래 열 것인가 | TrustDialog, external include warning |
| authoring boundary | 어떤 allow rule은 애초에 너무 위험한가 | dangerous Bash/PowerShell rule stripping |
| exposure boundary | 어떤 capability를 모델에게 보여 줄 것인가 | tool shaping, mode/rule composition |
| call-time boundary | 지금 이 action을 허용할 것인가 | ask/deny/allow ordering |
| environment boundary | 허용된 action도 어떤 환경에서만 실행할 것인가 | sandbox filesystem/network config |
| deployment boundary | local/remote/direct-connect에서 누가 approval을 처리하는가 | remote permission relay, bridge/viewer path |

이 층을 구분하지 못하면 operator는 "왜 여기서는 되는데 저기서는 막히는지" 이해할 수 없고, 시스템 설계자는 autonomy와 safety를 같은 언어로 설명할 수 없게 된다.

## trust boundary는 가장 앞단에 있다

`src/interactiveHelpers.tsx`는 interactive session에서 permission mode와 무관하게 trust dialog를 먼저 연다.

```ts
// The trust dialog is the workspace trust boundary ...
// bypassPermissions mode only affects tool execution permissions, not workspace trust.
if (!checkHasTrustDialogAccepted()) {
  const { TrustDialog } = await import('./components/TrustDialog/TrustDialog.js');
  await showSetupDialog(root, done => <TrustDialog commands={commands} onDone={done} />);
}
...
setSessionTrustAccepted(true);
```

이 ordering이 중요한 이유는 trust가 action approval보다 더 상위 boundary이기 때문이다. bypassPermissions가 켜져 있어도 trust boundary는 별도로 남는다. 이것이 없으면 dangerous mode가 workspace trust까지 덮어써 버린다.

## 일부 경계는 bypass-immune하게 남는다

`src/utils/permissions/permissions.ts`는 content-specific ask rule과 safety check를 bypassPermissions mode보다 앞에 둔다.

```ts
if (
  toolPermissionResult?.behavior === 'ask' &&
  toolPermissionResult.decisionReason?.type === 'safetyCheck'
) {
  return toolPermissionResult
}
...
if (shouldBypassPermissions) {
  return { behavior: 'allow', ... }
}
```

이 구조는 autonomy design의 핵심 교훈을 준다. bypass mode가 있다는 사실과 모든 경계가 사라진다는 사실은 다르다. 좋은 boundary engineering은 일부 edge를 bypass-immune하게 남겨 둔다.

## authoring 단계의 경계도 중요하다

`src/utils/permissions/permissionSetup.ts`는 위험한 Bash/PowerShell rule이 classifier를 우회하지 못하도록 authoring 단계에서 걸러 낸다. tool-level allow, wildcard, interpreter prefix 같은 rule은 "너무 넓은 권한"으로 취급된다.

즉 boundary engineering은 runtime prompt를 띄우는 기술만이 아니다. 애초에 너무 넓은 allow surface가 만들어지지 않게 하는 settings-time 제약도 포함한다.

## sandbox boundary는 permission boundary를 대체하지 않는다

`src/utils/sandbox/sandbox-adapter.ts`는 Claude Code settings를 sandbox runtime config로 바꾸며, filesystem/network restriction을 별도 규칙으로 다룬다.

이 층은 call-time permission과 다른 질문에 답한다.

- permission은 "지금 이 action을 허용할까"를 묻는다.
- sandbox는 "허용된 action도 어떤 filesystem/network 범위 안에서만 실행될까"를 묻는다.

둘을 같은 것으로 보면 안전 구조를 설명할 수 없다.

## remote/MCP 경계가 추가되면 boundary는 다시 변형된다

MCP `headersHelper`는 trust 확인 전에는 실행되지 않도록 막고, 문제 발생 시 event까지 남긴다.

```ts
if (!hasTrust) {
  const error = new Error(
    `Security: headersHelper for MCP server '${serverName}' executed before workspace trust is confirmed...`,
  )
  logEvent('tengu_mcp_headersHelper_missing_trust', {})
  return null
}
```

`src/hooks/useDirectConnect.ts`는 remote server에서 온 permission request를 local `ToolUseConfirm` queue로 바꿔 operator에게 보여 준다.

```ts
onPermissionRequest: (request, requestId) => {
  ...
  const toolUseConfirm: ToolUseConfirm = {
    ...
    onAllow(updatedInput, ...) {
      const response: RemotePermissionResponse = {
        behavior: 'allow',
        updatedInput,
      }
      manager.respondToPermissionRequest(requestId, response)
    },
    ...
  }
}
```

이것이 의미하는 바는, deployment family가 바뀌면 boundary도 같이 재배치된다는 점이다. 같은 approval surface라도 local tool-use prompt와 remote permission relay는 다른 경계다.

최신 MCP 문서를 함께 읽으면 한 층이 더 드러난다. roots나 advertised scope는 useful coordination signal일 수 있지만, 그 자체가 sandbox나 authorization boundary는 아니다. boundary engineering 문서가 roots를 enforcement layer처럼 설명하면 trust language와 auth language를 동시에 흐리게 만든다.

## boundary engineering의 목적은 “무조건 막기”가 아니다

좋은 boundary engineering은 다음을 동시에 만족해야 한다.

- operator가 이해할 수 있다
- automation을 과도하게 꺾지 않는다
- bypass-immune edge가 남아 있다
- local과 remote path를 같은 언어로 설명할 수 있다

즉 목적은 autonomy를 줄이는 것이 아니라, autonomy를 안전하게 배치하는 것이다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 trust, authoring, exposure, call-time, sandbox, deployment 경계를 분리한다.
- bypass mode가 있어도 일부 edge는 bypass-immune하게 남는다.
- remote/MCP path는 boundary를 새 장소로 옮긴다.

원칙:

- autonomy를 키울수록 boundary를 줄이기보다 층을 나눠야 한다.
- trust boundary는 action approval과 분리돼야 한다.
- deployment family가 달라지면 boundary placement도 달라져야 한다.
- coordination signal과 enforcement boundary를 같은 것으로 설명하면 안 된다.

해석:

- Anthropic의 sandboxing 글이 말하는 secure autonomy는 Claude Code에서 "더 적은 prompt"가 아니라 "더 정교한 boundary placement"로 구체화된다.
- boundary engineering은 permission prompt UI보다 훨씬 넓은 설계 언어다.

권고:

- 새 하네스를 설계할 때 boundary map을 먼저 그리고, 각 층의 bypass-immune edge를 명시하라.
- settings-time guardrail과 runtime prompt를 같은 층으로 설명하지 말라.
- remote/MCP path가 있다면 local path와 다른 boundary placement를 별도 섹션으로 문서화하라.
- governance review를 염두에 둔다면 각 boundary가 어떤 evidence artifact를 남기는지도 같이 적어라.

## benchmark 질문

1. autonomy를 한 종류의 approval로만 설명하고 있지 않은가.
2. trust와 action approval이 분리돼 있는가.
3. bypass-immune edge가 정의돼 있는가.
4. remote/MCP path로 갈 때 boundary placement 변화가 설명되는가.

## 요약

boundary engineering은 자율성을 줄이는 기술이 아니라, 자율성을 실제로 운영 가능하게 만드는 기술이다. Claude Code는 trust, permission, sandbox, remote/MCP 경계를 여러 층에 배치해 이 사실을 잘 보여 준다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/interactiveHelpers.tsx`
   trust boundary를 먼저 본다.
2. `src/utils/permissions/permissionSetup.ts`
   authoring-time boundary를 본다.
3. `src/utils/permissions/permissions.ts`
   call-time boundary를 본다.
4. `src/utils/sandbox/sandbox-adapter.ts`
   environment boundary를 확인한다.
5. `src/services/mcp/headersHelper.ts`와 `src/hooks/useDirectConnect.ts`
   remote/MCP boundary가 어떻게 재배치되는지 비교한다.
