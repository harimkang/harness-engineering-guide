# Harness Engineering: Designing Operational Systems for Long-Running Agents

이 저장소는 장기 실행형 agent harness를 설계, 분석, 평가하기 위한 한국어 reader-facing 문서 세트다. Claude Code를 반복 사례로 사용하지만, 목적은 특정 제품의 기능 소개가 아니라 harness engineering을 읽고 비교하는 공통 설계 언어를 만드는 데 있다.

공개 저장소로 운영하며 외부 이슈와 PR 제안을 받을 수 있다. 다만 이 문서 세트는 Anthropic 또는 다른 벤더의 공식 문서를 대체하지 않는다. 제품 사실과 drift-sensitive claim은 항상 [00-front-matter/03-references.md](./00-front-matter/03-references.md)의 canonical source registry와 함께 읽는 편이 맞다.

## 이 문서 세트가 하는 일

- 하네스를 단순 프롬프트 묶음이 아니라 운영 시스템으로 읽는다.
- 일반 원칙과 Claude Code 사례를 왕복하면서 설계 언어를 만든다.
- 평가를 뒤에 붙는 부록이 아니라 설계와 운영의 일부로 다룬다.
- instruction surfaces, observability/economics, governance, eval hygiene, reviewability를 독립 설계면으로 끌어올린다.

## 이 문서 세트가 하지 않는 일

- 일반 LLM 입문서 역할
- 모델 학습, 파인튜닝, 내부 가중치 분석
- 비공개 구현을 추정해 채워 넣는 일
- 특정 제품의 기능 소개 문서를 대체하는 일

## 처음 읽는다면

가장 안전한 입구는 `README -> front matter -> foundations -> 관심 있는 part guide` 순서다. 처음 읽는 독자는 아래 다섯 문서만 먼저 읽어도 이 문서 세트의 독서 규칙과 재진입 지점을 잡을 수 있다.

1. [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md)
2. [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)
3. [00-front-matter/03-references.md](./00-front-matter/03-references.md)
4. [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md)
5. [02-runtime-and-session-start/00-part-guide.md](./02-runtime-and-session-start/00-part-guide.md)

Claude Code 사례 장은 파일명에 `claude-code-`가 들어가므로 일반론과 빠르게 구분할 수 있다. [08-reference/](./08-reference)는 본문 서사가 아니라 `reader reference`와 `Claude Code source atlas`로 나뉘는 lookup layer다.

## 독자별 시작점

- `first-pass`: [00-front-matter/01-how-to-read-this-book.md](./00-front-matter/01-how-to-read-this-book.md) -> [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md) -> [00-front-matter/03-references.md](./00-front-matter/03-references.md) -> [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md) -> 관심 있는 `00-part-guide.md`
- `builder`: foundations 핵심 장 뒤에 관련 Part guide와 synthesis 장을 붙여 읽는다.
- `reviewer`: [00-front-matter/03-references.md](./00-front-matter/03-references.md), [08-reference/01-glossary.md](./08-reference/01-glossary.md), [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md)를 옆에 두고 claim tier와 provenance를 같이 본다.
- `source-first`: [07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md](./07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md)와 [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md)에서 provenance를 잡고 본문으로 되돌아간다.
- `초심자 90분 코스`: [01-foundations/01-why-harness-engineering-matters.md](./01-foundations/01-why-harness-engineering-matters.md) -> [01-foundations/02-workflows-agents-runtimes-and-harnesses.md](./01-foundations/02-workflows-agents-runtimes-and-harnesses.md) -> [02-runtime-and-session-start/00-part-guide.md](./02-runtime-and-session-start/00-part-guide.md) -> [03-context-and-control/01-context-as-an-operational-resource.md](./03-context-and-control/01-context-as-an-operational-resource.md) -> [04-interfaces-and-operator-surfaces/01-tool-contracts-and-the-agent-computer-interface.md](./04-interfaces-and-operator-surfaces/01-tool-contracts-and-the-agent-computer-interface.md) -> [07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](./07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)

## 이 문서 세트가 다루는 질문

- context를 무엇으로 채우고 언제 버릴 것인가
- context reset과 compaction을 언제 구분할 것인가
- 여러 턴, interruption, recovery, handoff를 어떻게 운영할 것인가
- tool, command, skill, plugin, MCP를 어떤 계약 표면으로 설계할 것인가
- settings, hooks, `CLAUDE.md`, subagents, CLI flags 같은 instruction surface를 어떻게 읽을 것인가
- observability, traces, run artifacts, cost, latency, headroom을 언제 운영 문제로 끌어올릴 것인가
- sandbox, trust, remote boundary를 어디에 둘 것인가
- model eval이 아니라 harness eval을 어떻게 설계할 것인가

## 문서 구성

### Reader-facing corpus

- [README.md](./README.md)
- [00-front-matter/](./00-front-matter)
- [01-foundations/](./01-foundations)
- [02-runtime-and-session-start/](./02-runtime-and-session-start)부터 [07-evaluation-and-synthesis/](./07-evaluation-and-synthesis)까지의 paired principle/case parts
- [08-reference/](./08-reference) (`reader reference + source atlas`)

### Maintenance and support paths

- [assets/](./assets): 공개 독서 경험을 돕는 정적 자산
- [scripts/](./scripts): 문서 정합성 점검과 유지보수 스크립트
- [superpowers/](./superpowers): 내부 작업용 보조 문서와 제작 흔적
- [harness-engineering-guide-rereview-2026-04-06.md](./harness-engineering-guide-rereview-2026-04-06.md): 내부 재검토 메모 성격의 작업 문서

reader-facing 독서 경로는 `README`와 `00-front-matter`부터 `08-reference`까지를 기준으로 잡는 편이 안전하다. 루트에 보이는 모든 파일이 독자용 출판 범위에 속하는 것은 아니다.

## Part 지도

- Part 0. [Front Matter](./00-front-matter): 독서 규칙, source analysis method, canonical registry를 고정한다.
- Part 1. [Foundations](./01-foundations): workflow, runtime, harness, eval harness를 구분하고 공통 설계 축을 세운다.
- Part 2. [Runtime And Session Start](./02-runtime-and-session-start/00-part-guide.md): runtime family, startup contract, trust boundary를 다룬다.
- Part 3. [Context And Control](./03-context-and-control/00-part-guide.md): context assembly, compaction, handoff, turn lifecycle을 다룬다.
- Part 4. [Interfaces And Operator Surfaces](./04-interfaces-and-operator-surfaces/00-part-guide.md): tool contract, permission shaping, extension surface, instruction surface를 다룬다.
- Part 5. [Execution, Continuity, And Integrations](./05-execution-continuity-and-integrations/00-part-guide.md): resumability, task orchestration, services/integrations, persistence를 다룬다.
- Part 6. [Boundaries, Deployment, And Safety](./06-boundaries-deployment-and-safety/00-part-guide.md): sandboxing, policy surfaces, local/remote family, governance mapping을 다룬다.
- Part 7. [Evaluation And Synthesis](./07-evaluation-and-synthesis/00-part-guide.md): harness eval, trials/transcripts/graders, benchmark framing, end-to-end synthesis를 다룬다.
- Part 8. [Reference](./08-reference/00-part-guide.md): glossary, matrix appendix, file index, directory map, conditional feature map을 제공한다.

## 핵심 참조 장치

- [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md): source tier, freshness 분류, observed-artifact citation, source verification 규칙을 설명한다.
- [00-front-matter/03-references.md](./00-front-matter/03-references.md): 공식 문서, 엔지니어링 글, 사양, 프레임워크 문서, supplemental research, observed artifact의 canonical registry와 watchlist 재진입 지점을 모아 둔다.
- [08-reference/00-part-guide.md](./08-reference/00-part-guide.md): Part 8의 `reader reference`와 `Claude Code source atlas`를 어떤 순서로 열어야 하는지 안내한다.
- [08-reference/01-glossary.md](./08-reference/01-glossary.md): 핵심 용어의 정의, 차이, confusable terms를 모아 둔다.
- [08-reference/02-key-file-index.md](./08-reference/02-key-file-index.md): benchmark question 중심으로 어떤 발췌와 provenance label을 다시 볼지 정리할 때 쓴다.

## 문서 상태와 검증 기준

> Last verified against official docs: 2026-04-06
> Volatile topics: Claude Code settings, skills, CLI flags, MCP client semantics, remote/bridge behavior, tracing and eval tooling
> Source policy: [00-front-matter/03-references.md](./00-front-matter/03-references.md) maintains immutable canonical registry IDs (`S*`, `P*`, `R*`); supplemental research and observed artifacts use separate ID families
> Reader paths: `first-pass`, `builder`, `reviewer`, `source-first`, `volatile re-check`
> Freshness baseline: reader-entry and reference scaffolds were normalized on 2026-04-06; watchlist and evidence-pack practice live in [00-front-matter/03-references.md](./00-front-matter/03-references.md) and [00-front-matter/02-source-analysis-method.md](./00-front-matter/02-source-analysis-method.md)

- entry path는 `README -> 00-front-matter -> foundations -> part guide -> chapter -> 08-reference` 순서로 통일한다.
- volatile chapter를 고칠 때는 `Last verified`, `Freshness class`, `Sources / evidence notes`를 함께 갱신한다.
- 주요 개정 시에는 checked docs list, checked release notes window, observed artifact snapshot identifiers, changed chapters를 evidence-pack 메모로 남긴다.

## 기여와 저장소 운영

- 이 저장소는 공개 저장소로 운영하며 외부 이슈와 PR 제안을 받을 수 있다.
- 한국어를 기본 서술 언어로 사용하고, 필요한 경우 첫 등장 시 영문을 괄호로 병기한다. 파일 경로, 코드 식별자, 제품 표면 이름은 원문 표기를 유지한다.
- 독자용 문서를 추가하거나 구조를 바꿀 때는 이 [README.md](./README.md)와 관련 `00-part-guide.md`, 필요하면 [00-front-matter/03-references.md](./00-front-matter/03-references.md)를 함께 갱신한다.
- 새 외부 자료가 본문에 들어오면 [00-front-matter/03-references.md](./00-front-matter/03-references.md)의 canonical registry를 먼저 확인하고 필요한 ID를 추가하거나 재확인한다.
- substantive change를 넣기 전에 관련 `S*` ID를 먼저 다시 확인한다. supplemental research와 observed artifact는 canonical `S*` ID를 재사용하지 않고 별도 ID로 등록한다.
- volatile topic을 수정하면 verified date와 freshness class를 함께 갱신한다.
- 외부 기여를 보낼 때는 문제 문장, 영향을 받는 장이나 reader path, 필요한 source re-check 범위를 PR 본문이나 이슈에 적어 주는 편이 좋다.
- 현재 루트에는 별도 `CONTRIBUTING.md`와 `LICENSE` 파일이 없다. 외부 협업과 재사용 정책을 더 명확히 하려면 두 파일을 별도로 추가하는 편이 맞다.
