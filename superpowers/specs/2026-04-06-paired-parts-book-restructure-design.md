# Harness Engineering 문서세트 대수술 리디자인 스펙

- 작성일: 2026-04-06
- 상태: Approved Design
- 대상 작업 공간: `claude-code/docs`
- 주 대상 산출물: reader-facing corpus 전체
- 목표 독서 경험: 한 권의 책 안에서 원칙과 Claude Code 사례를 왕복하는 구조

## 1. 문제 정의

현재 문서세트는 개별 장의 품질과 문제의식 자체는 대체로 `Harness Engineering: Designing Operational Systems for Long-Running Agents`라는 표제와 잘 맞는다. 다만 책 전체의 구조와 표면적 진입 경험은 여전히 다음 세 가지 문제를 남긴다.

1. 사례 spine `01`-`17`이 문서 표면의 주 번호 체계를 차지해, 독자가 `README`를 건너뛰면 Claude Code 사례서로 먼저 읽히기 쉽다.
2. evaluation 일부 장이 `long-running agent harness` 일반론보다 `coding harness` 쪽으로 범위를 더 좁혀 보이게 만든다.
3. workbook/reference 성격의 문서와 사례 본체가 같은 spine 안에 있어, 주제 중심 독서와 코드 독해 보조 장치가 충분히 분리되지 않는다.

핵심 문제는 내용 부족보다 정보 구조다. 즉, 문서 내용은 대체로 주제에 맞지만, 현재 파일 배치와 번호 체계가 그 의도를 충분히 전달하지 못한다.

## 2. 목표

이번 대수술의 목표는 다음과 같다.

1. 일반 하네스 설계 원칙이 항상 사례보다 먼저 보이도록 정보 구조를 재배치한다.
2. Claude Code 관련 장은 제목과 경로만 봐도 사례 분석임이 분명히 드러나게 만든다.
3. 원칙 장과 사례 장을 멀리 떼어 놓지 않고, 같은 주제 단위 안에서 왕복하도록 파트를 재구성한다.
4. evaluation 파트의 핵심 프레임을 특정 제품 사례보다 일반 하네스 비교 언어로 다시 고정한다.
5. workbook/reference 문서는 본 서사에서 분리하되, 각 파트와의 연결은 더 명확히 만든다.
6. 기존 reader-facing corpus만으로도 책 전체의 독서 경로가 자명하도록 `README`와 part guide를 다시 설계한다.

## 3. 비목표

이번 개편에서 하지 않는 일은 다음과 같다.

1. 각 장의 핵심 논지를 처음부터 다시 쓰는 전면 리라이트
2. 스냅샷에 없는 제품 사실을 추가 추정하는 일
3. 사례 장을 삭제하고 완전히 일반론 문서로 대체하는 일
4. 새로운 이론 장을 대량 추가하는 일
5. 문서의 주제를 coding agent 바깥의 모든 agent product로 무리하게 확장하는 일

## 4. 채택한 접근

채택한 접근은 `Paired Parts` 재구성형이다.

- 큰 주제별 Part를 만든다.
- 각 Part 안에서는 `원칙 장 -> Claude Code 사례 장 -> 필요한 경우 synthesis/reference` 순서를 유지한다.
- 사례 장 파일명에는 `claude-code-`를 명시해 일반론과 사례를 시각적으로 구분한다.
- workbook/reference는 별도 Part로 모으되, 종합 장과는 인접하게 둔다.

이 접근을 택한 이유는 다음과 같다.

1. `Dual Spine` 유지형보다 일반론 우선성이 더 잘 보인다.
2. `Triptych` 강결합형보다 편집 비용과 구조 경직성이 낮다.
3. 사용자가 원한 "한 권의 책 안에서 원칙과 사례를 왕복"하는 경험에 가장 잘 맞는다.

## 5. 최종 정보 구조

최종 디렉터리 구조는 아래와 같다.

```text
docs/
  README.md
  00-front-matter/
  01-foundations/
  02-runtime-and-session-start/
  03-context-and-control/
  04-interfaces-and-operator-surfaces/
  05-execution-continuity-and-integrations/
  06-boundaries-deployment-and-safety/
  07-evaluation-and-synthesis/
  08-reference/
```

핵심 설계 원칙은 다음 두 가지다.

1. 일반론은 part 안에서 항상 사례보다 앞에 온다.
2. 사례는 같은 문제 영역 안에서 바로 이어 읽을 수 있게 둔다.

## 6. Part별 역할

### 6.1 Part 0. Front Matter

- 책의 목적, 독서 규칙, 방법론, 참고문헌을 고정한다.
- 본문에 들어가기 전에 reader-facing corpus의 규칙을 정리한다.

### 6.2 Part 1. Foundations

- workflow, runtime, harness, eval harness, 품질 속성, 핵심 축을 정의한다.
- 이후 모든 파트의 개념적 공통 기반을 제공한다.

### 6.3 Part 2. Runtime And Session Start

- 일반론: runtime family, entrypoint, startup contract, trust boundary
- 사례: Claude Code의 project overview, architecture map, runtime modes, startup/trust

### 6.4 Part 3. Context And Control

- 일반론: context as resource, context classes, compaction/memory/handoff, turn loop/recovery
- 사례: Claude Code의 context assembly/query pipeline, QueryEngine/turn lifecycle

### 6.5 Part 4. Interfaces And Operator Surfaces

- 일반론: tool contract, permission shaping, extension surfaces, tool surface benchmark
- 사례: Claude Code의 command system, tool system/permissions, state/UI/terminal interaction

### 6.6 Part 5. Execution, Continuity, And Integrations

- 일반론: resumability, task orchestration, human oversight
- 사례: Claude Code의 services/integrations, skills/plugins/MCP/coordinator, task model, persistence

### 6.7 Part 6. Boundaries, Deployment, And Safety

- 일반론: boundary engineering, sandboxing/policy surfaces, local/remote family, safety-autonomy benchmark
- 사례: Claude Code의 remote/bridge/direct-connect/upstream proxy, risks/debt/failure modes

### 6.8 Part 7. Evaluation And Synthesis

- 일반론: model eval vs harness eval, tasks/trials/transcripts/graders, general harness benchmark, production traces, skeptical evaluator
- 사례/종합: Claude Code end-to-end scenarios
- reference-adjacent synthesis: benchmark-oriented code reading guide

### 6.9 Part 8. Reference

- glossary, key file index, directory map, root file map, conditional features map
- source re-entry와 file lookup을 돕는 보조 장치

## 7. 파일 이동 및 리네이밍 계획

### 7.1 Front Matter

| 현재 경로 | 새 경로 |
| --- | --- |
| `00-how-to-read-this-book.md` | `00-front-matter/01-how-to-read-this-book.md` |
| `appendix/source-analysis-method.md` | `00-front-matter/02-source-analysis-method.md` |
| `appendix/references.md` | `00-front-matter/03-references.md` |

### 7.2 Foundations

| 현재 경로 | 새 경로 |
| --- | --- |
| `foundations/01-why-harness-engineering-matters.md` | `01-foundations/01-why-harness-engineering-matters.md` |
| `foundations/02-workflows-agents-runtimes-and-harnesses.md` | `01-foundations/02-workflows-agents-runtimes-and-harnesses.md` |
| `foundations/03-quality-attributes-of-agent-harnesses.md` | `01-foundations/03-quality-attributes-of-agent-harnesses.md` |
| `foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md` | `01-foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md` |
| `foundations/05-evaluator-driven-harness-design.md` | `01-foundations/05-evaluator-driven-harness-design.md` |

### 7.3 Runtime And Session Start

| 현재 경로 | 새 경로 |
| --- | --- |
| `01-project-overview.md` | `02-runtime-and-session-start/03-claude-code-project-overview.md` |
| `02-architecture-map.md` | `02-runtime-and-session-start/04-claude-code-architecture-map.md` |
| `03-runtime-modes-and-entrypoints.md` | `02-runtime-and-session-start/05-claude-code-runtime-modes-and-entrypoints.md` |
| `04-session-startup-trust-and-initialization.md` | `02-runtime-and-session-start/06-claude-code-session-startup-trust-and-initialization.md` |

### 7.4 Context And Control

| 현재 경로 | 새 경로 |
| --- | --- |
| `context/01-context-as-an-operational-resource.md` | `03-context-and-control/01-context-as-an-operational-resource.md` |
| `context/02-context-classes-boundaries-and-scopes.md` | `03-context-and-control/02-context-classes-boundaries-and-scopes.md` |
| `context/03-compaction-memory-and-handoff-artifacts.md` | `03-context-and-control/03-compaction-memory-and-handoff-artifacts.md` |
| `context/04-turn-loops-stop-hooks-and-recovery.md` | `03-context-and-control/04-turn-loops-stop-hooks-and-recovery.md` |
| `05-context-assembly-and-query-pipeline.md` | `03-context-and-control/05-claude-code-context-assembly-and-query-pipeline.md` |
| `06-query-engine-and-turn-lifecycle.md` | `03-context-and-control/06-claude-code-query-engine-and-turn-lifecycle.md` |

### 7.5 Interfaces And Operator Surfaces

| 현재 경로 | 새 경로 |
| --- | --- |
| `interfaces/01-tool-contracts-and-the-agent-computer-interface.md` | `04-interfaces-and-operator-surfaces/01-tool-contracts-and-the-agent-computer-interface.md` |
| `interfaces/02-tool-shaping-permissions-and-capability-exposure.md` | `04-interfaces-and-operator-surfaces/02-tool-shaping-permissions-and-capability-exposure.md` |
| `interfaces/03-commands-skills-plugins-and-mcp.md` | `04-interfaces-and-operator-surfaces/03-commands-skills-plugins-and-mcp.md` |
| `interfaces/04-benchmarking-tool-surfaces.md` | `04-interfaces-and-operator-surfaces/04-benchmarking-tool-surfaces.md` |
| `execution/01-ui-transcripts-and-operator-control.md` | `04-interfaces-and-operator-surfaces/05-ui-transcripts-and-operator-control.md` |
| `07-command-system.md` | `04-interfaces-and-operator-surfaces/06-claude-code-command-system.md` |
| `08-tool-system-and-permissions.md` | `04-interfaces-and-operator-surfaces/07-claude-code-tool-system-and-permissions.md` |
| `09-state-ui-and-terminal-interaction.md` | `04-interfaces-and-operator-surfaces/08-claude-code-state-ui-and-terminal-interaction.md` |

### 7.6 Execution, Continuity, And Integrations

| 현재 경로 | 새 경로 |
| --- | --- |
| `execution/02-state-resumability-and-session-ownership.md` | `05-execution-continuity-and-integrations/01-state-resumability-and-session-ownership.md` |
| `execution/03-task-orchestration-and-long-running-execution.md` | `05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md` |
| `execution/04-human-oversight-trust-and-approval.md` | `05-execution-continuity-and-integrations/03-human-oversight-trust-and-approval.md` |
| `10-services-and-integrations.md` | `05-execution-continuity-and-integrations/04-claude-code-services-and-integrations.md` |
| `11-agent-skill-plugin-mcp-and-coordination.md` | `05-execution-continuity-and-integrations/05-claude-code-agent-skill-plugin-mcp-and-coordination.md` |
| `12-task-model-and-background-execution.md` | `05-execution-continuity-and-integrations/06-claude-code-task-model-and-background-execution.md` |
| `13-persistence-config-and-migrations.md` | `05-execution-continuity-and-integrations/07-claude-code-persistence-config-and-migrations.md` |

### 7.7 Boundaries, Deployment, And Safety

| 현재 경로 | 새 경로 |
| --- | --- |
| `safety/01-boundary-engineering-and-autonomy.md` | `06-boundaries-deployment-and-safety/01-boundary-engineering-and-autonomy.md` |
| `safety/02-sandboxing-permissions-and-policy-surfaces.md` | `06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md` |
| `safety/03-local-remote-bridge-and-direct-connect.md` | `06-boundaries-deployment-and-safety/03-local-remote-bridge-and-direct-connect.md` |
| `safety/04-safety-autonomy-benchmark.md` | `06-boundaries-deployment-and-safety/04-safety-autonomy-benchmark.md` |
| `14-remote-bridge-server-and-upstreamproxy.md` | `06-boundaries-deployment-and-safety/05-claude-code-remote-bridge-server-and-upstream-proxy.md` |
| `16-risks-debt-and-observations.md` | `06-boundaries-deployment-and-safety/06-claude-code-risks-debt-and-failure-modes.md` |

### 7.8 Evaluation And Synthesis

| 현재 경로 | 새 경로 |
| --- | --- |
| `evaluation/01-model-evals-vs-harness-evals.md` | `07-evaluation-and-synthesis/01-model-evals-vs-harness-evals.md` |
| `evaluation/02-tasks-trials-transcripts-and-graders.md` | `07-evaluation-and-synthesis/02-tasks-trials-transcripts-and-graders.md` |
| `evaluation/03-benchmarking-coding-harnesses.md` | `07-evaluation-and-synthesis/03-benchmarking-long-running-agent-harnesses.md` |
| `evaluation/04-production-traces-feedback-loops-and-optimization.md` | `07-evaluation-and-synthesis/04-production-traces-feedback-loops-and-optimization.md` |
| `evaluation/05-claude-code-benchmark-framework.md` | `07-evaluation-and-synthesis/05-harness-benchmark-framework.md` |
| `evaluation/06-contract-based-qa-and-skeptical-evaluators.md` | `07-evaluation-and-synthesis/06-contract-based-qa-and-skeptical-evaluators.md` |
| `17-end-to-end-scenarios.md` | `07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md` |
| `15-code-reading-guide.md` | `07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md` |

### 7.9 Reference

| 현재 경로 | 새 경로 |
| --- | --- |
| `appendix/glossary.md` | `08-reference/01-glossary.md` |
| `appendix/key-file-index.md` | `08-reference/02-key-file-index.md` |
| `appendix/directory-map.md` | `08-reference/03-directory-map.md` |
| `appendix/root-file-map.md` | `08-reference/04-root-file-map.md` |
| `appendix/conditional-features-map.md` | `08-reference/05-conditional-features-map.md` |

## 8. 새로 추가할 문서

각 주요 Part 앞에 짧은 `part guide`를 추가한다.

- `02-runtime-and-session-start/00-part-guide.md`
- `03-context-and-control/00-part-guide.md`
- `04-interfaces-and-operator-surfaces/00-part-guide.md`
- `05-execution-continuity-and-integrations/00-part-guide.md`
- `06-boundaries-deployment-and-safety/00-part-guide.md`
- `07-evaluation-and-synthesis/00-part-guide.md`

이 문서들은 길게 쓰지 않는다. 각 문서가 맡는 역할은 동일하다.

1. 이 Part의 핵심 질문 3~5개
2. 먼저 읽을 원칙 장 목록
3. 이어서 읽을 Claude Code 사례 장 목록
4. 필요한 경우 reference/workbook 연결

핵심은 새로운 이론을 추가하는 것이 아니라, 원칙과 사례의 접속점을 독자에게 즉시 보여 주는 것이다.

## 9. 내용 수정 원칙

### 9.1 사례 장 표기 규칙

Claude Code 사례 장은 다음 원칙을 따른다.

1. 파일명에 `claude-code-`를 명시한다.
2. 제목 첫 문단에서 "이 장은 Claude Code 사례를 통해 ..."라는 framing을 유지한다.
3. 장 초반에는 일반 문제를 먼저 말하고, 그 뒤에 Claude Code를 사례로 적용한다.

즉, 현재의 "`Claude Code의 X를 이렇게 읽자`" 중심 도입을 "`X는 왜 long-running harness 문제인가 -> Claude Code는 이 문제를 어떻게 드러내는가`" 순서로 바꾼다.

### 9.2 일반화 대상 장

다음 두 문서는 제목과 서문을 더 강하게 일반화한다.

#### `07-evaluation-and-synthesis/03-benchmarking-long-running-agent-harnesses.md`

- 기존 `coding harness` 중심 프레임을 `long-running agent harness` 일반 프레임으로 올린다.
- coding-specific 논점은 subsection으로 남긴다.
- 표와 benchmark axes는 더 넓은 agent runtime에도 적용 가능한 언어로 재정리한다.

#### `07-evaluation-and-synthesis/05-harness-benchmark-framework.md`

- 기존의 Claude Code 명시 제목을 일반 프레임 제목으로 바꾼다.
- Claude Code는 "worked example"로만 남긴다.
- 다른 harness에 이식 가능한 질문지가 전면에 와야 한다.

### 9.3 Reference 문서의 위치 신호

`08-reference/*` 문서는 본 서사 장과 구별되도록 `README`와 part guide에서 "lookup/reference" 역할을 명시한다. 독자가 이를 본문 서사의 필수 연속 장으로 오독하지 않게 만드는 것이 목적이다.

## 10. README 재작성 원칙

새 `README`는 다음 역할을 수행해야 한다.

1. 이 책이 일반 하네스 설계 원칙과 Claude Code 사례를 함께 다룬다고 첫 단락에서 명시한다.
2. Part 구조를 새 디렉터리 체계 기준으로 다시 제시한다.
3. "원칙 먼저, 사례는 같은 Part 안에서 읽는다"는 독서 규칙을 명시한다.
4. 빠른 시작 경로를 `Front Matter -> Foundations -> 원하는 문제 영역의 part guide` 방식으로 바꾼다.
5. `08-reference`는 보조 장치임을 분명히 한다.

## 11. 구현 순서

실제 개편은 아래 순서로 수행한다.

1. 새 디렉터리 구조 생성
2. 문서 파일 이동 및 리네이밍
3. 문서 내부 상대 링크 일괄 갱신
4. `README` 전면 개정
5. `00-front-matter` 링크 갱신
6. `00-part-guide.md` 문서 추가
7. 사례 장 제목과 장 서두 framing 수정
8. evaluation 일반화 대상 장 두 개 수정
9. `08-reference` 관련 링크와 설명 정리
10. lint 및 링크 검증

## 12. 검증 기준

개편 완료 판정은 아래 기준으로 내린다.

1. `README`만 읽어도 일반론 우선 구조가 분명해야 한다.
2. 사례 장 파일명만 봐도 Claude Code 사례 분석임이 드러나야 한다.
3. evaluation 파트 제목만 봐도 특정 제품 중심이 아니라 일반 하네스 비교 프레임으로 읽혀야 한다.
4. 모든 상대 링크가 유효해야 한다.
5. markdownlint가 통과해야 한다.
6. `15-code-reading-guide`의 후신 문서는 본체 서사보다 workbook/reference 성격으로 읽혀야 한다.

## 13. 위험과 대응

### 13.1 상대 링크 대량 파손

- 대응: 파일 이동 후 링크 일괄 검색과 lint를 반드시 수행한다.

### 13.2 기존 번호 체계 기억 상실

- 대응: `README`와 각 part guide에 "이전 경로/새 경로" 맥락을 짧게 제공한다. 다만 영구적인 migration appendix를 길게 둘 필요는 없다.

### 13.3 일반화 과잉

- 대응: 사례 장의 제품 사실과 provenance를 유지한다. 일반화는 evaluation 장과 서문 framing 중심으로 제한한다.

### 13.4 reference와 본체의 재혼선

- 대응: `08-reference`를 별도 Part로 분리하고, 본문에서 lookup 성격을 반복적으로 명시한다.

## 14. 승인된 결정 요약

이번 설계에서 이미 확정된 결정은 다음과 같다.

1. 파일 경로와 챕터 번호까지 실제로 바꾼다.
2. 결과물은 "한 권의 책 안에서 원칙과 사례를 왕복"하는 구조로 만든다.
3. 개편 방식은 `Paired Parts` 재구성형을 따른다.
4. 사례 장에는 `claude-code-` 접두를 사용한다.
5. `15-code-reading-guide`는 사례 spine 본체가 아니라 synthesis/reference 쪽으로 내린다.
6. evaluation의 일부 coding-harness 편향은 일반 하네스 프레임으로 다시 고정한다.

## 15. 다음 단계

이 스펙이 승인된 상태이므로, 다음 구현 세션에서는 이 문서를 기준으로 실제 파일 이동과 링크 재구성을 수행한다. 구현이 끝나면 `README`, part guide, evaluation 일반화, 링크 검증 결과를 함께 점검한다.
