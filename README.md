# Harness Engineering: Designing Operational Systems for Long-Running Agents

장기 실행형 에이전트 하네스를 설계, 분석, 평가하기 위한 책형 문서 세트입니다. 이 레포는 reader-facing corpus만으로 읽히도록 구성되어 있으며, 개별 제품 소개보다 운영 시스템으로서의 에이전트 런타임을 이해하는 데 초점을 둡니다.

읽는 단위는 기능 목록이 아니라 운영 문제입니다. 컨텍스트를 어떻게 조립하고 줄일지, 도구와 권한을 어떤 계약 표면으로 설계할지, 사람이 어디서 개입할지, 장기 실행을 어떤 상태와 artifact로 이어갈지, benchmark와 eval을 어떤 단위로 구성할지를 문서 전체에서 일관된 언어로 다룹니다.

## 이 레포를 어떻게 쓰는가

- 처음 읽는다면 `README -> 00-how-to-read-this-book -> appendix/source-analysis-method -> foundations/01` 순서가 가장 안전합니다.
- 특정 주제만 보고 싶다면 아래 `Part 지도`에서 해당 파트로 바로 이동하면 됩니다.
- 빠르게 찾아볼 때는 `appendix/`의 용어집, file index, directory map을 먼저 여는 편이 효율적입니다.
- 본문에 나오는 경로 표기는 provenance 메모입니다. reader-facing corpus는 이 레포 안의 문서들입니다.

## 가장 빠른 시작 경로

1. 이 포털 [README.md](./README.md)
2. [00-how-to-read-this-book.md](./00-how-to-read-this-book.md)
3. [appendix/source-analysis-method.md](./appendix/source-analysis-method.md)
4. [appendix/references.md](./appendix/references.md)
5. [foundations/01-why-harness-engineering-matters.md](./foundations/01-why-harness-engineering-matters.md)
6. [01-project-overview.md](./01-project-overview.md)

이 여섯 문서를 먼저 읽으면 이 책의 독서 규칙, 근거 체계, 일반 원칙, 사례 입구가 한 번에 고정된다.

## 이 책이 다루는 질문

- 컨텍스트를 무엇으로 채우고 언제 버릴 것인가
- 여러 턴, 중단, 회복, handoff를 어떻게 운영할 것인가
- tool, command, skill, plugin, MCP를 어떤 계약 표면으로 설계할 것인가
- 운영자가 언제 보고 개입하고 승인해야 하는가
- sandbox, trust, remote boundary를 어디에 둘 것인가
- model eval이 아니라 harness eval을 어떻게 설계할 것인가

## 레포 구성

- 서문과 방법론: [00-how-to-read-this-book.md](./00-how-to-read-this-book.md), [appendix/source-analysis-method.md](./appendix/source-analysis-method.md), [appendix/references.md](./appendix/references.md)
- 원칙 파트: `foundations/**`, `context/**`, `interfaces/**`, `execution/**`, `safety/**`, `evaluation/**`
- 사례 spine: [01-project-overview.md](./01-project-overview.md)부터 [17-end-to-end-scenarios.md](./17-end-to-end-scenarios.md)까지
- 참조 부록: [appendix/glossary.md](./appendix/glossary.md), [appendix/key-file-index.md](./appendix/key-file-index.md), [appendix/directory-map.md](./appendix/directory-map.md), [appendix/root-file-map.md](./appendix/root-file-map.md), [appendix/conditional-features-map.md](./appendix/conditional-features-map.md)

## Part 지도

### Part 0. Front Matter

- [00-how-to-read-this-book.md](./00-how-to-read-this-book.md)
- [appendix/source-analysis-method.md](./appendix/source-analysis-method.md)
- [appendix/references.md](./appendix/references.md)

역할:

- 이 책의 목적, 독서 리듬, 주장 층위, 출처 규칙을 고정한다.

### Part I. Foundations of Harness Engineering

- [foundations/01-why-harness-engineering-matters.md](./foundations/01-why-harness-engineering-matters.md)
- [foundations/02-workflows-agents-runtimes-and-harnesses.md](./foundations/02-workflows-agents-runtimes-and-harnesses.md)
- [foundations/03-quality-attributes-of-agent-harnesses.md](./foundations/03-quality-attributes-of-agent-harnesses.md)
- [foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md](./foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md)

역할:

- workflow, agent, runtime, harness, eval harness를 구분한다.
- 하네스를 독립된 설계 영역으로 읽는 기본 축을 세운다.

### Part II. Context and Cognitive Control

- [context/01-context-as-an-operational-resource.md](./context/01-context-as-an-operational-resource.md)
- [context/02-context-classes-boundaries-and-scopes.md](./context/02-context-classes-boundaries-and-scopes.md)
- [context/03-compaction-memory-and-handoff-artifacts.md](./context/03-compaction-memory-and-handoff-artifacts.md)
- [context/04-turn-loops-stop-hooks-and-recovery.md](./context/04-turn-loops-stop-hooks-and-recovery.md)

역할:

- context를 prompt가 아니라 운영 자원으로 읽는다.
- compaction, handoff artifact, recovery를 control 문제로 묶어 설명한다.

### Part III. Tooling, Interfaces, and Extension Surfaces

- [interfaces/01-tool-contracts-and-the-agent-computer-interface.md](./interfaces/01-tool-contracts-and-the-agent-computer-interface.md)
- [interfaces/02-tool-shaping-permissions-and-capability-exposure.md](./interfaces/02-tool-shaping-permissions-and-capability-exposure.md)
- [interfaces/03-commands-skills-plugins-and-mcp.md](./interfaces/03-commands-skills-plugins-and-mcp.md)
- [interfaces/04-benchmarking-tool-surfaces.md](./interfaces/04-benchmarking-tool-surfaces.md)

역할:

- tool을 함수 모음이 아니라 agent-computer interface로 설명한다.
- capability exposure와 permission boundary를 분리해 읽게 한다.

### Part IV. Execution, State, and Human Oversight

- [execution/01-ui-transcripts-and-operator-control.md](./execution/01-ui-transcripts-and-operator-control.md)
- [execution/02-state-resumability-and-session-ownership.md](./execution/02-state-resumability-and-session-ownership.md)
- [execution/03-task-orchestration-and-long-running-execution.md](./execution/03-task-orchestration-and-long-running-execution.md)
- [execution/04-human-oversight-trust-and-approval.md](./execution/04-human-oversight-trust-and-approval.md)

역할:

- UI, transcript, resumability, task artifact, human oversight를 하나의 실행 표면으로 묶는다.

### Part V. Safety, Boundaries, and Deployment Constraints

- [safety/01-boundary-engineering-and-autonomy.md](./safety/01-boundary-engineering-and-autonomy.md)
- [safety/02-sandboxing-permissions-and-policy-surfaces.md](./safety/02-sandboxing-permissions-and-policy-surfaces.md)
- [safety/03-local-remote-bridge-and-direct-connect.md](./safety/03-local-remote-bridge-and-direct-connect.md)
- [safety/04-safety-autonomy-benchmark.md](./safety/04-safety-autonomy-benchmark.md)

역할:

- sandbox, approval, trust, remote boundary를 한데 묶어 비교한다.

### Part VI. Evaluation, Optimization, and Benchmarking

- [evaluation/01-model-evals-vs-harness-evals.md](./evaluation/01-model-evals-vs-harness-evals.md)
- [evaluation/02-tasks-trials-transcripts-and-graders.md](./evaluation/02-tasks-trials-transcripts-and-graders.md)
- [evaluation/03-benchmarking-coding-harnesses.md](./evaluation/03-benchmarking-coding-harnesses.md)
- [evaluation/04-production-traces-feedback-loops-and-optimization.md](./evaluation/04-production-traces-feedback-loops-and-optimization.md)
- [evaluation/05-claude-code-benchmark-framework.md](./evaluation/05-claude-code-benchmark-framework.md)

역할:

- model eval과 harness eval을 분리한다.
- production trace, grader, optimization loop를 하나의 benchmark language로 묶는다.

### Part VII. Claude Code Case Study Spine

- runtime과 startup: [01-project-overview.md](./01-project-overview.md), [02-architecture-map.md](./02-architecture-map.md), [03-runtime-modes-and-entrypoints.md](./03-runtime-modes-and-entrypoints.md), [04-session-startup-trust-and-initialization.md](./04-session-startup-trust-and-initialization.md)
- context와 제어: [05-context-assembly-and-query-pipeline.md](./05-context-assembly-and-query-pipeline.md), [06-query-engine-and-turn-lifecycle.md](./06-query-engine-and-turn-lifecycle.md)
- operator surface: [07-command-system.md](./07-command-system.md), [08-tool-system-and-permissions.md](./08-tool-system-and-permissions.md), [09-state-ui-and-terminal-interaction.md](./09-state-ui-and-terminal-interaction.md)
- 확장과 장기 실행: [10-services-and-integrations.md](./10-services-and-integrations.md), [11-agent-skill-plugin-mcp-and-coordination.md](./11-agent-skill-plugin-mcp-and-coordination.md), [12-task-model-and-background-execution.md](./12-task-model-and-background-execution.md), [13-persistence-config-and-migrations.md](./13-persistence-config-and-migrations.md), [14-remote-bridge-server-and-upstreamproxy.md](./14-remote-bridge-server-and-upstreamproxy.md)
- synthesis: [15-code-reading-guide.md](./15-code-reading-guide.md), [16-risks-debt-and-observations.md](./16-risks-debt-and-observations.md), [17-end-to-end-scenarios.md](./17-end-to-end-scenarios.md)

역할:

- 원칙 spine에서 세운 개념을 사례 구조에 다시 연결한다.

### Part VIII. Workbook and Reference

- [appendix/glossary.md](./appendix/glossary.md)
- [appendix/key-file-index.md](./appendix/key-file-index.md)
- [appendix/directory-map.md](./appendix/directory-map.md)
- [appendix/root-file-map.md](./appendix/root-file-map.md)
- [appendix/conditional-features-map.md](./appendix/conditional-features-map.md)

역할:

- 용어 확인, file lookup, feature gate 추적, source re-entry를 돕는다.

## 독자별 권장 경로

### 제품 하네스 설계자

1. [foundations/01-why-harness-engineering-matters.md](./foundations/01-why-harness-engineering-matters.md)
2. [foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md](./foundations/04-core-design-axes-context-control-tools-memory-safety-evals.md)
3. [context/01-context-as-an-operational-resource.md](./context/01-context-as-an-operational-resource.md)
4. [interfaces/01-tool-contracts-and-the-agent-computer-interface.md](./interfaces/01-tool-contracts-and-the-agent-computer-interface.md)
5. [execution/03-task-orchestration-and-long-running-execution.md](./execution/03-task-orchestration-and-long-running-execution.md)
6. [safety/02-sandboxing-permissions-and-policy-surfaces.md](./safety/02-sandboxing-permissions-and-policy-surfaces.md)
7. [evaluation/03-benchmarking-coding-harnesses.md](./evaluation/03-benchmarking-coding-harnesses.md)
8. [17-end-to-end-scenarios.md](./17-end-to-end-scenarios.md)

### 연구자와 아키텍처 리뷰어

1. [00-how-to-read-this-book.md](./00-how-to-read-this-book.md)
2. [appendix/source-analysis-method.md](./appendix/source-analysis-method.md)
3. [appendix/references.md](./appendix/references.md)
4. [02-architecture-map.md](./02-architecture-map.md)
5. [06-query-engine-and-turn-lifecycle.md](./06-query-engine-and-turn-lifecycle.md)
6. [16-risks-debt-and-observations.md](./16-risks-debt-and-observations.md)
7. [evaluation/01-model-evals-vs-harness-evals.md](./evaluation/01-model-evals-vs-harness-evals.md)
8. [17-end-to-end-scenarios.md](./17-end-to-end-scenarios.md)

### 코드 독해 중심 독자

1. [15-code-reading-guide.md](./15-code-reading-guide.md)
2. [appendix/key-file-index.md](./appendix/key-file-index.md)
3. [01-project-overview.md](./01-project-overview.md)
4. [02-architecture-map.md](./02-architecture-map.md)
5. [05-context-assembly-and-query-pipeline.md](./05-context-assembly-and-query-pipeline.md)
6. [08-tool-system-and-permissions.md](./08-tool-system-and-permissions.md)
7. [12-task-model-and-background-execution.md](./12-task-model-and-background-execution.md)
8. [14-remote-bridge-server-and-upstreamproxy.md](./14-remote-bridge-server-and-upstreamproxy.md)

## 핵심 참조 장치

- [appendix/source-analysis-method.md](./appendix/source-analysis-method.md)
  이 책의 증거 규칙과 chapter scaffold 규칙을 설명한다.
- [appendix/references.md](./appendix/references.md)
  외부 참고 문헌과 canonical source registry를 모아 둔다.
- [appendix/glossary.md](./appendix/glossary.md)
  핵심 용어의 정의, 차이, 대표 근거 라벨을 모아 둔다.
- [appendix/key-file-index.md](./appendix/key-file-index.md)
  benchmark question 중심으로 어떤 발췌와 provenance label을 다시 볼지 정리할 때 쓴다.

## 이 레포를 갱신할 때

- 독서 경로나 Part 구성이 바뀌면 이 README를 함께 갱신한다.
- 새 외부 자료가 본문에 들어오면 [appendix/references.md](./appendix/references.md)를 함께 갱신한다.
- reader-facing corpus만으로 읽히는 입구 구조를 유지한다.
