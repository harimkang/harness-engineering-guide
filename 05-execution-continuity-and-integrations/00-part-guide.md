# Part 5 Guide: Execution, Continuity, And Integrations

이 Part는 장기 실행형 harness가 세션 continuity와 외부 integration을 어떻게 한 시스템 안에 묶는지 다룹니다. 먼저 resumability, task orchestration, human oversight를 일반론으로 읽고, 이어서 Claude Code의 services, MCP/skill/plugin coordination, task artifact, persistence layer를 사례로 봅니다.

## 이 Part의 핵심 질문

- transcript와 owner는 어떻게 분리되고 다시 결합되는가
- 장기 실행은 왜 task artifact로 승격되어야 하는가
- human oversight는 어디서 friction이고 어디서 load-bearing한가
- service layer와 integration seam은 runtime substrate에서 어떤 역할을 하는가

## 먼저 읽을 원칙 장

1. [./01-state-resumability-and-session-ownership.md](./01-state-resumability-and-session-ownership.md)
2. [./02-task-orchestration-and-long-running-execution.md](./02-task-orchestration-and-long-running-execution.md)
3. [./03-human-oversight-trust-and-approval.md](./03-human-oversight-trust-and-approval.md)

## 이어서 읽을 Claude Code 사례 장

1. [./04-claude-code-services-and-integrations.md](./04-claude-code-services-and-integrations.md)
2. [./05-claude-code-agent-skill-plugin-mcp-and-coordination.md](./05-claude-code-agent-skill-plugin-mcp-and-coordination.md)
3. [./06-claude-code-task-model-and-background-execution.md](./06-claude-code-task-model-and-background-execution.md)
4. [./07-claude-code-persistence-config-and-migrations.md](./07-claude-code-persistence-config-and-migrations.md)

## 필요할 때 함께 볼 곳

- [../07-evaluation-and-synthesis/04-production-traces-feedback-loops-and-optimization.md](../07-evaluation-and-synthesis/04-production-traces-feedback-loops-and-optimization.md)
- [../08-reference/02-key-file-index.md](../08-reference/02-key-file-index.md)
