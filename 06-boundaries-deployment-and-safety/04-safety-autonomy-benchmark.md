# 04. safety-autonomy benchmark

## 장 요약

좋은 하네스는 안전과 자율성을 추상적 가치로만 말하지 않는다. 대신 어느 층에서 autonomy를 열고, 그 대가로 어떤 safety surface를 더 두껍게 만들었는지 설명 가능해야 한다. Claude Code는 trust dialog, dangerous-rule stripping, bypass-immune safety check, sandbox runtime, remote permission relay를 통해 이 균형을 artifact 수준에서 드러낸다. 이 장은 그 균형을 읽는 benchmark frame을 제안한다.

## 범위와 비범위

이 장이 다루는 것:

- safety와 autonomy를 함께 읽는 benchmark axes
- boundary placement와 operator legibility를 어떻게 측정할지
- deployment family가 benchmark에 어떤 변수를 추가하는지

이 장이 다루지 않는 것:

- 절대적인 safety score를 매기는 일
- 법적/compliance audit 절차 전부
- sandbox runtime 내부 테스트 harness 전체

이 장은 safety 파트의 synthesis 장이다. 따라서 아래 axis는 현재 공개 스냅샷을 읽기 위한 benchmark frame이며, build flag나 packaging 변화와 함께 재검증해야 한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/interactiveHelpers.tsx`
- `src/utils/permissions/permissionSetup.ts`
- `src/utils/permissions/permissions.ts`
- `src/utils/sandbox/sandbox-adapter.ts`
- `src/services/mcp/headersHelper.ts`
- `src/hooks/useDirectConnect.ts`
- `src/remote/RemoteSessionManager.ts`
- `src/remote/SessionsWebSocket.ts`

외부 프레이밍:

- Anthropic, [Beyond permission prompts: making Claude Code more secure and autonomous](https://www.anthropic.com/engineering/claude-code-sandboxing), 2025-10-20
- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09
- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), 2026-03-30

Sources / evidence notes:
이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 Part 6 cluster를 따른다. 핵심 source ID는 `S5`, `S15`, `S20`, `S25`, `S30`, `S31`이며, `S7`은 safety/autonomy benchmark를 eval language와 연결하는 보조 프레임으로만 사용한다.

함께 읽으면 좋은 장:

- [01-boundary-engineering-and-autonomy.md](01-boundary-engineering-and-autonomy.md)
- [02-sandboxing-permissions-and-policy-surfaces.md](02-sandboxing-permissions-and-policy-surfaces.md)
- [03-local-remote-bridge-and-direct-connect.md](03-local-remote-bridge-and-direct-connect.md)
- [../evaluation/05-claude-code-benchmark-framework.md](../07-evaluation-and-synthesis/05-harness-benchmark-framework.md)

## 대표 코드 발췌

이 장은 safety를 단일 permission prompt가 아니라 계층적 boundary로 읽는다. 그 이유는 startup trust와 feature gate가 실제로 같은 흐름 안에서 이어지기 때문이다.

```ts
logForDebugging('[STARTUP] Running showSetupScreens()...');
const setupScreensStart = Date.now();
const onboardingShown = await showSetupScreens(root, permissionMode, allowDangerouslySkipPermissions, commands, enableClaudeInChrome, devChannels);
logForDebugging(`[STARTUP] showSetupScreens() completed in ${Date.now() - setupScreensStart}ms`);

if (feature('BRIDGE_MODE') && remoteControlOption !== undefined) {
  // ... remote-control entitlement check ...
}
```

이 발췌는 `src/main.tsx`에서 trust/setup 화면을 통과한 뒤에야 remote-control entitlement를 다시 확인하는 구간이다. 즉 safety는 "더 많이 묻는다"가 아니라 "어느 경계를 어떤 순서로 연다"의 문제라는 것이 이 문서의 출발점이다.

## benchmark axes

| axis | 낮은 점수 | 높은 점수 |
| --- | --- | --- |
| boundary clarity | trust, permission, sandbox, remote relay가 뒤섞여 있다 | 각 경계가 층위별로 구분된다 |
| operator legibility | 왜 막혔는지/왜 허용됐는지 읽기 어렵다 | decision reason과 mode가 읽힌다 |
| autonomy depth | 거의 모든 action이 수동 승인에 막힌다 | 여러 층의 guardrail 아래 많은 action이 자동 진행된다 |
| constrained recovery | 제한 조건이 걸리면 세션이 쉽게 무너진다 | reconnect/retry/resume contract가 남아 있다 |
| deployment variance handling | local과 remote 차이를 설명하지 못한다 | family별 contract가 분리돼 있다 |
| fatigue management | prompt 수만 세고 구조는 모른다 | 어떤 층을 자동화하고 어떤 층을 남겼는지 설명 가능하다 |

이 표는 "누가 더 안전한가"를 단순히 서열화하려는 것이 아니다. 더 정확히는 "어떤 설계가 어떤 종류의 autonomy를 허용하고, 그 대가로 어떤 burden을 만드는가"를 읽는 표다.

## Claude Code를 이 frame으로 읽으면

### boundary clarity

비교적 높다. trust dialog, dangerous rule stripping, call-time permission, sandbox runtime, MCP trust check가 서로 다른 코드 surface에 드러난다.

### operator legibility

중간 이상이다. decision reason과 mode explanation은 남지만, 층이 많아 독해 비용도 함께 크다.

### autonomy depth

중간에서 높음 사이다. bypass/auto mode, safe allowlist, sandboxed execution, remote session flow를 통해 많은 action이 자동 진행될 수 있지만, bypass-immune edge도 남아 있다.

### constrained recovery

중간 이상이다. remote reconnect, session resume, permission relay가 존재하지만 family가 다양해 구조가 복잡하다.

### deployment variance handling

강한 편이다. local, remote attach, direct-connect, bridge/viewer를 서로 다른 family로 읽을 수 있다.

### fatigue management

중간 이상이다. permission prompt count와 decision reason을 계측하지만, operator가 읽어야 할 구조 역시 두껍다.

## 왜 “높은 autonomy”가 곧 “약한 safety”가 아닌가

Claude Code 사례가 보여 주는 중요한 점은 이것이다. autonomy depth를 높이기 위해 항상 boundary를 줄인 것은 아니다. 오히려 boundary를 더 세분화하고, 일부만 자동화하고, 일부는 bypass-immune하게 남겨 뒀다.

예를 들어:

- trust boundary는 bypass mode와 분리돼 남는다.
- safetyCheck ask는 bypass-immune하게 남는다.
- sandbox runtime은 permission을 대체하지 않고 보완한다.
- remote family는 reconnect/auth/relay contract를 별도로 가진다.

따라서 safety-autonomy benchmark는 "prompt가 몇 개 뜨는가"보다 "어떤 boundary를 자동화했고 어떤 boundary를 남겼는가"를 더 많이 봐야 한다.

## benchmark 절차

1. boundary map을 그린다.  
   trust, authoring, call-time, sandbox, remote family를 분리한다.
2. 각 boundary마다 operator가 보는 explanation surface를 적는다.
3. 자동화된 층과 수동 승인 층을 나눈다.
4. local과 remote family에서 같은 action이 어떻게 다르게 흐르는지 비교한다.
5. 실패 시 recovery contract가 남는지 본다.

이 절차를 따르면 safety benchmark가 permission dialog 숫자 세기로 축소되지 않는다.

benchmark-ready 문서라면 여기에 evidence pack도 붙여 두는 편이 좋다. boundary map, decision reason sample, approval burden metric, recovery trace, deployment-family variance note가 함께 남아야 나중에 "왜 이 점수를 줬는가"를 재검토할 수 있다. eval hygiene 장의 reproducibility bundle과 여기의 safety evidence는 분리되지만 강하게 인접한다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 safety와 autonomy를 단일 switch가 아니라 여러 boundary의 조합으로 다룬다.
- deployment family가 달라지면 safety contract도 달라진다.
- operator legibility와 fatigue management는 별도 측정 축으로 남겨야 한다.

원칙:

- safety-autonomy benchmark는 boundary placement를 먼저 봐야 한다.
- autonomy depth를 높일 때 어떤 boundary가 남는지 반드시 같이 적어야 한다.
- deployment variance와 constrained recovery를 benchmark에서 빼면 실제 위험을 놓친다.
- governance review에 쓸 evidence artifact를 남기지 않으면 benchmark 결과는 재사용성이 낮다.

해석:

- Anthropic의 secure autonomy 원칙은 Claude Code에서 layered boundary와 family-specific contract로 구체화된다.
- safety benchmark는 "더 막는다"가 아니라 "더 잘 배치한다"를 평가해야 한다.

권고:

- 새 harness를 평가할 때는 safety benchmark 표에 반드시 `deployment variance handling` 축을 넣어라.
- prompt 수보다 decision reason과 bypass-immune edge를 먼저 기록하라.
- recovery under constraint를 별도 축으로 남겨라. 안전 경계가 강할수록 이 축이 더 중요해진다.

## Review scaffold

- boundary map, operator burden, constrained recovery, deployment variance가 한 bundle로 남는지 확인하라.
- safety-autonomy 점수만 남기고 evidence artifact를 버리고 있지 않은지 점검하라.
- 이 benchmark 결과를 governance review 언어로 다시 번역할 수 있어야 한다.

## benchmark 질문

1. 이 시스템은 safety를 한 종류의 승인으로만 설명하고 있지 않은가.
2. autonomy depth를 높일 때 어떤 boundary가 함께 두꺼워지는가.
3. local과 remote family를 같은 safety language로 뭉개고 있지 않은가.
4. operator legibility와 approval fatigue를 동시에 측정할 수 있는가.
5. 제한 아래에서도 recovery contract가 남는가.

## 요약

안전과 자율성의 균형은 추상적 구호가 아니라 benchmark 대상이다. Claude Code는 trust, permission, sandbox, remote relay, reconnect를 서로 다른 artifact로 드러내기 때문에, safety-autonomy benchmark를 연습하기 좋은 사례가 된다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/interactiveHelpers.tsx`
   trust boundary와 위험 모드 gate를 본다.
2. `src/utils/permissions/permissionSetup.ts`
   authoring-time guardrail을 본다.
3. `src/utils/permissions/permissions.ts`
   call-time safety language를 본다.
4. `src/utils/sandbox/sandbox-adapter.ts`
   environment envelope를 확인한다.
5. `src/hooks/useDirectConnect.ts`, `src/remote/RemoteSessionManager.ts`, `src/remote/SessionsWebSocket.ts`
   deployment variance와 constrained recovery를 비교한다.
