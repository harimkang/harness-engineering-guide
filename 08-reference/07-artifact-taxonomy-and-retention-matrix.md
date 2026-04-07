# Appendix. Artifact Taxonomy And Retention Matrix

> Why this chapter exists: transcript, trace, checkpoint, evidence pack 같은 운영 artifact를 retention과 reviewability까지 포함한 한 표로 고정한다.
> Reader path tags: `builder` / `reviewer` / `volatile re-check`
> Last verified: 2026-04-07
> Freshness class: medium
> Source tier focus: Part 5-7의 artifact language를 review artifact로 다시 묶고, privacy/governance 관점을 함께 붙인다.

## 장 요약

Part 5는 observability artifact를, Part 6은 governance evidence를, Part 7은 reproducibility bundle을 다룬다. 이 appendix는 그 세 축의 공통 결과물을 한 표로 다시 고정한다. 목적은 "무엇을 남겨야 하는가"뿐 아니라 "누가 왜 남기고, 얼마나 오래 붙들고, privacy rule과 governance value를 어떻게 설명할 것인가"를 같은 언어로 읽게 만드는 것이다.

여기서 retention window는 법무 지침이 아니라 working design guidance다. 즉, review와 reproduction이 끝나기 전에 버리면 안 되는 최소 기간을 뜻한다.

## Matrix

| artifact type | primary owner | primary use | retention window | masking / privacy rule | reproducibility value | governance evidence value |
| --- | --- | --- | --- | --- | --- | --- |
| transcript | runtime owner, operator | 사건 순서와 human review 복기 | session lifecycle + review window | 민감한 user/tool payload가 포함될 수 있으므로 최소 수집과 selective redaction 필요 | high | medium |
| trace / span / event | observability owner, platform engineer | timing topology, bottleneck, branch causality 분석 | incident triage + performance comparison window | span attributes와 tool I/O는 field-level masking 기준이 필요 | high | high |
| checkpoint / restore metadata | runtime owner | resume, replay, restore-path 검증 | restore 성공 확인 + failure review window | path, session id, state snapshot에 민감정보가 섞이지 않게 분리 저장 | high | medium |
| diagnostic summary | service owner, incident responder | failure class triage와 recurring issue clustering | until failure taxonomy stabilizes | summary가 raw sensitive payload를 재노출하지 않게 한다 | medium | medium |
| config / policy snapshot | platform owner, reviewer | 어떤 ruleset 아래 run이 실행됐는지 재구성 | transcript/trace와 같은 review window | secrets는 제외하고 effective config만 남긴다 | high | high |
| evidence pack | evaluator, reviewer, incident owner | disagreement case 재검토와 benchmark reproduction | benchmark baseline or review decision lifecycle | transcript, trace, config를 묶을 때 bundle-level access control이 필요 | very high | high |
| dataset / grader version record | eval owner | score drift와 contamination analysis | benchmark history window | task text와 reference solution 노출 범위를 분리한다 | very high | high |

## 읽는 규칙

1. transcript와 trace는 같은 artifact가 아니다.
2. checkpoint는 state management artifact이면서 observability artifact이기도 하다.
3. config/policy snapshot이 빠지면 같은 run을 다시 설명하기 어렵다.
4. evidence pack은 "다 있으면 좋은 묶음"이 아니라 score와 review 판단을 다시 여는 최소 bundle이다.

## 관련 장

- [../05-execution-continuity-and-integrations/08-observability-traces-and-run-artifacts.md](../05-execution-continuity-and-integrations/08-observability-traces-and-run-artifacts.md)
- [../06-boundaries-deployment-and-safety/07-governance-risk-and-compliance-mapping.md](../06-boundaries-deployment-and-safety/07-governance-risk-and-compliance-mapping.md)
- [../07-evaluation-and-synthesis/09-eval-hygiene-dataset-versioning-and-contamination.md](../07-evaluation-and-synthesis/09-eval-hygiene-dataset-versioning-and-contamination.md)

## Sources / evidence notes

- 이 matrix는 Part 5의 observability artifact language, Part 6의 governance evidence language, Part 7의 reproducibility bundle language를 묶은 review artifact다.
- drift-sensitive privacy and tracing claim은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S22`, `S23`, `S28`, `S29`, `S30`, `S31`을 다시 확인하는 편이 맞다.
