# Part 8 Guide: Reference

> Why this chapter exists: `reader reference`와 `Claude Code source atlas`를 분리해 Part 8의 entrypoint confusion을 줄인다.
> Reader path tags: `first-pass` / `builder` / `reviewer` / `source-first` / `volatile re-check`
> Last verified: 2026-04-07
> Freshness class: medium
> Source tier focus: reader reference는 Tier 1-3/6 재진입을, source atlas는 Tier 6 observed artifact lookup을 우선한다.

이 Part는 본문 서사를 이어 가는 장이 아니라, reader-facing corpus를 다시 여는 lookup layer다. 다만 lookup 장치도 성격이 다르다. 어떤 파일은 용어와 review matrix를 고정하는 `reader reference`에 가깝고, 어떤 파일은 Claude Code 공개 사본의 provenance label을 빠르게 찾는 `source atlas`에 가깝다. 이 guide의 목적은 그 둘을 섞어 읽지 않게 만드는 것이다.

## Reader-path suggestions

- `first-pass`: [./01-glossary.md](./01-glossary.md)만 먼저 열고, 필요할 때 matrix appendix를 참고한다.
- `builder`: 용어와 review matrix를 먼저 닫은 뒤 source atlas로 내려가 구현 provenance를 다시 잡는다.
- `reviewer`: [./06-instruction-precedence-matrix.md](./06-instruction-precedence-matrix.md), [./07-artifact-taxonomy-and-retention-matrix.md](./07-artifact-taxonomy-and-retention-matrix.md), [./02-key-file-index.md](./02-key-file-index.md)를 같이 연다.
- `source-first`: [./02-key-file-index.md](./02-key-file-index.md)에서 첫 provenance hop을 잡고, 필요하면 directory/root/conditional map으로 넓힌다.
- `volatile re-check`: [./05-conditional-features-map.md](./05-conditional-features-map.md)과 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 watchlist를 함께 본다.

## Part 8의 두 축

### Reader reference

이 축은 독자가 문서 언어와 review artifact를 먼저 닫기 위한 reference다.

1. [./01-glossary.md](./01-glossary.md)
2. [./06-instruction-precedence-matrix.md](./06-instruction-precedence-matrix.md)
3. [./07-artifact-taxonomy-and-retention-matrix.md](./07-artifact-taxonomy-and-retention-matrix.md)

### Claude Code source atlas

이 축은 Claude Code 공개 사본의 provenance label과 구조 지도를 빠르게 다시 찾기 위한 atlas다.

1. [./02-key-file-index.md](./02-key-file-index.md)
2. [./03-directory-map.md](./03-directory-map.md)
3. [./04-root-file-map.md](./04-root-file-map.md)
4. [./05-conditional-features-map.md](./05-conditional-features-map.md)

## 어느 파일부터 열어야 하는가

- 개념이 헷갈리면 glossary부터 연다.
- instruction surface precedence를 빠르게 비교하려면 precedence matrix를 연다.
- transcript, trace, checkpoint, evidence pack을 한 표로 보고 싶으면 artifact taxonomy matrix를 연다.
- 첫 코드 provenance hop이 필요하면 key file index를 연다.
- 구조가 너무 넓게 느껴지면 directory map을 연다.
- 루트 조립면만 빠르게 보고 싶으면 root file map을 연다.
- feature gate와 default-state drift가 걱정되면 conditional features map을 연다.

## 필요할 때 함께 볼 곳

- [../00-front-matter/02-source-analysis-method.md](../00-front-matter/02-source-analysis-method.md)
- [../00-front-matter/03-references.md](../00-front-matter/03-references.md)
- [../07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md](../07-evaluation-and-synthesis/08-benchmark-oriented-code-reading-guide.md)

## Sources / evidence notes

- Part 8의 `reader reference` 축은 canonical registry, eval hygiene, governance, instruction surface 장과 함께 읽을 때 가장 강하다.
- Part 8의 `Claude Code source atlas` 축은 Tier 6 observed artifact re-entry를 담당하며, drift-sensitive claim은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 relevant `S*` source를 함께 다시 확인하는 편이 맞다.
