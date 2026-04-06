# Part 4 Guide: Interfaces And Operator Surfaces

이 Part는 모델과 사람이 시스템을 만나는 표면을 함께 다룹니다. 먼저 tool contract, permission shaping, extension ingress, operator-facing transcript/UI를 일반론으로 읽고, 그 다음 Claude Code의 command system, tool system, state/UI shell을 사례로 따라갑니다.

## 이 Part의 핵심 질문

- tool은 함수가 아니라 어떤 계약 표면인가
- capability exposure와 call-time permission은 왜 분리돼야 하는가
- command, skill, plugin, MCP는 어떤 ingress grammar를 이루는가
- operator surface는 단순 UI가 아니라 어떤 control layer인가

## 먼저 읽을 원칙 장

1. [./01-tool-contracts-and-the-agent-computer-interface.md](./01-tool-contracts-and-the-agent-computer-interface.md)
2. [./02-tool-shaping-permissions-and-capability-exposure.md](./02-tool-shaping-permissions-and-capability-exposure.md)
3. [./03-commands-skills-plugins-and-mcp.md](./03-commands-skills-plugins-and-mcp.md)
4. [./04-benchmarking-tool-surfaces.md](./04-benchmarking-tool-surfaces.md)
5. [./05-ui-transcripts-and-operator-control.md](./05-ui-transcripts-and-operator-control.md)

## 이어서 읽을 Claude Code 사례 장

1. [./06-claude-code-command-system.md](./06-claude-code-command-system.md)
2. [./07-claude-code-tool-system-and-permissions.md](./07-claude-code-tool-system-and-permissions.md)
3. [./08-claude-code-state-ui-and-terminal-interaction.md](./08-claude-code-state-ui-and-terminal-interaction.md)

## 필요할 때 함께 볼 곳

- [../06-boundaries-deployment-and-safety/00-part-guide.md](../06-boundaries-deployment-and-safety/00-part-guide.md)
- [../08-reference/01-glossary.md](../08-reference/01-glossary.md)
