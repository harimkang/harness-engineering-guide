# 03. 에이전트 하네스의 품질 속성

## 장 요약

하네스를 설계할 때는 기능 목록보다 품질 속성을 먼저 보는 편이 낫다. Claude Code 사례에서도 중요한 것은 "명령이 몇 개인가"보다 reliability, steerability, recoverability, observability, reproducibility, efficiency 같은 속성이 어떤 code path와 artifact에 스며 있는가다. 이 장은 그 속성을 정리하고, 각 속성이 실제로 어떤 local surface에 기대는지 보여 준다.

## 범위와 비범위

이 장이 다루는 것:

- production coding harness를 읽을 때 유용한 핵심 품질 속성
- 각 속성이 local artifact와 어떻게 연결되는지
- 속성들 사이의 대표 trade-off와 failure signature

이 장이 다루지 않는 것:

- 특정 시스템의 최종 scorecard
- 모든 품질 속성의 완전한 taxonomy
- 하위 구현 최적화 팁 전부

이 장은 품질 속성 프레임을 세우는 foundations 장이며, 이후 파트에서 각 속성이 context/tools/execution/safety/evaluation으로 세분화된다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/query.ts`
- `src/query/tokenBudget.ts`
- `src/screens/REPL.tsx`
- `src/utils/sessionRestore.ts`
- `src/hooks/useLogMessages.ts`
- `src/utils/permissions/permissions.ts`
- `src/services/analytics/growthbook.ts`
- `src/services/vcr.ts`
- `src/cost-tracker.ts`

외부 프레이밍:

- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), 2026-03-30

함께 읽으면 좋은 장:

- [../execution/04-human-oversight-trust-and-approval.md](../execution/04-human-oversight-trust-and-approval.md)
- [../evaluation/03-benchmarking-coding-harnesses.md](../evaluation/03-benchmarking-coding-harnesses.md)
- [04-core-design-axes-context-control-tools-memory-safety-evals.md](./04-core-design-axes-context-control-tools-memory-safety-evals.md)

## 여섯 품질 속성

| 품질 속성 | 핵심 질문 | Claude Code에서 먼저 볼 곳 |
| --- | --- | --- |
| reliability | 같은 작업을 예측 가능한 구조로 이어 갈 수 있는가 | `src/query.ts`, task lifecycle |
| steerability | 사람이 세션을 이해하고 방향을 바꿀 수 있는가 | REPL, permission surface, transcript |
| recoverability | 실패 후 같은 의미로 다시 이어 갈 수 있는가 | session restore, transcript, content replacement |
| observability | 현재 상태와 결과를 읽을 수 있는가 | transcript, result packet, diagnostics, notifications |
| reproducibility | 같은 조건을 다시 만들 수 있는가 | GrowthBook override, VCR fixture |
| efficiency | 불필요한 turn, token, cost, friction을 줄이는가 | token budget, compaction, cost tracker |

이 여섯 속성은 체크리스트가 아니라 서로 충돌하는 품질 목표다. production harness는 항상 이들 사이에서 균형을 잡는다.

## reliability: loop와 lifecycle이 흔들리지 않는가

reliability는 단순히 crash가 없다는 뜻이 아니다. long-running harness에서는 다음 turn이 같은 규칙 아래 이어지고, task family가 terminal state를 잘 처리하며, session이 길어져도 control loop가 붕괴하지 않는지가 더 중요하다.

`src/query.ts`의 explicit continuation state와 `src/Task.ts`의 terminal status 구분은 reliability의 대표 evidence다.

## steerability: 사람이 제때 이해하고 개입할 수 있는가

steerability는 "사람이 수동으로 다 조종한다"는 뜻이 아니다. operator가 현재 상태를 읽고, 필요한 순간에 의미 있게 개입할 수 있느냐가 핵심이다.

- transcript mode
- tool-specific permission request
- background/foreground task 전환
- explicit command surface

이런 surface가 있으면 operator는 시스템을 steer할 수 있다. 반대로 아무리 모델이 좋아도 현재 상태를 읽을 길이 없으면 steerability는 낮다.

## recoverability: 중단 뒤 semantic continuity가 유지되는가

recoverability는 restart가 아니라 semantic continuity의 문제다. transcript, resume, worktree restore, cost restore, invalid state filtering이 함께 작동해야 한다.

이 속성은 `src/utils/sessionRestore.ts`, `src/utils/conversationRecovery.ts`, `src/utils/sessionStorage.ts`에 흩어져 있다. 따라서 recoverability는 한 함수가 아니라 artifact family 전체를 읽어야 보인다.

## observability: 시스템이 스스로를 설명할 수 있는가

observability는 사람이 현재 무슨 일이 일어나는지, run이 어떻게 끝났는지, 어디서 실패했는지 읽을 수 있게 만드는 속성이다.

- transcript chain
- QueryEngine result packet
- diagnostics summary
- task notification
- permission decision log

이런 artifact가 없으면 operator와 reviewer는 대부분의 failure를 추정으로만 말하게 된다.

## reproducibility: 같은 조건을 다시 만들 수 있는가

reproducibility는 evaluation 파트에서만 필요한 속성이 아니다. production bug를 고치려면 같은 feature configuration과 같은 external interaction을 다시 만들어야 한다.

`GrowthBook` env override와 `VCR` fixture는 바로 이 품질 속성을 product code 안에서 드러낸다. 이것이 없는 harness는 테스트는 통과해도 field bug를 설명하기 어렵다.

## efficiency: 좋은 결과를 낭비 없이 내는가

efficiency는 비용 절감만이 아니다. token budget continuation, compaction, safe allowlist, cost tracking처럼 "같은 결과를 더 적은 turn, 적은 friction, 적은 비용으로 내는가"를 묻는 속성이다.

```ts
const decision = checkTokenBudget(
  budgetTracker!,
  toolUseContext.agentId,
  getCurrentTurnTokenBudget(),
  getTurnOutputTokens(),
)
```

이 코드는 efficiency가 단순 limit check가 아니라 continuation policy라는 사실을 보여 준다.

## 대표 trade-off

| 속성 쌍 | 흔한 긴장 |
| --- | --- |
| reliability vs efficiency | 더 많은 guard와 artifact는 안정성을 높이지만 비용과 latency를 올린다 |
| steerability vs autonomy | operator surface를 넓히면 개입은 쉬워지지만 자율 흐름은 자주 끊길 수 있다 |
| recoverability vs simplicity | restore path를 강화할수록 상태 공간과 coupling이 복잡해진다 |
| observability vs noise | 더 많은 trace와 status는 분석을 돕지만 operator 부담도 키운다 |
| reproducibility vs flexibility | dynamic config가 많을수록 동일 조건 재현은 어려워진다 |

하네스 품질을 읽을 때는 "무엇이 좋은가"보다 "무엇을 대가로 선택했는가"를 함께 보는 편이 정확하다.

## failure signature로 읽어라

속성마다 실패 signature도 다르다.

- reliability failure  
  같은 조건에서도 loop나 lifecycle이 예측 가능하게 유지되지 않는다.
- steerability failure  
  operator가 현재 상태를 이해하거나 개입할 위치를 찾지 못한다.
- recoverability failure  
  중단 뒤 다시 이어 붙일 artifact나 restore path가 부족하다.
- observability failure  
  transcript/result/diagnostic가 빈약해 왜 실패했는지 읽을 수 없다.
- reproducibility failure  
  동일 bug를 다시 만들 수 없어 개선 검증이 흔들린다.
- efficiency failure  
  불필요하게 많은 turn, token, permission prompt, cost가 든다.

이 failure signature는 기능 목록보다 훨씬 빨리 문제의 층을 가리켜 준다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code의 품질 속성은 한 파일에 모여 있지 않고 loop, transcript, permissions, task, telemetry에 흩어져 있다.
- reproducibility는 evaluation용 부가 기능이 아니라 production 품질 속성으로도 중요하다.
- efficiency와 reliability는 종종 같은 code path에서 함께 설계된다.

원칙:

- 기능보다 품질 속성을 먼저 읽어야 구조적 장단점이 보인다.
- 품질 속성은 반드시 artifact와 연결해 설명해야 한다.
- trade-off를 숨기면 품질 속성 설명은 금방 공허해진다.

해석:

- Anthropic의 long-running harness 원칙은 Claude Code에서 품질 속성별 artifact cluster로 읽힌다.
- Meta-Harness 관점에서도 최적화 대상은 모델이 아니라 이런 품질 속성 조합을 구현한 harness 전체다.

권고:

- 새 harness를 리뷰할 때는 기능 목록 전에 여섯 품질 속성 표를 먼저 채워 보라.
- weakness를 설명할 때는 반드시 failure signature와 연결해 적어라.
- reproducibility를 evaluation 파트로만 미루지 말고 foundations 단계에서부터 품질 속성으로 넣어라.

## benchmark 질문

1. 이 시스템의 strongest/weakest quality attribute는 무엇인가.
2. 각 속성을 뒷받침하는 artifact를 실제로 가리킬 수 있는가.
3. 같은 기능도 속성 관점으로 보면 어떤 trade-off를 만드는지 설명할 수 있는가.
4. reproducibility를 product-quality concern으로 보고 있는가.

## 요약

기능이 같아 보여도 하네스 품질은 크게 다를 수 있다. Claude Code 사례는 reliability, steerability, recoverability, observability, reproducibility, efficiency가 실제 code path와 artifact에 어떻게 스며드는지 보여 준다. 이후 장들은 이 속성을 context, tools, execution, safety, evaluation으로 더 구체화한다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/query/tokenBudget.ts`
   efficiency와 continuation policy를 먼저 본다.
2. `src/query.ts`
   reliability가 state transition에 어떻게 박히는지 본다.
3. `src/screens/REPL.tsx`
   steerability와 observability surface를 확인한다.
4. `src/utils/sessionRestore.ts`
   recoverability를 본다.
5. `src/services/analytics/growthbook.ts`와 `src/services/vcr.ts`
   reproducibility surface를 확인한다.
6. `src/cost-tracker.ts`
   efficiency와 economics가 어떻게 이어지는지 본다.
