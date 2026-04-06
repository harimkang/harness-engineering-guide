# 02. Source Analysis Method

> Why this chapter exists: 이 책이 어떤 source를 어떤 무게로 읽고, 어떤 문장을 어떤 근거 위에 쓰는지 고정한다.
> Reader level: beginner / advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: medium

## Core claim

이 문서 세트는 `관찰`, `원칙`, `해석`, `권고`를 섞어 쓰되, 그 층위를
분리해서 읽게 해야 한다. 특히 fast-moving topic을 다룰 때는 proposal에
정리한 공식 출처를 먼저 다시 확인하고, 그 확인 결과를 freshness note와
evidence note에 남겨야 한다.

## What this chapter is not claiming

- 공개 스냅샷 밖의 구현을 확정할 수 있다는 주장
- 연구 preprint가 공식 제품 문서와 같은 무게를 가진다는 주장
- code block이나 Mermaid 하나만으로 운영 현실을 확정할 수 있다는 주장

## 적용 범위

이 부록의 규칙은 reader-facing 문서 집합에 적용한다.

- `README.md`
- [01-how-to-read-this-book.md](01-how-to-read-this-book.md)
- `01-foundations/**`
- `02-runtime-and-session-start/**`
- `03-context-and-control/**`
- `04-interfaces-and-operator-surfaces/**`
- `05-execution-continuity-and-integrations/**`
- `06-boundaries-deployment-and-safety/**`
- `07-evaluation-and-synthesis/**`
- `08-reference/**`

다음 경로는 내부 작업 문서이므로 출판 규약 적용 대상에서 제외한다.

- `superpowers/**`

## 2026-04-06 baseline

Task 7 착수 직전 기준으로 이 문서 세트에는 이미 다음 baseline이 있었다.

- `README.md`는 저장소 단위 `Last verified` 날짜와 volatile topic 요약을 갖고 있었다.
- 이 장은 source weight, claim status, freshness class를 이미 분리하고 있었다.
- [03-references.md](03-references.md)는 공식 자료를 canonical registry로 묶고,
  주요 항목에 verified date를 붙이고 있었다.

이번 보강은 이 baseline을 뒤엎는 것이 아니라, 다음 네 가지를 더 명시적으로
만드는 작업이다.

- source tier hierarchy와 primary vs provisional distinction
- freshness class를 chapter claim과 연결하는 방법
- observed artifact citation 규칙
- proposal source ID 기반 verification loop

## Source tier hierarchy

reader-facing 문서에서 쓰는 source의 기본 무게는 아래 순서를 따른다.

| Tier | 기본 범주 | 기본 용도 | 검증 규칙 |
| --- | --- | --- | --- |
| 1 | Primary / official docs | 제품 동작, SDK surface, 최신 권장사항 | substantive change 전에 반드시 재확인 |
| 2 | Official engineering posts | 설계 원칙, 운영 패턴, trade-off framing | 원칙 층위로 사용하고 drift를 재확인 |
| 3 | Protocol specifications / standards | schema, vocabulary, interoperability | version marker와 status를 함께 기록 |
| 4 | Framework docs | 구현 비교 프레임, reusable pattern 비교 | local artifact를 대체하지 않음 |
| 5 | Provisional research / preprints | 가설, 비교 프레임, emerging terminology | 단독 근거 금지, provisional 표기 필수 |
| 6 | Observed code / public artifact snapshot | 공개 스냅샷 안에서 직접 확인 가능한 사실 | provenance와 verification date를 남김 |

이 순서는 "항상 위 tier만 인용한다"는 뜻이 아니라, claim이 무엇에 기대고
있는지를 독자가 다시 검토할 수 있게 하라는 뜻이다.

- product behavior, settings, managed policy, SDK contract, tracing support, eval
  guidance는 가능한 한 Tier 1에 먼저 기대야 한다.
- architectural framing, workflow vs agent distinction, long-running harness
  pattern, evaluator-driven design은 Tier 2가 강한 설명력을 가진다.
- protocol-level field naming, span semantics, interoperability 논의는 Tier 3가
  우선이다.
- persistence, interrupts, masking 같은 comparative implementation pattern은
  Tier 4를 비교 근거로 쓴다.
- Tier 5는 provisional framing으로만 사용한다.
- Tier 6는 local artifact 사실을 말할 때 필요하지만, 외부 제품 claim을 대신할
  수 없다.

fast-moving topic에서는 추가 우선순위를 둔다.

1. official docs
2. release notes
3. observed artifact
4. preprint

## Primary vs provisional distinction

`primary`와 `provisional`은 source 종류가 아니라 claim 안정성을 가리키는
표기다.

- `primary`
  - official docs
  - official engineering posts
  - protocol specs
  - standards / governance publications
- `supplemental`
  - framework docs
  - observed public artifact
  - 반복적으로 참조하는 비교용 문서
- `provisional`
  - research preprint
  - under-review paper
  - stable adoption이 없는 draft semantics
  - 공식 문서와 교차검증되지 않은 관찰 해석

under-review 논문이나 preprint는 반드시 provisional framing으로 취급한다.
local artifact와 잘 맞더라도 reader-facing 본문에서는 "비교 프레임" 또는
"가설을 돕는 참고점" 이상으로 올리지 않는다.

## Proposal source verification rule

이번 개편에서 `harness-engineering-guide-revision-proposal.md`의 출처 섹션은
canonical source registry다. reader-facing 문서를 실질적으로 업데이트,
추가, 수정, 삭제할 때는 다음 순서를 따른다.

1. proposal에서 관련 source ID를 찾는다.
2. 공식 URL을 실제로 다시 열어 현재 내용을 확인한다.
3. 확인한 사실만 본문에 반영한다.
4. drift, 불일치, 폐기된 경로가 있으면 추정으로 메우지 않고
   `Freshness class`, `Last verified`, `Sources / evidence notes`에 남긴다.

추가 규칙:

- proposal의 `S*` ID는 immutable canonical identifier다.
- supplemental research와 observed artifact는 `P*`, `R*` 같은 별도 계열 ID를
  써야 하며 `S*`를 재사용하지 않는다.
- substantive change를 한 장에는 가능하면 어떤 proposal source ID를 다시
  확인했는지 `Sources / evidence notes`에 적는다.
- 적절한 official source를 찾지 못하면 본문을 확정하지 말고 `Open question`
  또는 freshness note로 남긴다.

chapter의 `Sources / evidence notes`에는 가능하면 proposal source ID를 같이
남긴다. 예:

```md
- `S22` OpenAI Tracing: trace/span vocabulary와 sensitive-data capture rule을 다시 확인했다.
- `S29` OpenTelemetry GenAI semconv: span/event/metric naming이 아직 Development status임을 다시 확인했다.
```

2026-04-06 기준으로 다음 고변동 공식 문서는 실제 URL을 다시 확인했다.

- Claude Code settings
- Claude Code skills
- Claude Code CLI reference
- Claude Code release notes
- MCP specification `2025-11-25`
- MCP client concepts
- OpenAI `AGENTS.md` guide
- OpenAI Agents SDK guide
- OpenAI tracing
- OpenAI evaluation best practices / agent evals
- LangGraph persistence / interrupts / observability
- OpenTelemetry GenAI semantic conventions
- NIST AI RMF Generative AI Profile / Playbook

## Claim status

이 문서 세트는 장 안에서 아래 claim status를 분리한다.

- Fact from official docs
- Fact from observed artifact/code
- Interpretation / synthesis
- Recommendation
- Open question / unverifiable from current sources

문장 표기와의 대응은 아래처럼 읽는다.

- `관찰:` local code 또는 관찰 가능한 artifact에서 직접 확인한 사실
- `원칙:` 공식 문서나 공식 엔지니어링 글이 직접 말하는 주장
- `해석:` 여러 근거를 종합한 구조적 판단
- `권고:` 독자가 자기 하네스 설계에 적용할 일반화된 지침
- `확인 불가:` 스냅샷 밖이거나 source만으로 확정할 수 없는 연결고리

## Freshness classes

| Class | 의미 | 대표 대상 | 편집 규칙 |
| --- | --- | --- | --- |
| `stable` | 구조적 distinction과 오래 유지되는 taxonomy | workflow vs harness, glossary, core operating questions | 큰 framing change만 source 재확인 |
| `medium` | 원칙은 오래 가지만 운영 관행과 schema가 바뀔 수 있음 | eval practice, observability patterns, governance mapping | 실질 수정 전 source 재확인 권장 |
| `volatile` | release note, SDK, hosted product behavior, draft semantics에 민감 | settings, skills, CLI flags, tracing products, MCP client semantics | 장 수정 직전에 source 재확인 필수 |

`volatile` 장은 장 서두에 verified date를 남기고, 어떤 source를 다시
확인했는지 적는다.

## Snapshot and observed-artifact citation rules

공개 사본이나 관찰 가능한 artifact를 인용할 때는 가능하면 아래 식별자 중 최소
둘 이상을 남긴다.

- source ID 또는 artifact ID
- commit hash
- tag or release version
- package version
- acquisition path
- verification date

커밋 해시가 없는 공개 배포본이면 `현재 공개 사본`과 기준 날짜를 함께 적는다.
관찰 artifact가 chapter-level claim의 핵심 근거라면, 가능하면 "무엇을 봤고
무엇은 보지 못했는지"를 함께 적는다.

## Reviewability rules

reader-facing 문서는 나중에 skeptical reviewer가 다시 확인할 수 있어야 한다.
그래서 evidence note와 operational artifact를 다음처럼 연결한다.

- policy나 운영 원칙을 말할 때는 verified proposal source ID를 남긴다.
- local or observed artifact를 말할 때는 provenance 단서와 verification date를 남긴다.
- trace, transcript, result packet, cost record, handoff note 같은 artifact를
  언급할 때는 "무엇을 review할 수 있게 해 주는가"를 함께 적는다.
- sensitive-data-bearing trace를 다룰 때는 capture 여부, redaction 여부,
  privacy caveat를 함께 적는다.

## Evidence block rules

code block과 diagram은 증거이지만, 단독으로 장의 주장을 완성하지는 않는다.

- code block은 짧게 유지한다.
- 한 block은 한 주장에 대응시킨다.
- block 바로 아래에 해설을 붙인다.
- 긴 함수는 생략을 명시한다.
- provenance 단서로 파일 경로와 함수/구간 이름을 남긴다.

권장 evidence metadata:

```md
출처:
- 파일 경로
- 함수/구간 이름
- 스냅샷 기준
- 발췌 규칙
- 출처 단서
```

## Diagram discipline

diagram은 선택이 아니라 검토 대상이다.

- runtime, session, context, tooling, permission, resumability, trace, boundary
  계열 장은 diagram candidate로 본다.
- Mermaid는 구조도, 시퀀스, 상태 전이를 요약하는 용도로 쓴다.
- 다이어그램만 있고 본문 해설이 없는 상태는 허용하지 않는다.
- diagram을 넣지 않기로 했으면, 본문 구조만으로 충분한 이유가 설명 가능해야 한다.

## Chapter template contract

새 장과 실질적으로 재작성하는 기존 장은 가능하면 아래 골격을 따른다.

```md
> Why this chapter exists
> Reader level
> Last verified
> Freshness class

## Core claim
## What this chapter is not claiming
## Mental model / diagram
## Design implications
## What to measure
## Failure signatures
## Review questions
## Sources / evidence notes
```

모든 장을 기계적으로 같은 길이로 맞출 필요는 없지만, 독자가 "왜 이 장을
읽는가"와 "무엇을 근거로 믿어야 하는가"를 빠르게 알 수 있어야 한다.

## 스냅샷에 없는 것은 추정하지 않는다

다음 정보는 reader-facing 본문의 핵심 근거가 아니다.

- git 이력과 커밋 의도
- 테스트 인프라 전체
- CI/CD 설정
- 빌드 파이프라인의 외부 단계
- 저장소 외부 서비스의 서버 구현

이 정보가 스냅샷에 직접 포함되지 않거나 부분적이면 본문에서는 `확인 불가:`
또는 `스냅샷 범위 밖`으로 취급한다.

## 요약

이 문서 세트는 공개 스냅샷과 공식 문서를 결합해 Claude Code를 사례 기반
하네스 엔지니어링 교재로 읽는다. 핵심 규칙은 세 가지다.

1. source tier와 claim status를 분리한다.
2. proposal `S*` ID를 기준으로 substantive change를 다시 검증한다.
3. fast-moving topic과 observed artifact는 freshness와 reviewability metadata를 남긴다.
