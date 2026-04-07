# 02. startup contract, trust boundary, initialization

## 장 요약

startup은 단순히 화면을 띄우거나 welcome text를 보여 주는 과정이 아니다. 장기 실행형 agent harness에서 startup은 세션이 어떤 입력면과 정책 아래 열리는지, 어디까지를 trust boundary 바깥으로 볼지, 어떤 capability를 trust 이후에만 붙일지를 고정하는 계약이다. 이 장은 그 계약을 `startup contract`, `trust boundary`, `preflight initialization`, `post-trust initialization` 네 층으로 나눠 읽게 만든다.

이 구분이 없으면 settings precedence, hooks, memory files, CLI flags, startup UI, approval gating이 모두 "시작할 때 하는 일"이라는 모호한 말로 뭉개진다. 실제로는 어떤 입력은 trust 이전에 세션 조건을 바꾸고, 어떤 초기화는 trust 이후에만 허용되며, permission mode는 또 다른 실행 경계를 다룬다.

## 범위와 비범위

이 장이 다루는 것:

- startup contract를 왜 독립 설계면으로 적어야 하는가
- trust boundary와 permission mode를 왜 분리해야 하는가
- settings, hooks, `CLAUDE.md`, CLI flags가 startup contract에 들어오는 시점
- preflight initialization과 post-trust initialization의 차이

이 장이 다루지 않는 것:

- 개별 setting key와 CLI flag의 전체 카탈로그
- tool call-time permission 정책 세부
- 세션 시작 이후 turn loop와 recovery의 상세 구조

이 세 주제는 [../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md](../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md), [../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md](../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md), [../03-context-and-control/06-claude-code-query-engine-and-turn-lifecycle.md](../03-context-and-control/06-claude-code-query-engine-and-turn-lifecycle.md)에서 확장한다.

## 자료와 독서 기준

외부 프레이밍:

- Anthropic, [Claude Code settings](https://docs.anthropic.com/en/docs/claude-code/settings), verified 2026-04-06
- Anthropic, [Claude Agent SDK overview](https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-overview), verified 2026-04-06
- Anthropic, [Claude Code CLI reference](https://docs.anthropic.com/en/docs/claude-code/cli-reference), verified 2026-04-06
- Anthropic, [Claude Code release notes](https://docs.anthropic.com/en/release-notes/claude-code), verified 2026-04-06
- OpenAI, [Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md), verified 2026-04-06

사례 재진입 장:

- [05-claude-code-runtime-modes-and-entrypoints.md](05-claude-code-runtime-modes-and-entrypoints.md)
- [06-claude-code-session-startup-trust-and-initialization.md](06-claude-code-session-startup-trust-and-initialization.md)

함께 읽으면 좋은 장:

- [../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md](../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md)
- [../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md](../06-boundaries-deployment-and-safety/02-sandboxing-permissions-and-policy-surfaces.md)

## startup contract는 세션의 선행 조건을 고정한다

startup contract는 "세션이 열릴 때 무엇이 이미 정해지는가"를 뜻한다. 여기에는 보통 다음이 포함된다.

- 어떤 instruction surface가 이번 세션에 로드되는가
- 어떤 policy/config scope가 적용되는가
- 어떤 workspace나 remote target이 신뢰 대상으로 간주되는가
- trust 확인 전후에 어떤 capability가 허용되는가

이 계약을 적지 않으면 동일한 runtime family라도 왜 어떤 세션은 tool을 바로 쓸 수 있고, 어떤 세션은 더 많은 검증을 거치는지 설명하기 어렵다.

## trust boundary와 permission mode는 다른 질문이다

trust boundary는 "이 workspace나 remote target을 세션의 신뢰 범위 안으로 넣을 것인가"를 묻는다. permission mode는 "신뢰 범위 안에서 개별 action을 어떤 승인 정책 아래 실행할 것인가"를 묻는다. 둘 다 gate지만 대상이 다르다.

- trust boundary는 세션 개시 계약과 deployment boundary에 가깝다.
- permission mode는 tool execution과 action authorization에 가깝다.

둘을 구분하지 않으면 startup dialog와 tool approval prompt를 같은 층위로 설명하게 되고, boundary reasoning이 흐려진다.

## settings, hooks, `CLAUDE.md`, CLI flags는 startup contract의 선행 입력면이다

settings file, managed policy, repo instruction file, hook configuration, CLI prompt flag는 모두 "나중에 모델이 읽을 텍스트" 이상의 역할을 한다. 이 입력면들은 세션 시작 전에 어떤 규칙과 추가 instruction이 기본 계약으로 들어올지 결정한다.

이때 중요한 질문은 내용보다 timing이다.

- launch 전에 이미 확정되는가
- trust 이전에 읽히는가
- session-scoped override인가
- policy layer를 바꾸는가, instruction text만 바꾸는가

startup contract 문서는 이 timing을 적어야 한다.

## preflight initialization과 post-trust initialization을 분리하라

초기화는 한 묶음처럼 보이지만 실제로는 두 층으로 나뉜다.

- preflight initialization: path selection, config load, trust check, 초기 policy 계산처럼 세션을 열기 전에 필요한 단계
- post-trust initialization: interactive shell attach, remote client bind, background worker bootstrap처럼 trust 이후에만 붙여야 하는 단계

이 분리가 문서에 드러나면 startup 관련 failure mode도 더 잘 보인다. 예를 들어 config drift와 trust failure는 preflight 문제에 가깝고, shell bootstrap mismatch나 late service attach 문제는 post-trust 문제에 가깝다.

## 사례 장을 읽을 때 확인할 질문

Part 2 사례 장으로 들어갈 때는 아래 질문을 먼저 들고 가면 좋다.

1. 어떤 입력면이 trust 이전에 이미 세션 조건을 바꾸는가.
2. 어떤 초기화가 preflight에서 끝나고, 어떤 초기화가 trust 이후로 미뤄지는가.
3. trust boundary와 permission mode가 같은 UI/코드 경로에 섞여 있는가, 분리돼 있는가.
4. release note drift가 생기면 어느 층이 가장 먼저 흔들리는가.

이 질문은 [06-claude-code-session-startup-trust-and-initialization.md](06-claude-code-session-startup-trust-and-initialization.md)를 읽을 때 startup을 단순 온보딩 flow가 아니라 운영 계약으로 읽게 만든다.

## Sources / evidence notes

- 이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S10`, `S13`, `S14`, `S15`, `S24`를 따른다.
- startup contract 언어는 Tier 1 product docs의 scope, CLI override, repo instruction guidance를 우선하고, runtime-specific 재진입은 Part 2 사례 장으로 닫는다.
