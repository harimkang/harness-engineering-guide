# Part 5 Guide: Execution, Continuity, And Integrations

이 Part는 장기 실행형 harness가 세션 continuity와 외부 integration을 어떻게 한 시스템 안에 묶는지 다룹니다. 먼저 resumability, task orchestration, human oversight를 읽고, 이어서 observability와 cost/economics를 독립 축으로 끌어올립니다. 그 다음 Claude Code의 services, MCP/skill/plugin coordination, task artifact, persistence layer를 사례로 봅니다. 이번 개정에서는 무엇이 보존되고 무엇이 사라지는지의 preservation matrix, retry/backoff/cancel semantics, approval fatigue, service dependency volatility를 Part 전체의 공통 질문으로 더 선명하게 올립니다.

## 이 Part의 핵심 질문

- transcript와 owner는 어떻게 분리되고 다시 결합되는가
- transcript, checkpoint, worktree, memory, config는 각각 무엇을 보존하고 무엇을 보존하지 않는가
- 장기 실행은 왜 task artifact로 승격되어야 하는가
- retry, backoff, cancel, orphan cleanup은 어떤 artifact와 policy로 남아야 하는가
- human oversight는 어디서 friction이고 어디서 load-bearing한가
- transcript, trace, checkpoint, evidence pack은 무엇이 다른가
- cost, latency, prompt caching, infrastructure noise는 언제 설계 축이 되는가
- service layer와 integration seam은 runtime substrate에서 어떤 역할을 하는가
- external service volatility와 fail-open/fail-closed choice는 continuity를 어떻게 바꾸는가

## 먼저 읽을 원칙 장

1. [./01-state-resumability-and-session-ownership.md](./01-state-resumability-and-session-ownership.md)
2. [./02-task-orchestration-and-long-running-execution.md](./02-task-orchestration-and-long-running-execution.md)
3. [./03-human-oversight-trust-and-approval.md](./03-human-oversight-trust-and-approval.md)
4. [./08-observability-traces-and-run-artifacts.md](./08-observability-traces-and-run-artifacts.md)
5. [./09-cost-latency-headroom-and-prompt-caching.md](./09-cost-latency-headroom-and-prompt-caching.md)

## 이어서 읽을 Claude Code 사례 장

1. [./04-claude-code-services-and-integrations.md](./04-claude-code-services-and-integrations.md)
2. [./05-claude-code-agent-skill-plugin-mcp-and-coordination.md](./05-claude-code-agent-skill-plugin-mcp-and-coordination.md)
3. [./06-claude-code-task-model-and-background-execution.md](./06-claude-code-task-model-and-background-execution.md)
4. [./07-claude-code-persistence-config-and-migrations.md](./07-claude-code-persistence-config-and-migrations.md)

## 필요할 때 함께 볼 곳

- [../07-evaluation-and-synthesis/04-production-traces-feedback-loops-and-optimization.md](../07-evaluation-and-synthesis/04-production-traces-feedback-loops-and-optimization.md)
- [../07-evaluation-and-synthesis/09-eval-hygiene-dataset-versioning-and-contamination.md](../07-evaluation-and-synthesis/09-eval-hygiene-dataset-versioning-and-contamination.md)
- [../08-reference/02-key-file-index.md](../08-reference/02-key-file-index.md)
