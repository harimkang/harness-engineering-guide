# 03. References

> Why this chapter exists: 이 책 전체에서 반복해서 참조하는 공식 문서, 엔지니어링 글, 사양, 프레임워크 문서, 연구 자료를 한곳에 모은 canonical source registry다.
> Reader level: beginner / advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: volatile

## Core claim

이 책의 reader-facing 본문은 local code 관찰과 외부 공식 자료를 결합해 쓰인다. 이 부록은 그때 우선 확인해야 하는 canonical source registry를 제공한다.

## What this chapter is not claiming

- 여기 나열된 모든 source가 같은 무게를 가진다는 주장
- provisional source가 공식 문서를 대체할 수 있다는 주장
- 이 부록만으로 각 장의 사실 검증이 끝난다는 주장

## How to use this registry

- substantive chapter edit 전에는 먼저 여기서 관련 source ID와 공식 URL을 찾는다.
- volatile topic은 chapter edit 시점에 URL을 다시 열어 확인한다.
- preprint는 반드시 provisional framing으로만 사용한다.
- local code 사실은 이 부록의 외부 자료로 대체하지 않는다.

## Primary / official docs

### Anthropic and Claude Code docs

- `S10` [Claude Code settings](https://docs.anthropic.com/en/docs/claude-code/settings)
  - verified 2026-04-06
  - scope, precedence, `CLAUDE.md`, hooks, subagents, plugin, managed settings를 확인할 때 우선 사용
- `S11` [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills)
  - verified 2026-04-06
  - personal/project/plugin/managed skill scope와 precedence를 확인할 때 우선 사용
- `S12` [Claude Code MCP](https://docs.anthropic.com/en/docs/claude-code/mcp)
  - volatile
  - Claude Code의 MCP integration surface를 확인할 때 우선 사용
- `S13` [Claude Agent SDK overview](https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-overview)
  - volatile
  - SDK surface와 library-level agent control을 읽을 때 우선 사용
- `S14` [Claude Code CLI reference](https://docs.anthropic.com/en/docs/claude-code/cli-reference)
  - verified 2026-04-06
  - CLI commands, flags, system prompt flags, hooks/plugins/subagent entrypoints를 확인할 때 우선 사용
- `S15` [Claude Code release notes](https://docs.anthropic.com/en/release-notes/claude-code)
  - verified 2026-04-06
  - fast-moving feature, auth, MCP transport, config drift를 추적할 때 우선 사용

### OpenAI official docs

- `S21` [Agents SDK guide](https://developers.openai.com/api/docs/guides/agents-sdk)
  - verified 2026-04-06
  - agent SDK surface, handoff, tracing, specialized agents를 비교할 때 사용
- `S22` [Tracing](https://openai.github.io/openai-agents-python/tracing/)
  - verified 2026-04-06
  - trace model, span/event thinking, observability 비교에 사용
- `S23` [Evaluation best practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices) and [Agent evals](https://developers.openai.com/api/docs/guides/agent-evals)
  - verified 2026-04-06
  - dataset hygiene, eval artifact, trace-aware grading을 비교할 때 사용
- `S24` [Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
  - verified 2026-04-06
  - repo-level instruction surface, hooks, MCP, skills, subagents, managed configuration 비교에 사용
- `S25` [Safety in building agents](https://developers.openai.com/api/docs/guides/agent-builder-safety/)
  - volatile
  - tool/data exposure와 safety surface를 비교할 때 사용

### Governance docs

- `S30` [Artificial Intelligence Risk Management Framework: Generative Artificial Intelligence Profile](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence)
  - verified 2026-04-06
  - governance, trustworthiness, architecture review translation layer에 사용
- `S31` [AI RMF Playbook](https://airc.nist.gov/airmf-resources/playbook/)
  - verified 2026-04-06
  - governance review questions와 operational mapping에 사용

## Official engineering posts

- `S1` [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
  - verified 2026-04-06
  - workflow vs agent, composable patterns, ACI framing
- `S2` [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
  - verified 2026-04-06
  - orchestrator-worker, delegation, context partitioning
- `S3` [Writing effective tools for AI agents—using AI agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
  - verified 2026-04-06
  - tool naming, schemas, discoverability, ACI quality
- `S4` [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
  - verified 2026-04-06
  - context as resource, retrieval, compaction, memory framing
- `S5` [Making Claude Code more secure and autonomous with sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)
  - verified 2026-04-06
  - sandboxing, permission fatigue, boundary engineering
- `S6` [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
  - verified 2026-04-06
  - clean state, handoff artifacts, long-running session patterns
- `S7` [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
  - verified 2026-04-06
  - task, trial, transcript, grader, evaluator thinking
- `S8` [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
  - verified 2026-04-06
  - planner/generator/evaluator split, contract-based QA, long-running app harnesses
- `S32` [Quantifying infrastructure noise in agentic coding evals](https://www.anthropic.com/engineering/infrastructure-noise)
  - volatility-sensitive
  - infra noise, flakiness, benchmark realism
- `S33` [Prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
  - volatility-sensitive
  - caching, cost, latency, context economics

## Protocol specifications

- `S16` [Model Context Protocol Specification (Version 2025-11-25)](https://modelcontextprotocol.io/specification/2025-11-25)
  - verified 2026-04-06
  - latest version marker, client features, authorization baseline
- `S17` [Understanding MCP clients](https://modelcontextprotocol.io/docs/learn/client-concepts)
  - verified 2026-04-06
  - roots, sampling, elicitation, authorization-adjacent client behavior
- `S18` [Sampling](https://modelcontextprotocol.io/specification/draft/client/sampling)
  - volatile
  - client-mediated model calls and human-in-the-loop control
- `S19` [Elicitation](https://modelcontextprotocol.io/specification/draft/client/elicitation)
  - volatile
  - user-data request semantics and interaction model
- `S20` [Authorization](https://modelcontextprotocol.io/specification/draft/basic/authorization)
  - volatile
  - remote MCP auth and trust surface
- `S29` [Semantic conventions for generative AI systems](https://opentelemetry.io/docs/specs/semconv/gen-ai/)
  - verified 2026-04-06
  - trace schema vocabulary and observability field design

## Framework docs

- `S26` [LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
  - verified 2026-04-06
  - checkpointing, resumability, saved state comparisons
- `S27` [LangGraph interrupts](https://docs.langchain.com/oss/python/langgraph/interrupts)
  - verified 2026-04-06
  - pause/resume, approval wait states, recovery comparisons
- `S28` [LangGraph observability](https://docs.langchain.com/oss/python/langgraph/observability) and [Prevent logging of sensitive data in traces](https://docs.langchain.com/langsmith/mask-inputs-outputs)
  - verified 2026-04-06
  - trace privacy, masking, observability operations

## Research papers / preprints

- `S11` [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723)
  - provisional
  - explicit contract, durable artifact, lightweight adapter framing
- `S12` [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052)
  - provisional
  - harness 자체를 optimization 대상으로 읽는 비교 프레임

## Observed code / public artifact snapshot

- `R1` [harimkang/harness-engineering-guide](https://github.com/harimkang/harness-engineering-guide/tree/main)
  - this book’s reader-facing corpus
  - chapter-level observed artifact citations should additionally carry verification date and acquisition path

## Freshness watchlist

아래 source는 chapter edit 직전에 다시 여는 것을 기본 규칙으로 둔다.

- Claude Code settings / CLI reference / skills / MCP / release notes
- OpenAI `AGENTS.md`, Agents SDK, tracing, eval docs
- MCP specification release page and client-feature docs
- LangGraph persistence / interrupts / observability
- OpenTelemetry GenAI semantic conventions

## Usage rules

- local code 사실은 외부 자료로 대체하지 않는다.
- 외부 자료는 `원칙:` 또는 비교 프레임으로 사용한다.
- preprint는 provisional로만 사용한다.
- 새 source가 반복적으로 들어오면 이 부록에 먼저 등록한다.
