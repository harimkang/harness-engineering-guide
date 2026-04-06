# 하네스 엔지니어링: Claude Code 사례로 읽는 운영 시스템 설계

## 장 요약

이 문서 세트는 Claude Code 공개 사본을 중심 사례로 삼아 장기 실행형 에이전트 하네스를 읽고 설계하는 방법을 설명하는 책이다. 이 책의 관심사는 "이 파일이 무슨 기능을 하는가"에만 머무르지 않는다. 더 중요한 질문은 "어떤 운영 문제가 여기서 해결되는가", "그 문제를 일반적인 하네스 설계 언어로 어떻게 옮겨 읽을 수 있는가", "내 시스템과 비교할 때 무엇을 측정해야 하는가"다.

Claude Code는 이 책의 주인공이 아니라 기준 사례다. 이 문서 세트는 공개 사본의 source tree, Anthropic의 공식 engineering 글과 Platform 문서, 최근 하네스 연구를 함께 읽어 일반 설계 원칙을 끌어내는 것을 목표로 한다.

## 대표 코드 발췌

이 책이 소스 경로 자체보다 발췌와 해설을 우선하는 이유는 아래처럼 REPL의 실제 composition seam이 몇 줄의 코드에서 바로 드러나기 때문이다.

```tsx
for await (const event of query({
  messages: messagesIncludingNewMessages,
  systemPrompt,
  userContext,
  systemContext,
  canUseTool,
  toolUseContext,
  querySource: getQuerySourceForREPL()
})) {
  onQueryEvent(event);
}
```

이 발췌는 공개 사본의 `src/screens/REPL.tsx`에서 가져왔다. 이 책은 이런 식의 짧은 code block을 근거로 삼아, 런타임 ownership과 query loop의 연결을 설명한다.

## 이 책이 다루는 질문

- 컨텍스트를 무엇으로 채우고 언제 버릴 것인가
- 여러 턴, 중단, 회복, handoff를 어떻게 운영할 것인가
- tool, command, skill, plugin, MCP를 어떤 계약 표면으로 설계할 것인가
- 운영자가 언제 보고 개입하고 승인해야 하는가
- sandbox, trust, remote boundary를 어디에 둘 것인가
- model eval이 아니라 harness eval을 어떻게 설계할 것인가

## 독자용 출판 범위

이 README가 안내하는 독자용 범위는 다음 집합이다.

- 서문과 방법론: [00-how-to-read-this-book.md](./00-how-to-read-this-book.md), [appendix/source-analysis-method.md](./appendix/source-analysis-method.md), [appendix/references.md](./appendix/references.md)
- 원칙 파트: `foundations/**`, `context/**`, `interfaces/**`, `execution/**`, `safety/**`, `evaluation/**`
- 사례 spine: [01-project-overview.md](./01-project-overview.md)부터 [17-end-to-end-scenarios.md](./17-end-to-end-scenarios.md)까지
- 참조 부록: [appendix/glossary.md](./appendix/glossary.md), [appendix/key-file-index.md](./appendix/key-file-index.md), [appendix/directory-map.md](./appendix/directory-map.md), [appendix/root-file-map.md](./appendix/root-file-map.md), [appendix/conditional-features-map.md](./appendix/conditional-features-map.md)

다음 경로는 독자용 책 본문 범위에서 제외한다.

- `superpowers/**`
  내부 집필 스펙과 실행 계획 보관용이다. 본문 독서 경로나 출판용 검수 집합에는 포함하지 않는다.

이 문서 세트는 `docs/`만으로 읽히도록 구성한다. 본문에 나오는 `src/` 기준 경로는 원 upstream 공개 사본의 provenance label이며, 독자가 별도 source tree를 열어야 한다는 뜻은 아니다.

## 가장 빠른 시작 경로

1. 이 포털 [README.md](./README.md)
2. [00-how-to-read-this-book.md](./00-how-to-read-this-book.md)
3. [appendix/source-analysis-method.md](./appendix/source-analysis-method.md)
4. [appendix/references.md](./appendix/references.md)
5. [foundations/01-why-harness-engineering-matters.md](./foundations/01-why-harness-engineering-matters.md)
6. [01-project-overview.md](./01-project-overview.md)

이 여섯 문서를 먼저 읽으면 이 책의 독서 규칙, 근거 체계, 일반 원칙, 사례 입구가 한 번에 고정된다.

## 이 책의 독서 모델

이 책에는 세 개의 읽기 층이 동시에 존재한다.

1. 원칙 spine
   Part I-VI 문서들이다. 하네스 설계의 일반 언어를 먼저 세운다.
2. 사례 spine
   `01`~`17` 장이다. Claude Code 공개 사본에서 그 언어가 실제로 어떻게 드러나는지 보여준다.
3. workbook와 참조 apparatus
   용어집, file index, directory map, references appendix다. 책을 정독할 때도 쓰지만, 부분 독해와 재검증 때 특히 유용하다.

처음 읽는 독자라면 원칙 spine을 먼저 가볍게 통과한 뒤, 사례 spine으로 내려와 구체 코드를 보는 편이 좋다. 이미 코드를 읽고 있는 독자라면 사례 spine에서 출발해 원칙 spine으로 되돌아가도 된다.

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
- 원칙 spine에서 세운 개념을 Claude Code 공개 사본의 실제 구조에 다시 연결한다.

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
  Anthropic engineering 글, Platform 문서, 핵심 연구 논문의 canonical source registry다.
- [appendix/glossary.md](./appendix/glossary.md)
  핵심 용어의 정의, 차이, 대표 근거 라벨을 모아 둔다.
- [appendix/key-file-index.md](./appendix/key-file-index.md)
  benchmark question 중심으로 어떤 발췌와 provenance label을 다시 볼지 정리할 때 쓴다.

## 근거 체계

이 책은 하나의 출처만으로 쓰이지 않는다. 모든 핵심 주장은 가능하면 아래 세 층을 결합한다.

1. 제품 사실
   공개 사본 source tree에서 직접 확인 가능한 구조, 타입, 분기, 상태 전이, handoff artifact
2. 공개 설계 원칙
   Anthropic의 engineering 글과 공식 Platform 문서
3. 연구 확장 근거
   하네스를 비교 가능한 실행 구조로 읽게 해 주는 연구 문헌

이 규칙을 어떻게 적용하는지는 [00-how-to-read-this-book.md](./00-how-to-read-this-book.md)와 [appendix/source-analysis-method.md](./appendix/source-analysis-method.md)에, 실제 출처 목록은 [appendix/references.md](./appendix/references.md)에 정리한다.

## 현재 판본의 한계

- 이 책은 git 이력 없는 공개 사본을 기준으로 한다. 따라서 커밋 의도나 비공개 운영 지표는 직접 근거가 아니다.
- 저장소 바깥의 백엔드 구현, 내부 정책 시스템, 전체 CI/CD 파이프라인은 본문 중심 근거가 아니다.
- 같은 source file이 원칙 spine과 사례 spine에 모두 등장할 수 있다. 이것은 중복이 아니라 다른 질문으로 다시 읽기 위한 의도적 배치다.
- 외부 문서는 시간이 지나며 제목이나 세부 내용이 바뀔 수 있다. 이 판본의 외부 출처 확인 기준일은 2026-04-02다.

## 이 책이 하지 않는 일

- 스냅샷에 없는 내부 구현을 추정해 채워 넣지 않는다.
- Claude Code를 정답 아키텍처로 미화하지 않는다.
- file inventory만 나열하는 디렉터리 설명문으로 머물지 않는다.
- 구현 변경 제안이나 product roadmap을 책의 중심 목적으로 삼지 않는다.

## 갱신 규칙

- 독자용 책 구조나 reading path가 바뀌면 이 포털을 함께 갱신한다.
- 새 외부 자료가 본문에 들어오면 [appendix/references.md](./appendix/references.md)를 함께 갱신한다.
- `superpowers/**` 아래의 내부 산출물은 이 포털의 독자용 인덱스에 포함하지 않는다.
