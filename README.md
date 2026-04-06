# Harness Engineering: Designing Operational Systems for Long-Running Agents

장기 실행형 에이전트 하네스를 설계, 분석, 평가하기 위한 책형 문서 세트입니다. 이 책은 일반적인 harness engineering 원칙을 먼저 세우고, Claude Code를 반복 사례로 사용해 그 원칙이 실제 product runtime에 어떻게 드러나는지 보여 줍니다.

읽는 단위는 기능 목록이 아니라 운영 문제입니다. context를 어떻게 조립하고 줄일지, tool과 permission을 어떤 계약 표면으로 설계할지, 사람이 언제 개입하고 어떤 artifact가 continuity를 떠받칠지, deployment boundary와 eval loop를 어디에 둘지를 문서 전체에서 일관된 언어로 다룹니다.

## 이 레포를 어떻게 읽는가

- 처음 읽는다면 `README -> 00-front-matter -> 01-foundations -> 관심 있는 part guide` 순서가 가장 안전합니다.
- 각 Part는 원칙 장으로 시작하고, 바로 이어지는 Claude Code 사례 장으로 그 원칙을 구체화합니다.
- Claude Code 사례 장은 파일명에 `claude-code-`가 들어가므로 일반론과 빠르게 구분할 수 있습니다.
- `08-reference`는 본문 서사가 아니라 lookup과 source re-entry를 돕는 보조 장치입니다.

## 가장 빠른 시작 경로

1. [README.md](./README.md)
2. [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md)
3. [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)
4. [00-front-matter/03-references.md](./00-front-matter/03-references.md)
5. [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md)
6. [02-runtime-and-session-start/00-part-guide.md](./02-runtime-and-session-start/00-part-guide.md)

이 여섯 문서를 먼저 읽으면 독서 규칙, 근거 체계, 기본 개념, 그리고 새 paired-parts 독서 흐름이 한 번에 고정됩니다.

## 이 책이 다루는 질문

- context를 무엇으로 채우고 언제 버릴 것인가
- context reset과 compaction을 언제 구분할 것인가
- 여러 턴, interruption, recovery, handoff를 어떻게 운영할 것인가
- tool, command, skill, plugin, MCP를 어떤 계약 표면으로 설계할 것인가
- 운영자가 언제 보고 개입하고 승인해야 하는가
- sandbox, trust, remote boundary를 어디에 둘 것인가
- model eval이 아니라 harness eval을 어떻게 설계할 것인가
- self-evaluation failure를 external evaluator, explicit criteria, contract-based QA로 어떻게 보완할 것인가

## 레포 구성

- front matter: [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md), [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md), [00-front-matter/03-references.md](./00-front-matter/03-references.md)
- foundations: [`01-foundations/`](./01-foundations)
- paired principle/case parts: [`02-runtime-and-session-start/`](./02-runtime-and-session-start)부터 [`07-evaluation-and-synthesis/`](./07-evaluation-and-synthesis)까지
- reference: [`08-reference/`](./08-reference)

## Part 지도

### Part 0. Front Matter

- [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md)
- [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)
- [00-front-matter/03-references.md](./00-front-matter/03-references.md)

역할:

- 이 책의 목적, 독서 리듬, 주장 층위, 출처 규칙을 고정한다.

### Part 1. Foundations

- [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md)
- [01-foundations/02-workflows-agents-runtimes-and-harnesses.md](./01-foundations/02-workflows-agents-runtimes-and-harnesses.md)
- [01-foundations/03-quality-attributes-of-agent-harnesses.md](./01-foundations/03-quality-attributes-of-agent-harnesses.md)
- [01-foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md](./01-foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md)
- [01-foundations/05-evaluator-driven-harness-design.md](./01-foundations/05-evaluator-driven-harness-design.md)

역할:

- workflow, runtime, harness, eval harness를 구분한다.
- 하네스를 독립된 설계 영역으로 읽는 기본 축을 세운다.
- 이후 paired parts를 읽기 위한 공통 기반을 제공한다.

### Part 2. Runtime And Session Start

- [02-runtime-and-session-start/00-part-guide.md](./02-runtime-and-session-start/00-part-guide.md)
- 일반론: runtime family, startup contract, trust boundary
- 사례: Claude Code의 project overview, architecture map, runtime modes, startup/trust

### Part 3. Context And Control

- [03-context-and-control/00-part-guide.md](./03-context-and-control/00-part-guide.md)
- 일반론: context as resource, context classes, compaction/memory/handoff, turn loop/recovery
- 사례: Claude Code의 context assembly/query pipeline, QueryEngine/turn lifecycle

### Part 4. Interfaces And Operator Surfaces

- [04-interfaces-and-operator-surfaces/00-part-guide.md](./04-interfaces-and-operator-surfaces/00-part-guide.md)
- 일반론: tool contract, permission shaping, extension surfaces, tool benchmark
- 사례: Claude Code의 command system, tool system/permissions, state/UI/terminal

### Part 5. Execution, Continuity, And Integrations

- [05-execution-continuity-and-integrations/00-part-guide.md](./05-execution-continuity-and-integrations/00-part-guide.md)
- 일반론: resumability, task orchestration, human oversight
- 사례: Claude Code의 services/integrations, MCP/skills/plugins, task model, persistence

### Part 6. Boundaries, Deployment, And Safety

- [06-boundaries-deployment-and-safety/00-part-guide.md](./06-boundaries-deployment-and-safety/00-part-guide.md)
- 일반론: boundary engineering, sandboxing/policy surfaces, local/remote family, safety-autonomy benchmark
- 사례: Claude Code의 remote/bridge/direct-connect/upstream proxy, risks/debt/failure modes

### Part 7. Evaluation And Synthesis

- [07-evaluation-and-synthesis/00-part-guide.md](./07-evaluation-and-synthesis/00-part-guide.md)
- 일반론: model eval vs harness eval, tasks/trials/transcripts/graders, benchmark framework, production traces, skeptical evaluator
- 사례/종합: Claude Code end-to-end scenarios, benchmark-oriented code reading guide

### Part 8. Reference

- [08-reference/01-glossary.md](./08-reference/01-glossary.md)
- [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md)
- [08-reference/03-directory-map.md](./08-reference/03-directory-map.md)
- [08-reference/04-root-file-map.md](./08-reference/04-root-file-map.md)
- [08-reference/05-conditional-features-map.md](./08-reference/05-conditional-features-map.md)

역할:

- 용어 확인, file lookup, feature gate 추적, source re-entry를 돕는다.

## 독자별 권장 경로

### 제품 하네스 설계자

1. [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md)
2. [01-foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md](./01-foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md)
3. [01-foundations/05-evaluator-driven-harness-design.md](./01-foundations/05-evaluator-driven-harness-design.md)
4. [03-context-and-control/00-part-guide.md](./03-context-and-control/00-part-guide.md)
5. [04-interfaces-and-operator-surfaces/00-part-guide.md](./04-interfaces-and-operator-surfaces/00-part-guide.md)
6. [05-execution-continuity-and-integrations/00-part-guide.md](./05-execution-continuity-and-integrations/00-part-guide.md)
7. [07-evaluation-and-synthesis/06-contract-based-qa-and-skeptical-evaluators.md](./07-evaluation-and-synthesis/06-contract-based-qa-and-skeptical-evaluators.md)
8. [07-evaluation-and-synthesis/03-benchmarking-long-running-agent-harnesses.md](./07-evaluation-and-synthesis/03-benchmarking-long-running-agent-harnesses.md)
9. [07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](./07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)

### 연구자와 아키텍처 리뷰어

1. [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md)
2. [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)
3. [00-front-matter/03-references.md](./00-front-matter/03-references.md)
4. [02-runtime-and-session-start/00-part-guide.md](./02-runtime-and-session-start/00-part-guide.md)
5. [03-context-and-control/06-claude-code-query-engine-and-turn-lifecycle.md](./03-context-and-control/06-claude-code-query-engine-and-turn-lifecycle.md)
6. [06-boundaries-deployment-and-safety/06-claude-code-risks-debt-and-failure-modes.md](./06-boundaries-deployment-and-safety/06-claude-code-risks-debt-and-failure-modes.md)
7. [07-evaluation-and-synthesis/01-model-evals-vs-harness-evals.md](./07-evaluation-and-synthesis/01-model-evals-vs-harness-evals.md)
8. [07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](./07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)

### 코드 독해 중심 독자

1. [07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md](./07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md)
2. [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md)
3. [02-runtime-and-session-start/03-claude-code-project-overview.md](./02-runtime-and-session-start/03-claude-code-project-overview.md)
4. [02-runtime-and-session-start/04-claude-code-architecture-map.md](./02-runtime-and-session-start/04-claude-code-architecture-map.md)
5. [03-context-and-control/05-claude-code-context-assembly-and-query-pipeline.md](./03-context-and-control/05-claude-code-context-assembly-and-query-pipeline.md)
6. [04-interfaces-and-operator-surfaces/07-claude-code-tool-system-and-permissions.md](./04-interfaces-and-operator-surfaces/07-claude-code-tool-system-and-permissions.md)
7. [05-execution-continuity-and-integrations/06-claude-code-task-model-and-background-execution.md](./05-execution-continuity-and-integrations/06-claude-code-task-model-and-background-execution.md)
8. [06-boundaries-deployment-and-safety/05-claude-code-remote-bridge-server-and-upstream-proxy.md](./06-boundaries-deployment-and-safety/05-claude-code-remote-bridge-server-and-upstream-proxy.md)

## 핵심 참조 장치

- [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)
  이 책의 증거 규칙과 chapter scaffold 규칙을 설명한다.
- [00-front-matter/03-references.md](./00-front-matter/03-references.md)
  외부 참고 문헌과 canonical source registry를 모아 둔다.
- [08-reference/01-glossary.md](./08-reference/01-glossary.md)
  핵심 용어의 정의, 차이, 대표 근거 라벨을 모아 둔다.
- [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md)
  benchmark question 중심으로 어떤 발췌와 provenance label을 다시 볼지 정리할 때 쓴다.

## 이 레포를 갱신할 때

- 새 문서를 추가할 때는 먼저 어느 Part의 원칙/사례/reference에 속하는지 결정한다.
- 독서 경로나 Part 구성이 바뀌면 이 `README`와 관련 `00-part-guide.md`를 함께 갱신한다.
- 새 외부 자료가 본문에 들어오면 [00-front-matter/03-references.md](./00-front-matter/03-references.md)를 함께 갱신한다.
- reader-facing corpus만으로 읽히는 입구 구조를 유지한다.
