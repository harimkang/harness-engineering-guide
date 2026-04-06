# 03. References

> Why this chapter exists: 이 책 전체에서 반복해서 참조하는 공식 문서,
> 엔지니어링 글, 사양, 프레임워크 문서, 연구 자료를 한곳에 모은 canonical
> source registry다.
> Reader level: beginner / advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: volatile
> Reader path tags: `first-pass` / `builder` / `reviewer` / `source-first` / `volatile re-check`
> Source tier focus: Tier 1-5 외부 registry와 Tier 6 observed artifact entry를 함께 다룬다.
> Reference scaffolds: proposal `S*` IDs, freshness watchlist, evidence-pack practice, chapter re-entry

## Core claim

이 책의 reader-facing 본문은 local code 관찰과 외부 공식 자료를 결합해
쓰인다. 이 부록은 그때 우선 확인해야 하는 canonical source registry를 제공한다.

## What this chapter is not claiming

- 여기 나열된 모든 source가 같은 무게를 가진다는 주장
- provisional source가 공식 문서를 대체할 수 있다는 주장
- 이 부록만으로 각 장의 사실 검증이 끝난다는 주장

## How to use this registry

- substantive chapter edit 전에는 먼저 여기서 관련 source ID와 공식 URL을 찾는다.
- volatile topic은 chapter edit 시점에 URL을 다시 열어 확인한다.
- preprint는 반드시 provisional framing으로만 사용한다.
- local code 사실은 이 부록의 외부 자료로 대체하지 않는다.
- proposal의 canonical source ID는 `S*` 계열만 사용한다.
- supplemental research와 observed artifact는 `P*`, `R*` 같은 별도 계열 ID를
  사용한다.

## Reader-path re-entry

- `first-pass`: 이 장의 역할과 Tier 1, Tier 2, `Freshness watchlist`만 먼저 읽어도 충분하다.
- `builder`: 관련 Part guide에서 제시한 `S*` cluster를 따라 세부 섹션으로 들어간다.
- `reviewer`: chapter의 `Sources / evidence notes`에 적힌 `S*`, `P*`, `R*` ID를 이 장에서 다시 확인한다.
- `source-first`: provenance나 watchlist 기준으로 먼저 source를 확인한 뒤 본문으로 되돌아간다.
- `volatile re-check`: chapter edit 직전에 watchlist source와 release notes window를 다시 열고 evidence-pack 메모를 남긴다.

## Source tier quick guide

| Tier | 범주 | 기본 status | 이 책에서의 역할 |
| --- | --- | --- | --- |
| Tier 1 | Primary / official docs | primary | 제품 surface, SDK behavior, 최신 guidance 확인 |
| Tier 2 | Official engineering posts | primary | 설계 원칙, 운영 패턴, trade-off framing |
| Tier 3 | Protocol specifications / standards | primary | schema, vocabulary, governance translation |
| Tier 4 | Framework docs | supplemental | 구현 비교 프레임과 pattern 비교 |
| Tier 5 | Provisional research | provisional | 보조 가설과 emerging terminology |
| Tier 6 | Observed artifact snapshot | supplemental | 공개 사본 관찰 근거 |

chapter의 `Sources / evidence notes`에서는 가능하면 proposal source ID를
그대로 다시 쓴다. 예: `S22`, `S29`, `S30`.

## Freshness and claim discipline

- `stable`: taxonomy, glossary, long-lived conceptual distinction
- `medium`: observability/eval/governance 운영 일반론
- `volatile`: settings, release-note-heavy features, trace tooling, agent SDK details

source의 section 위치가 tier를 가리키고, bullet 아래의 `verified` 또는
`volatile` 메모는 freshness 경고를 가리킨다.

## Tier 1. Primary / official docs

이 섹션의 항목은 제품 사실, 공식 contract, vendor-stated guidance를 확인할 때
가장 먼저 다시 여는 source다.

### Anthropic and Claude Code docs

- `S10` [Claude Code settings](https://docs.anthropic.com/en/docs/claude-code/settings)
  - verified 2026-04-06
  - scope, precedence, `CLAUDE.md`, hooks, subagents, plugins, managed settings를
    확인할 때 우선 사용
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
  - CLI commands, flags, hooks/plugins/subagent entrypoints를 확인할 때 우선 사용
- `S15` [Claude Code release notes](https://docs.anthropic.com/en/release-notes/claude-code)
  - verified 2026-04-06
  - fast-moving feature, auth, MCP transport, config drift를 추적할 때 우선 사용

### OpenAI official docs

- `S21` [Agents SDK guide](https://developers.openai.com/api/docs/guides/agents-sdk)
  - verified 2026-04-06
  - additional context, tools, handoffs, streaming, full-trace support를 비교할 때 사용
- `S22` [Tracing](https://openai.github.io/openai-agents-python/tracing/)
  - verified 2026-04-06
  - built-in tracing, trace/span structure, sensitive-data controls, long-running
    worker flush behavior를 비교할 때 사용
- `S23` [Evaluation best practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices) and [Agent evals](https://developers.openai.com/api/docs/guides/agent-evals)
  - verified 2026-04-06
  - eval-driven development, task-specific datasets, workflow-level traces, trace
    grading, grader criteria를 비교할 때 사용
- `S24` [Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
  - verified 2026-04-06
  - repo-level instruction surface와 configuration family를 비교할 때 사용
- `S25` [Safety in building agents](https://developers.openai.com/api/docs/guides/agent-builder-safety/)
  - volatile
  - tool/data exposure와 safety surface를 비교할 때 사용

### Governance docs

- `S30` [Artificial Intelligence Risk Management Framework: Generative Artificial Intelligence Profile](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence)
  - verified 2026-04-06
  - cross-sectoral governance framing, trustworthiness, design/development/use/evaluation
    review language에 사용
- `S31` [AI RMF Playbook](https://airc.nist.gov/airmf-resources/playbook/)
  - verified 2026-04-06
  - governance review questions와 operational mapping에 사용

## Tier 2. Official engineering posts

이 섹션의 항목은 설계 pattern, workflow/evaluator framing, 운영 원칙을 보강할
때 우선 사용한다. 다만 제품 세부 contract는 같은 항목이 아니라 상단의
official docs 또는 spec으로 되돌아가 확인한다.

- `S1` [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
  - verified 2026-04-06
  - workflow vs agent, composable patterns, simplest viable system framing
- `S2` [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
  - verified 2026-04-06
  - orchestrator-worker, delegation, context partitioning
- `S3` [Writing effective tools for AI agents—using AI agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
  - verified 2026-04-06
  - tool naming, schemas, discoverability, ACI quality
- `S4` [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
  - verified 2026-04-06
  - context as finite resource, retrieval/compaction/memory framing, sub-agent
    clean-context patterns
- `S5` [Making Claude Code more secure and autonomous with sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)
  - verified 2026-04-06
  - sandboxing, permission fatigue, boundary engineering
- `S6` [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
  - verified 2026-04-06
  - clean state, handoff artifacts, progress notes, long-running session reviewability
- `S7` [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
  - verified 2026-04-06
  - task, trial, transcript, grader, stable eval environment, production monitoring
    and transcript review
- `S8` [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
  - verified 2026-04-06
  - planner/generator/evaluator split, skeptical evaluator tuning, contract-based QA,
    cost/latency trade-offs
- `S9` [Claude Code auto mode: a safer way to skip permissions](https://www.anthropic.com/engineering/claude-code-auto-mode)
  - verified 2026-04-06
  - auto mode, approval burden, permission-surface redistribution, autonomy/safety trade-off
- `S32` [Quantifying infrastructure noise in agentic coding evals](https://www.anthropic.com/engineering/infrastructure-noise)
  - volatility-sensitive
  - infra noise, flakiness, benchmark realism
- `S33` [Prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
  - volatility-sensitive
  - caching, cost, latency, context economics

## Tier 3. Protocol specifications and standards

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
  - GenAI events/metrics/model spans/agent spans vocabulary와 status-sensitive
    schema guidance

## Tier 4. Framework docs

- `S26` [LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
  - verified 2026-04-06
  - checkpointing, resumability, saved state comparisons
- `S27` [LangGraph interrupts](https://docs.langchain.com/oss/python/langgraph/interrupts)
  - verified 2026-04-06
  - pause/resume, approval wait states, recovery comparisons
- `S28` [LangGraph observability](https://docs.langchain.com/oss/python/langgraph/observability) and [Prevent logging of sensitive data in traces](https://docs.langchain.com/langsmith/mask-inputs-outputs)
  - verified 2026-04-06
  - trace privacy, masking, observability operations

## Tier 5. Provisional research

- `P1` [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723)
  - provisional
  - explicit contract, durable artifact, lightweight adapter framing
  - canonical `S*` source verification을 대신하지 못한다
- `P2` [Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/abs/2603.28052)
  - provisional
  - harness 자체를 optimization 대상으로 읽는 비교 프레임
  - canonical `S*` source verification을 대신하지 못한다

## Tier 6. Observed code / public artifact snapshot

- `R1` [harimkang/harness-engineering-guide](https://github.com/harimkang/harness-engineering-guide/tree/main)
  - this book’s reader-facing corpus
  - chapter-level observed artifact citations should additionally carry verification
    date and acquisition path

## Evidence-pack practice

주요 개정이나 volatile chapter update를 끝낼 때는 가능하면 아래 bundle을 함께
남긴다.

- verified date
- checked docs list
- checked release notes window
- observed artifact snapshot identifiers
- changed chapters

이 bundle은 별도 파일이어도 되지만, 최소한 chapter-level `Sources / evidence
notes`에는 어떤 source를 다시 열었는지와 어떤 drift risk를 확인했는지 남기는
편이 좋다. Part 7의 reproducibility/evidence-pack 언어는
[../07-evaluation-and-synthesis/09-eval-hygiene-dataset-versioning-and-contamination.md](../07-evaluation-and-synthesis/09-eval-hygiene-dataset-versioning-and-contamination.md)에서
minimum reproducibility bundle로 다시 정리한다.

## Freshness watchlist

아래 source는 chapter edit 직전에 다시 여는 것을 기본 규칙으로 둔다.

- Claude Code settings / CLI reference / skills / MCP / release notes
- Claude Agent SDK
- OpenAI `AGENTS.md`, Agents SDK, tracing, eval docs
- MCP specification release page and client-feature docs
- LangGraph persistence / interrupts / observability
- OpenTelemetry GenAI semantic conventions
- NIST AI RMF GenAI Profile / Playbook

reader-facing corpus의 상대 링크, 번호-제목 일치, legacy label residue는
`npm run check:docs`로 점검한다.

## Usage rules

- local code 사실은 외부 자료로 대체하지 않는다.
- 외부 자료는 `원칙:` 또는 비교 프레임으로 사용한다.
- preprint는 provisional로만 사용한다.
- proposal source verification이 필요한 chapter edit에는 `S*` source를 하나 이상
  다시 확인한다.
- 새 source가 반복적으로 들어오면 이 부록에 먼저 등록한다.
