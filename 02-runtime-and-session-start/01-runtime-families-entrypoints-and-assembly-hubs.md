# 01. runtime family, entrypoint, assembly hub

## 장 요약

장기 실행형 agent product를 읽을 때 가장 먼저 해야 할 일은 "이 제품은 어떤 runtime family를 가지는가"를 묻는 것이다. interactive shell, headless SDK path, remote attach, background worker는 겉으로는 하나의 제품처럼 보이지만, 실제로는 서로 다른 state owner, startup depth, capability exposure를 가진다. 이 장은 그 차이를 `runtime family`, `entrypoint`, `assembly hub`, `launch seam` 네 언어로 나눠 읽게 만든다.

핵심은 entrypoint와 assembly hub를 같은 것으로 부르지 않는 것이다. entrypoint는 어떤 family로 들어갈지 fan-out하는 분기점이고, assembly hub는 그 family 안에서 공통 runtime을 조립하는 결절점이다. launch seam은 그 조립 결과가 실제 operator surface나 downstream control loop로 넘어가는 마지막 handoff다.

## 범위와 비범위

이 장이 다루는 것:

- 하나의 agent product가 여러 runtime family를 가져야 하는 이유
- entrypoint, assembly hub, launch seam을 구분해서 적어야 하는 이유
- fast-path와 full runtime assembly의 차이
- 사례 장으로 다시 들어갈 때 어떤 질문을 먼저 들고 가야 하는지

이 장이 다루지 않는 것:

- 특정 제품의 trust/approval sequencing 세부
- query loop나 tool recursion의 내부 구조
- Claude Code 파일별 구현 디테일의 완전한 설명

위 세 주제는 각각 [02-startup-contract-trust-boundary-and-initialization.md](02-startup-contract-trust-boundary-and-initialization.md), [../03-context-and-control/06-claude-code-query-engine-and-turn-lifecycle.md](../03-context-and-control/06-claude-code-query-engine-and-turn-lifecycle.md), [03-claude-code-project-overview.md](03-claude-code-project-overview.md) 이후 사례 장들에서 더 직접 다룬다.

## 자료와 독서 기준

외부 프레이밍:

- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), verified 2026-04-06
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), verified 2026-04-06
- Anthropic, [Claude Agent SDK overview](https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-overview), verified 2026-04-06
- Anthropic, [Claude Code CLI reference](https://docs.anthropic.com/en/docs/claude-code/cli-reference), verified 2026-04-06

사례 재진입 장:

- [03-claude-code-project-overview.md](03-claude-code-project-overview.md)
- [04-claude-code-architecture-map.md](04-claude-code-architecture-map.md)
- [05-claude-code-runtime-modes-and-entrypoints.md](05-claude-code-runtime-modes-and-entrypoints.md)

함께 읽으면 좋은 장:

- [../01-foundations/02-workflows-agents-runtimes-and-harnesses.md](../01-foundations/02-workflows-agents-runtimes-and-harnesses.md)
- [../01-foundations/03-quality-attributes-of-agent-harnesses.md](../01-foundations/03-quality-attributes-of-agent-harnesses.md)

## 왜 하나의 제품이 여러 runtime family를 가지는가

장기 실행형 하네스는 보통 "한 번의 prompt"만 처리하지 않는다. interactive REPL, automation worker, evaluator path, remote attach path는 같은 브랜드와 같은 tool surface를 공유할 수 있지만, 운영 질문은 서로 다르다.

- 누가 state owner인가
- 어떤 artifact가 세션 사이를 건너는가
- 사람이 어느 지점에서 개입하는가
- startup depth와 trust gate가 어디서 달라지는가

runtime family를 먼저 적지 않으면, 나중에 headless path의 제약을 interactive path의 특징처럼 오독하거나, remote attach를 단순 transport 변경처럼 오해하기 쉽다.

## entrypoint는 fan-out 지점이고 assembly hub는 공통 조립 지점이다

entrypoint는 "어느 family로 들어갈지"를 정하는 바깥 분기다. CLI argument, mode flag, attach intent, worker invocation 같은 신호를 보고 다음 경로를 고른다. 반면 assembly hub는 이미 family가 선택된 뒤 공통 state, services, UI shell, adapter를 묶는 안쪽 조립 지점이다.

이 구분이 중요한 이유는 fan-out과 composition의 실패 모드가 다르기 때문이다.

- entrypoint 문제는 잘못된 path selection, 잘못된 fast-path bypass, mode drift로 나타난다.
- assembly hub 문제는 같은 service를 다른 family가 일관되지 않게 공유하거나, state bootstrap 순서가 꼬이는 형태로 나타난다.

따라서 문서에서는 "어디서 시작하는가"와 "어디서 조립되는가"를 따로 적어야 한다.

## fast-path, full assembly, launch seam를 따로 적어라

runtime family를 비교할 때는 depth를 세 층으로 나누면 독해가 빨라진다.

- fast-path: 최소한의 분기와 검증만 거치고 곧바로 특정 family로 들어가는 경로
- full runtime assembly: 공통 services, state, shell, adapter를 모두 조립하는 경로
- launch seam: 조립된 runtime이 실제 operator surface, query loop, remote client, background executor로 handoff되는 지점

이 셋을 분리해 두면 "같은 제품인데 왜 어떤 path는 이렇게 짧고 어떤 path는 이렇게 깊은가"를 자연스럽게 설명할 수 있다.

## 사례 장을 읽기 전에 먼저 던질 질문

Part 2 사례 장으로 들어가기 전에는 아래 질문을 먼저 고정하는 편이 좋다.

1. 이 경로는 새로운 runtime family인가, 기존 family의 launch seam인가.
2. entrypoint가 여기서 끝나는가, 아니면 assembly hub까지 바로 이어지는가.
3. fast-path가 있다면 어떤 공통 초기화를 생략하는가.
4. launch seam 이후 state owner는 누구로 바뀌는가.

이 질문을 먼저 들고 가면 [05-claude-code-runtime-modes-and-entrypoints.md](05-claude-code-runtime-modes-and-entrypoints.md)를 읽을 때 file tree보다 운영 구조가 먼저 보인다.

## Sources / evidence notes

- 이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S6`, `S8`, `S13`, `S14`를 따른다.
- runtime family와 assembly 언어는 Tier 2 long-running harness framing을 우선하고, 제품 surface 재진입 포인터는 Tier 1 product docs와 Part 2 사례 장으로 닫는다.
