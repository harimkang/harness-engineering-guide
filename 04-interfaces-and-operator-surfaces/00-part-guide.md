# Part 4 Guide: Interfaces And Operator Surfaces

이 Part는 모델과 사람이 시스템을 만나는 표면을 함께 다룹니다. 먼저 tool contract, permission shaping, extension ingress를 읽고, 이어서 instruction surface와 operator-facing transcript/UI를 분리해서 설명합니다. 그 다음 Claude Code의 command system, tool system, state/UI shell을 사례로 따라갑니다. 이번 개정에서는 MCP를 단순 tool bridge가 아니라 client-server coordination protocol로 읽고, capability exposure를 authorization, privacy, observability와 분리해서 보는 관점을 더 앞단에 둡니다.

## 이 Part의 핵심 질문

- tool은 함수가 아니라 어떤 계약 표면인가
- capability exposure와 call-time permission은 왜 분리돼야 하는가
- capability exposure, authorization, privacy, masking은 왜 같은 문제가 아닌가
- command, skill, plugin, MCP는 어떤 ingress grammar를 이루는가
- roots, sampling, elicitation, authorization 같은 MCP client semantics는 왜 "도구 호출 이후"까지 설명해야 하는가
- settings, hooks, `CLAUDE.md`, subagents는 어떤 instruction stack을 이루는가
- operator surface는 단순 UI가 아니라 어떤 control layer인가
- transcript, trace, run artifact adjacency는 operator control과 benchmarkability를 어떻게 바꾸는가

## 먼저 읽을 원칙 장

1. [./01-tool-contracts-and-the-agent-computer-interface.md](./01-tool-contracts-and-the-agent-computer-interface.md)
2. [./02-tool-shaping-permissions-and-capability-exposure.md](./02-tool-shaping-permissions-and-capability-exposure.md)
3. [./03-commands-skills-plugins-and-mcp.md](./03-commands-skills-plugins-and-mcp.md)
4. [./04-benchmarking-tool-surfaces.md](./04-benchmarking-tool-surfaces.md)
5. [./05-ui-transcripts-and-operator-control.md](./05-ui-transcripts-and-operator-control.md)
6. [./09-instruction-surfaces-settings-hooks-claude-md-subagents.md](./09-instruction-surfaces-settings-hooks-claude-md-subagents.md)

## 이어서 읽을 Claude Code 사례 장

1. [./06-claude-code-command-system.md](./06-claude-code-command-system.md)
2. [./07-claude-code-tool-system-and-permissions.md](./07-claude-code-tool-system-and-permissions.md)
3. [./08-claude-code-state-ui-and-terminal-interaction.md](./08-claude-code-state-ui-and-terminal-interaction.md)

## 필요할 때 함께 볼 곳

- [../05-execution-continuity-and-integrations/08-observability-traces-and-run-artifacts.md](../05-execution-continuity-and-integrations/08-observability-traces-and-run-artifacts.md)
- [../06-boundaries-deployment-and-safety/00-part-guide.md](../06-boundaries-deployment-and-safety/00-part-guide.md)
- [../02-runtime-and-session-start/06-claude-code-session-startup-trust-and-initialization.md](../02-runtime-and-session-start/06-claude-code-session-startup-trust-and-initialization.md)
- [../08-reference/01-glossary.md](../08-reference/01-glossary.md)
