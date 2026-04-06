# Part 2 Guide: Runtime And Session Start

이 Part는 long-running agent harness가 어떤 runtime family를 가지며, 세션이 어떤 startup contract와 trust boundary 아래에서 열리는지를 다룹니다. 먼저 일반론으로 runtime 분기와 session start를 읽고, 바로 이어서 Claude Code가 그 문제를 실제 product shell 안에서 어떻게 구현하는지 확인합니다.

## 이 Part의 핵심 질문

- 하나의 agent product가 왜 여러 runtime family를 가져야 하는가
- entrypoint와 assembly hub를 왜 구분해야 하는가
- startup은 단순 온보딩이 아니라 어떤 contract를 고정하는가
- trust boundary와 permission mode는 어떻게 다른가

## 먼저 읽을 원칙 장

1. [../01-foundations/02-workflows-agents-runtimes-and-harnesses.md](../01-foundations/02-workflows-agents-runtimes-and-harnesses.md)
2. [../01-foundations/03-quality-attributes-of-agent-harnesses.md](../01-foundations/03-quality-attributes-of-agent-harnesses.md)

## 이어서 읽을 Claude Code 사례 장

1. [./03-claude-code-project-overview.md](./03-claude-code-project-overview.md)
2. [./04-claude-code-architecture-map.md](./04-claude-code-architecture-map.md)
3. [./05-claude-code-runtime-modes-and-entrypoints.md](./05-claude-code-runtime-modes-and-entrypoints.md)
4. [./06-claude-code-session-startup-trust-and-initialization.md](./06-claude-code-session-startup-trust-and-initialization.md)

## 필요할 때 함께 볼 곳

- [../08-reference/02-key-file-index.md](../08-reference/02-key-file-index.md)
- [../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)
