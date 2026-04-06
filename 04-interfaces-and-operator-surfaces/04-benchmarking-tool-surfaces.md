# 04. tool surface를 어떻게 평가할 것인가

## 장 요약

tool surface의 좋고 나쁨은 tool 개수만으로 판단되지 않는다. 중요한 것은 discoverability, contract clarity, exposure discipline, permission clarity, output economy, provenance, recoverability다. Claude Code는 이 모든 차원을 직접 보여 주는 codebase다. `src/Tool.ts`는 contract를, permission layer는 boundary를, `ToolSearchTool`은 deferred discoverability를, MCP merge는 provenance complexity를 드러낸다. 이 장은 그 차원을 benchmark 언어로 정리한다.

## 범위와 비범위

이 장이 다루는 것:

- coding harness의 tool surface를 비교하는 핵심 차원
- 1차 루브릭과 evidence collection 방법
- tool-level variance를 읽는 법

이 장이 다루지 않는 것:

- 정밀한 수학적 scoring framework
- 모든 tool에 적용되는 완전한 자동 grader 설계
- 특정 벤치마크 제품에 종속된 구현법

이 장은 interfaces 파트의 evaluation bridge 장이다. Part VI의 broader harness benchmark와 연결해 읽어야 한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/Tool.ts`
- `src/tools/ToolSearchTool/ToolSearchTool.ts`
- `src/utils/permissions/permissions.ts`
- `src/utils/permissions/permissionSetup.ts`
- `src/services/mcp/client.ts`
- `src/query.ts`

외부 프레이밍:

- Anthropic, [Writing effective tools for agents — with agents](https://www.anthropic.com/engineering/writing-tools-for-agents), 2025-09-11
- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09
- Lee et al., [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052), 2026-03-30

함께 읽으면 좋은 장:

- [01-tool-contracts-and-the-agent-computer-interface.md](01-tool-contracts-and-the-agent-computer-interface.md)
- [02-tool-shaping-permissions-and-capability-exposure.md](02-tool-shaping-permissions-and-capability-exposure.md)
- [../evaluation/03-benchmarking-coding-harnesses.md](../07-evaluation-and-synthesis/03-benchmarking-long-running-agent-harnesses.md)

## 평가 차원

| 차원 | 질문 | 대표 local evidence |
| --- | --- | --- |
| discoverability | 모델이 어떤 tool을 언제 써야 하는지 이해할 수 있는가 | name, aliases, searchHint, ToolSearch |
| contract clarity | 입력/출력/중단 semantics가 명확한가 | `Tool<T>`, schema, interruptBehavior |
| exposure discipline | capability를 언제 보여 주고 언제 숨기는가 | shaping + deferred search |
| permission clarity | allow/ask/deny와 decision reason이 이해 가능한가 | `src/utils/permissions/permissions.ts`, permission request UI |
| output economy | 결과가 next turn에 재사용 가능하면서도 낭비가 적은가 | result shaping, output budget, collapse summary |
| provenance | capability가 어디서 왔는지 분명한가 | local tool vs MCP vs deferred |
| recoverability | deny/oversized result/deferred discovery 이후 다시 시도할 경로가 있는가 | retry path, ToolSearch, permission explanations |

이 차원을 함께 봐야 "좋은 tool system"과 "툴이 많기만 한 시스템"을 구분할 수 있다.

## 1차 scoring rubric

| 점수 | 의미 |
| --- | --- |
| 1 | 차원이 약해 모델이나 operator가 자주 오해한다 |
| 3 | 기본적 계약은 있으나 edge case와 provenance 설명이 약하다 |
| 5 | 계약, 경계, 재시도 경로, provenance가 모두 분명하다 |

이 루브릭은 정교한 계량 도구가 아니라 first-pass reading guide다. publication-grade 비교 문서에서는 점수보다 왜 그 점수를 줬는지 한 줄 근거를 남기는 편이 더 중요하다.

## discoverability는 현재 목록과 deferred 목록을 함께 봐야 한다

Claude Code는 discoverability를 name/description/searchHint에만 의존하지 않는다. deferred tool이 있을 때 `ToolSearchTool`이 keyword search와 exact match를 담당한다.

```ts
query: z.string().describe(
  'Query to find deferred tools. Use "select:<tool_name>" for direct selection, or keywords to search.'
)
```

따라서 discoverability 점수는 "현재 보이는 tool 설명"만이 아니라 "지금 안 보이는 capability를 다시 찾게 해 주는가"까지 포함해야 한다.

## contract clarity는 schema만으로 충분하지 않다

`Tool<T>`는 schema 외에도 `isReadOnly`, `isDestructive`, `isConcurrencySafe`, `interruptBehavior`를 갖는다. 이는 contract clarity가 입력 타입 정의만으로 닫히지 않는다는 뜻이다.

tool surface benchmark에서 schema만 보고 점수를 매기면 중요한 차이를 놓친다.

- cancel 가능한 tool과 block-only tool
- read-only tool과 destructive tool
- concurrency-safe tool과 context-mutating tool

이런 차이는 operator와 agent 모두에게 큰 의미를 가진다.

## permission clarity는 decision reason을 함께 봐야 한다

permission이 ask/deny/allow 세 가지 상태만 있다고 해서 clarity가 높은 것은 아니다. 중요한 것은 왜 그런 결정이 났는지가 operator에게 설명되는가다.

Claude Code는 rule, mode, safetyCheck, permissionPromptTool 같은 decision reason을 operator-facing message로 바꾼다. 이것이 없으면 permission layer는 그저 friction으로만 느껴진다.

## provenance complexity는 MCP가 들어오면 급격히 증가한다

MCP merge는 tool surface를 넓혀 주지만, provenance complexity도 키운다. 외부 tool, command, skill, resource가 한꺼번에 세션 surface로 들어오면 discoverability와 permission clarity는 더 어려워진다.

따라서 MCP-heavy tool surface를 평가할 때는 "기능이 많다"보다 "provenance가 읽히는가"를 더 많이 봐야 한다.

## sample scoring을 Claude Code에 적용하면

| 차원 | 빠른 평가 | 이유 |
| --- | --- | --- |
| discoverability | 높음 | aliases/searchHint/ToolSearch까지 갖춘다 |
| contract clarity | 높음 | schema + execution metadata가 비교적 분명하다 |
| exposure discipline | 높음 | shaping, deferred discovery, call-time permission이 나뉜다 |
| permission clarity | 중상 | decision reason은 강하지만 operator가 읽어야 할 층이 많다 |
| output economy | 중상 | budget/collapse/summary가 있으나 complexity cost도 있다 |
| provenance | 중상 | local/MCP/plugin/skill provenance가 존재하나 읽기 비용이 있다 |
| recoverability | 중상 | deny/ask 이후 경로는 존재하지만 surface가 복합적이다 |

이 예시는 절대 점수표가 아니라 "어디가 강하고 어디가 complex한가"를 보여 주는 working example이다.

## benchmark 절차

1. 대표 tool 3~5개를 고른다.  
   예: read, shell, web fetch, agent spawn, MCP tool
2. 각 tool에 대해 위 일곱 차원을 1/3/5로 매긴다.
3. deny/ask/allow, oversized result, deferred discovery, MCP provenance edge case를 최소 하나씩 섞는다.
4. 점수와 함께 한 줄 evidence를 남긴다.
5. 평균보다 variance를 먼저 본다.

특정 tool 하나만 유난히 약해도 실제 harness 경험은 크게 무너질 수 있기 때문이다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 contract clarity와 exposure discipline이 강한 대신, provenance complexity가 높은 surface다.
- discoverability는 visible tool 목록 밖의 deferred search까지 포함해 설계돼 있다.
- permission clarity는 decision reason과 operator-facing explanation이 있어야 높아진다.

원칙:

- tool surface 평가는 함수 개수 세기가 아니다.
- discoverability와 provenance는 MCP/deferred capability가 있는 시스템에서 특히 중요하다.
- permission clarity는 ask/deny 숫자보다 explanation surface를 더 많이 본다.

해석:

- Anthropic의 tool-writing 원칙은 이 codebase에서 contract, search, permission, MCP merge라는 여러 seam으로 구현된다.
- Meta-Harness 관점에서 tool surface는 별도 최적화 대상 subsystem이다.

권고:

- 새 tool system을 리뷰할 때는 반드시 discoverability와 provenance 차원을 분리해서 보라.
- tool contract checklist에 schema 외 execution semantics까지 넣어라.
- MCP를 붙인 뒤에는 기능 수보다 provenance readability가 떨어졌는지 먼저 점검하라.

## benchmark 질문

1. discoverability, contract clarity, exposure discipline 중 어디가 가장 약한가.
2. provenance가 복잡해질 때 operator와 모델 모두에게 설명 가능한가.
3. output economy를 높이면서 recoverability를 해치지 않았는가.
4. 특정 tool 하나의 약점이 전체 harness 경험을 무너뜨릴 정도로 variance가 큰가.

## 요약

tool surface 평가는 함수 개수 세기가 아니다. 그것은 계약, 노출, 경계, provenance, 회복 가능성을 함께 보는 일이다. Claude Code는 좋은 기준점과 높은 complexity cost를 동시에 제공하며, 그래서 tool surface benchmark의 교육용 사례로 적합하다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/Tool.ts`
   contract clarity의 기본 단위를 본다.
2. `src/tools/ToolSearchTool/ToolSearchTool.ts`
   discoverability와 deferred capability bridge를 확인한다.
3. `src/utils/permissions/permissions.ts`
   permission clarity와 recoverability를 본다.
4. `src/utils/permissions/permissionSetup.ts`
   exposure discipline 앞단의 guardrail을 확인한다.
5. `src/services/mcp/client.ts`
   provenance complexity가 커지는 지점을 본다.
6. `src/query.ts`
   output economy가 next-turn artifact와 어떻게 연결되는지 확인한다.
