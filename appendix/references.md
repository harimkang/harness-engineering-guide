# Appendix. References

## 장 요약

이 부록은 reader-facing 문서 집합에서 반복해서 인용하는 핵심 외부 자료를 한곳에 모은 canonical source registry다. 장마다 모든 출처를 다시 길게 반복하지 않기 위해, 여기서는 "이 책 전체를 떠받치는 공통 자료"만 추린다. 세부 장이 특정 자료를 직접 인용할 때는 그 장 안에서도 날짜와 링크를 다시 보여 줄 수 있지만, 기준 목록은 이 부록을 우선한다.

확인 기준:

- Anthropic engineering 및 Platform 문서 확인 시점: 2026-04-02
- arXiv 문헌 확인 시점: 2026-04-02

## Anthropic Engineering

### Building effective agents

- 링크: [anthropic.com/engineering/building-effective-agents](https://www.anthropic.com/engineering/building-effective-agents)
- 발행일: 2024-12-19
- 이 책에서 맡는 역할: workflow와 agent의 구분, 단순하고 조합 가능한 agent pattern, agent-computer interface의 중요성

### How we built our multi-agent research system

- 링크: [anthropic.com/engineering/multi-agent-research-system](https://www.anthropic.com/engineering/multi-agent-research-system)
- 발행일: 2025-06-13
- 이 책에서 맡는 역할: orchestrator-worker 구조, 작업 단위 분해, shared tooling과 orchestration substrate

### Writing effective tools for agents - with agents

- 링크: [anthropic.com/engineering/writing-tools-for-agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
- 발행일: 2025-09-11
- 이 책에서 맡는 역할: tool naming, description, schema, token efficiency, ACI 품질

### Effective context engineering for AI agents

- 링크: [anthropic.com/engineering/effective-context-engineering-for-ai-agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- 발행일: 2025-09-29
- 이 책에서 맡는 역할: context를 finite operational resource로 읽는 원칙, retrieval과 compaction의 위치

### Beyond permission prompts: making Claude Code more secure and autonomous

- 링크: [anthropic.com/engineering/claude-code-sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)
- 발행일: 2025-10-20
- 이 책에서 맡는 역할: filesystem isolation, network isolation, approval fatigue, boundary engineering

### Effective harnesses for long-running agents

- 링크: [anthropic.com/engineering/effective-harnesses-for-long-running-agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- 발행일: 2025-11-26
- 이 책에서 맡는 역할: clean state, structured artifact, initializer/coding agent 분리, long-running session handoff

### Demystifying evals for AI agents

- 링크: [anthropic.com/engineering/demystifying-evals-for-ai-agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- 발행일: 2026-01-09
- 이 책에서 맡는 역할: task, trial, transcript, grader, outcome language

### Harness design for long-running application development

- 링크: [anthropic.com/engineering/harness-design-long-running-apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- 발행일: 2026-03-24
- 이 책에서 맡는 역할: long-running application harness, handoff artifact, feedback loop, execution scaffold

## Anthropic Platform Docs

### Agent SDK overview

- 링크: [platform.claude.com/docs/en/agent-sdk/overview](https://platform.claude.com/docs/en/agent-sdk/overview)
- 확인 시점: 2026-04-02
- 이 책에서 맡는 역할: tools, sessions, permissions, MCP, context management를 library surface로 읽는 기준

## Research Literature

### Natural-Language Agent Harnesses

- 링크: [arXiv:2603.25723](https://arxiv.org/abs/2603.25723)
- 문서 성격: 프리프린트, under review
- 확인 시점: 2026-04-02
- 이 책에서 맡는 역할: explicit contract, durable artifact, lightweight adapter라는 비교 프레임

### Meta-Harness: End-to-End Optimization of Model Harnesses

- 링크: [arXiv:2603.28052](https://arxiv.org/abs/2603.28052)
- 문서 성격: 프리프린트
- 최초 제출: 2026-03-30
- 이 책에서 맡는 역할: harness 자체를 최적화 대상 코드로 읽는 관점

## 사용 규칙

- local code 사실을 말할 때는 이 부록의 외부 자료를 직접 증거처럼 쓰지 않는다.
- 외부 자료는 `원칙:` 또는 비교 프레임으로 사용하고, local code는 `관찰:`로 별도 고정한다.
- 새 외부 자료가 본문에 반복적으로 들어오면 이 부록에 먼저 등록한 뒤 각 장에 반영한다.
