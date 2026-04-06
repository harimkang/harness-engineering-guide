# Harness Engineering: Designing Operational Systems for Long-Running Agents

> Last verified against official docs: 2026-04-06
> Volatile topics: Claude Code settings, skills, CLI flags, MCP client semantics, remote/bridge behavior, tracing and eval tooling
> Source policy: proposal `S*` IDs are immutable canonical references; supplemental research and observed artifacts use separate IDs
> Reader paths: `first-pass`, `builder/reviewer`, `source-first`, `volatile re-check`
> Freshness baseline: reader-entry and reference scaffolds were normalized on 2026-04-06; watchlist and evidence-pack practice live in [00-front-matter/03-references.md](./00-front-matter/03-references.md) and [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)

장기 실행형 에이전트 하네스를 설계, 분석, 평가하기 위한 책형 문서 세트입니다. 이 책은 일반적인 harness engineering 원칙을 먼저 세우고, Claude Code를 반복 사례로 사용해 그 원칙이 실제 product runtime에 어떻게 드러나는지 보여 줍니다.

읽는 단위는 기능 목록이 아니라 운영 문제입니다. context를 어떻게 조립하고 줄일지, tool과 permission을 어떤 계약 표면으로 설계할지, 사람이 언제 개입하고 어떤 artifact가 continuity와 reviewability를 떠받칠지, observability와 economics를 어떤 운영 표면으로 끌어올릴지, deployment boundary와 eval loop를 어디에 둘지를 문서 전체에서 일관된 언어로 다룹니다.

이 문서세트는 proposal에 정리한 공식 출처를 canonical source registry로 사용합니다. reader-facing 본문을 실질적으로 수정할 때는 먼저 관련 proposal source ID의 공식 문서와 사양을 다시 확인하고, 그 근거를 [00-front-matter/03-references.md](./00-front-matter/03-references.md)와 각 장의 evidence note에 반영해야 합니다. source tier, freshness class, observed-artifact citation 규칙은 [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)에 고정합니다.

## 이 책이 하는 일

- 하네스를 단순 프롬프트 묶음이 아니라 운영 시스템으로 읽는다.
- 일반 원칙과 Claude Code 사례를 왕복하면서 설계 언어를 만든다.
- 평가를 뒤에 붙는 부록이 아니라 설계와 운영의 일부로 다룬다.
- instruction surfaces, observability/economics, governance, eval hygiene, reviewability를 독립 설계면으로 끌어올린다.

## 이 책이 하지 않는 일

- 일반 LLM 입문서 역할
- 모델 학습, 파인튜닝, 내부 가중치 분석
- 비공개 구현을 추정해 채워 넣는 일
- 특정 제품의 기능 소개 문서를 대체하는 일

## 이 레포를 어떻게 읽는가

- 처음 읽는다면 `README -> 00-front-matter -> 01-foundations -> 관심 있는 part guide` 순서가 가장 안전합니다.
- 각 Part는 원칙 장으로 시작하고, 바로 이어지는 Claude Code 사례 장으로 그 원칙을 구체화합니다.
- Claude Code 사례 장은 파일명에 `claude-code-`가 들어가므로 일반론과 빠르게 구분할 수 있습니다.
- `08-reference`는 본문 서사가 아니라 lookup, tagging, source re-entry를 돕는 보조 장치입니다.

## 가장 빠른 시작 경로

1. [README.md](./README.md)
2. [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md)
3. [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)
4. [00-front-matter/03-references.md](./00-front-matter/03-references.md)
5. [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md)
6. [02-runtime-and-session-start/00-part-guide.md](./02-runtime-and-session-start/00-part-guide.md)

이 여섯 문서를 먼저 읽으면 독서 규칙, 근거 체계, 기본 개념, 그리고 paired-parts 독서 흐름이 한 번에 고정됩니다.

## Canonical Reader Paths

- `first-pass`: [README.md](./README.md) -> [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md) -> [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md) -> 관심 있는 `00-part-guide.md`
- `builder/reviewer`: foundations 핵심 장 뒤에 관련 Part guide와 synthesis 장을 붙여 읽는다.
- `source-first`: [07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md](./07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md)와 [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md)에서 provenance를 잡고 본문으로 되돌아간다.
- `volatile re-check`: settings, MCP, tracing, remote, eval tooling처럼 drift 가능성이 큰 주제를 만질 때는 [00-front-matter/03-references.md](./00-front-matter/03-references.md)의 watchlist와 `S*` IDs를 먼저 다시 연다.

## 초심자 90분 코스

1. [README.md](./README.md)
2. [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md)
3. [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md)
4. [01-foundations/02-workflows-agents-runtimes-and-harnesses.md](./01-foundations/02-workflows-agents-runtimes-and-harnesses.md)
5. [02-runtime-and-session-start/00-part-guide.md](./02-runtime-and-session-start/00-part-guide.md)
6. [03-context-and-control/01-context-as-an-operational-resource.md](./03-context-and-control/01-context-as-an-operational-resource.md)
7. [04-interfaces-and-operator-surfaces/01-tool-contracts-and-the-agent-computer-interface.md](./04-interfaces-and-operator-surfaces/01-tool-contracts-and-the-agent-computer-interface.md)
8. [07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](./07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)

## 이 책이 다루는 질문

- context를 무엇으로 채우고 언제 버릴 것인가
- context reset과 compaction을 언제 구분할 것인가
- 여러 턴, interruption, recovery, handoff를 어떻게 운영할 것인가
- tool, command, skill, plugin, MCP를 어떤 계약 표면으로 설계할 것인가
- settings, hooks, `CLAUDE.md`, subagents, CLI flags 같은 instruction surface를 어떻게 읽을 것인가
- observability, traces, run artifacts, cost, latency, headroom을 언제 운영 문제로 끌어올릴 것인가
- sandbox, trust, remote boundary를 어디에 둘 것인가
- model eval이 아니라 harness eval을 어떻게 설계할 것인가

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
- 하네스를 독립된 설계 영역으로 읽는 기본 축을 세우고, observability, economics, reviewability, evaluator-driven design을 foundations 수준에서 드러낸다.
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
- 일반론: tool contract, permission shaping, extension surfaces, instruction surfaces, tool benchmark
- 사례: Claude Code의 command system, tool system/permissions, state/UI/terminal

### Part 5. Execution, Continuity, And Integrations

- [05-execution-continuity-and-integrations/00-part-guide.md](./05-execution-continuity-and-integrations/00-part-guide.md)
- 일반론: resumability, task orchestration, human oversight, observability, cost/economics
- 사례: Claude Code의 services/integrations, MCP/skills/plugins, task model, persistence

### Part 6. Boundaries, Deployment, And Safety

- [06-boundaries-deployment-and-safety/00-part-guide.md](./06-boundaries-deployment-and-safety/00-part-guide.md)
- 일반론: boundary engineering, sandboxing/policy surfaces, local/remote family, safety-autonomy benchmark, governance mapping
- 사례: Claude Code의 remote/bridge/direct-connect/upstream proxy, risks/debt/failure modes

### Part 7. Evaluation And Synthesis

- [07-evaluation-and-synthesis/00-part-guide.md](./07-evaluation-and-synthesis/00-part-guide.md)
- 일반론: model eval vs harness eval, tasks/trials/transcripts/graders, benchmark framework, production traces, skeptical evaluator, eval hygiene
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
  이 책의 source tier, freshness 분류, observed-artifact citation, source verification 규칙을 설명합니다.
- [00-front-matter/03-references.md](./00-front-matter/03-references.md)
  공식 문서, 엔지니어링 글, 사양, 프레임워크 문서, supplemental research, observed artifact의 canonical registry와 proposal source ID 재진입 지점을 모아 둡니다.
- [08-reference/01-glossary.md](./08-reference/01-glossary.md)
  핵심 용어의 정의, 차이, confusable terms를 모아 둡니다.
- [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md)
  benchmark question 중심으로 어떤 발췌와 provenance label을 다시 볼지 정리할 때 씁니다.

## Freshness Baseline

- entry path는 `README -> 00-front-matter -> foundations -> part guide -> chapter -> 08-reference` 순서로 통일한다.
- volatile chapter를 고칠 때는 `Last verified`, `Freshness class`, `Sources / evidence notes`를 함께 갱신한다.
- 주요 개정 시에는 checked docs list, checked release notes window, observed artifact snapshot identifiers, changed chapters를 evidence-pack 메모로 남긴다.

## 이 레포를 갱신할 때

- 새 문서를 추가할 때는 먼저 어느 Part의 원칙/사례/reference에 속하는지 결정합니다.
- 독서 경로나 Part 구성이 바뀌면 이 `README`와 관련 `00-part-guide.md`를 함께 갱신합니다.
- 새 외부 자료가 본문에 들어오면 [00-front-matter/03-references.md](./00-front-matter/03-references.md)를 함께 갱신합니다.
- substantive change를 넣기 전에 proposal에 정리한 공식 출처와 관련 `S*` ID를 먼저 다시 확인합니다.
- supplemental research와 observed artifact는 canonical `S*` ID를 재사용하지 않고 별도 ID로 등록합니다.
- volatile chapter는 verified date와 freshness class를 함께 갱신합니다.
