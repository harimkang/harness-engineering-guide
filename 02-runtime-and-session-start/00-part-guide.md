# Part 2 Guide: Runtime And Session Start

## 3문장 요약

이 Part는 장기 실행형 agent harness가 어떤 runtime family를 가지며, 세션이 어떤 startup contract 아래에서 열리는지 설명한다. 핵심은 startup을 단순 온보딩이 아니라 entrypoint, trust boundary, initialization sequencing이 함께 굳는 운영 계약으로 읽는 데 있다. 처음 읽는 독자는 원칙 장 둘로 개념을 잡은 뒤 Claude Code 사례 장에서 그 절단면을 따라가면 된다.

## 한 장짜리 멘탈 모델

이 Part를 읽을 때는 다섯 질문만 붙들면 된다.

1. 하나의 제품이 왜 여러 runtime family를 가지는가
2. entrypoint와 assembly hub는 어디서 갈리는가
3. startup contract에는 어떤 입력면이 들어오는가
4. trust boundary와 permission mode는 어떻게 다른가
5. 어떤 경로가 fast-path이고 어떤 경로가 full runtime assembly를 거치는가

## 왜 이 Part가 필요한가

runtime 설명에서 가장 흔한 실패는 실행 모드, startup, trust, approval, initialization을 한 덩어리로 부르는 것이다. 그러면 사례 장을 읽을 때도 단순 file tour처럼 보이고, 실제로는 어떤 경로가 세션 계약을 고정하는지 드러나지 않는다. 이 Part는 그 혼선을 먼저 정리한 뒤, Claude Code 사례를 운영 구조로 다시 읽게 만드는 입구다.

> Why this chapter exists: runtime family, startup contract, trust boundary를 먼저 고정해 이후 사례 장의 진입면을 정렬한다.
> Reader path tags: `first-pass` / `builder` / `volatile re-check`
> Last verified: 2026-04-06
> Freshness class: volatile
> Source tier focus: Tier 2 framing, Tier 1 product docs, Tier 6 Claude Code case-study cuts
> Volatile topics: settings precedence, hooks, CLI flags, runtime modes, remote/bridge entry surface

## Reader-path suggestions

- `first-pass`: [./01-runtime-families-entrypoints-and-assembly-hubs.md](./01-runtime-families-entrypoints-and-assembly-hubs.md)와 [./02-startup-contract-trust-boundary-and-initialization.md](./02-startup-contract-trust-boundary-and-initialization.md)를 먼저 읽고, 사례 장에서는 [./04-claude-code-architecture-map.md](./04-claude-code-architecture-map.md)와 [./06-claude-code-session-startup-trust-and-initialization.md](./06-claude-code-session-startup-trust-and-initialization.md)를 우선 본다.
- `builder`: runtime modes, startup trust, Part 4 instruction surface 장을 묶어 startup contract를 비교한다.
- `volatile re-check`: runtime mode나 startup policy 설명을 고칠 때는 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S10`, `S13`, `S14`, `S15`, `S24`를 먼저 다시 연다.

## 이 Part의 핵심 질문

- 하나의 agent product가 왜 여러 runtime family를 가져야 하는가
- entrypoint와 assembly hub를 왜 구분해야 하는가
- startup은 단순 온보딩이 아니라 어떤 contract를 고정하는가
- trust boundary와 permission mode는 어떻게 다른가
- settings, hooks, managed policy, repo instructions 같은 입력면은 어느 시점에 startup contract로 굳는가

## 이 Part를 읽고 나면 기대할 수 있는 산출물

- 어떤 경로가 fast-path이고 어떤 경로가 full runtime assembly를 거치는지 설명할 수 있다
- startup contract를 trust boundary, policy input, post-trust initialization으로 나눠 읽을 수 있다
- Claude Code 사례에서 entrypoint, assembly hub, operator-facing launch seam의 경계를 다시 그릴 수 있다

## 먼저 읽을 원칙 장

1. [./01-runtime-families-entrypoints-and-assembly-hubs.md](./01-runtime-families-entrypoints-and-assembly-hubs.md)
2. [./02-startup-contract-trust-boundary-and-initialization.md](./02-startup-contract-trust-boundary-and-initialization.md)

## 이어서 읽을 Claude Code 사례 장

1. [./03-claude-code-project-overview.md](./03-claude-code-project-overview.md)
2. [./04-claude-code-architecture-map.md](./04-claude-code-architecture-map.md)
3. [./05-claude-code-runtime-modes-and-entrypoints.md](./05-claude-code-runtime-modes-and-entrypoints.md)
4. [./06-claude-code-session-startup-trust-and-initialization.md](./06-claude-code-session-startup-trust-and-initialization.md)

## 필요할 때 함께 볼 곳

- [../01-foundations/02-workflows-agents-runtimes-and-harnesses.md](../01-foundations/02-workflows-agents-runtimes-and-harnesses.md)
- [../01-foundations/03-quality-attributes-of-agent-harnesses.md](../01-foundations/03-quality-attributes-of-agent-harnesses.md)
- [../08-reference/02-key-file-index.md](../08-reference/02-key-file-index.md)
- [../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)

## Sources / evidence notes

- 이 Part의 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S6`, `S8`, `S10`, `S13`, `S14`, `S15`, `S24`를 따른다.
- source tier는 Tier 2 framing과 Tier 1 product contract를 우선하고, local case-study fact는 Tier 6 observed artifact로 닫는다.
