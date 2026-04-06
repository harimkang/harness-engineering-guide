# Part 7 Guide: Evaluation And Synthesis

> Why this chapter exists: harness eval, synthesis, reproducibility를 한 review loop로 다시 묶는다.
> Reader path tags: `first-pass` / `builder` / `reviewer`
> Last verified: 2026-04-06
> Freshness class: medium
> Source tier focus: Tier 2 eval framing, Tier 1 official eval/tracing docs, Tier 6 Claude Code synthesis cuts
> Volatile topics: tracing products, eval tooling guidance, benchmark reproducibility policy

이 Part는 harness를 측정 가능한 시스템으로 읽는 방법과, 앞선 모든 축을 다시 종합하는 방법을 다룹니다. 먼저 model eval과 harness eval의 차이, task/trial/transcript/grader vocabulary, benchmark frame, production trace loop, skeptical evaluator를 읽고, 이어서 eval hygiene를 독립 축으로 끌어올립니다. 그 다음 Claude Code end-to-end scenario와 code reading guide를 통해 전체 구조를 다시 묶습니다. 이번 개정에서는 dataset/version contamination hygiene, reproducibility bundle, flaky-dependency policy, grader disagreement와 retirement, scenario/code-reading 장의 위치를 더 분명하게 정리합니다.

## Reader-path suggestions

- `first-pass`: [./01-model-evals-vs-harness-evals.md](./01-model-evals-vs-harness-evals.md), [./03-benchmarking-long-running-agent-harnesses.md](./03-benchmarking-long-running-agent-harnesses.md), [./07-claude-code-end-to-end-scenarios.md](./07-claude-code-end-to-end-scenarios.md)를 먼저 읽는다.
- `builder`: [./04-production-traces-feedback-loops-and-optimization.md](./04-production-traces-feedback-loops-and-optimization.md), [./06-contract-based-qa-and-skeptical-evaluators.md](./06-contract-based-qa-and-skeptical-evaluators.md), [./09-eval-hygiene-dataset-versioning-and-contamination.md](./09-eval-hygiene-dataset-versioning-and-contamination.md)를 묶어 evidence pack과 reproducibility bundle 언어를 고정한다.
- `reviewer`: scenario 장과 code-reading guide는 마지막에 읽되, reproducibility와 evidence-pack discipline은 [./09-eval-hygiene-dataset-versioning-and-contamination.md](./09-eval-hygiene-dataset-versioning-and-contamination.md)를 기준 장으로 삼는다.

## 이 Part의 핵심 질문

- model eval과 harness eval은 무엇을 각각 고정하고 무엇을 측정하는가
- task, trial, transcript, grader, outcome을 어떤 artifact 언어로 읽어야 하는가
- production trace와 feedback loop는 optimization에 어떤 입력을 제공하는가
- dataset versioning, contamination, evidence pack은 eval 신뢰성을 어떻게 바꾸는가
- 종합 장에서 ownership handoff와 benchmark question을 어떻게 다시 결합하는가
- code-reading guide는 왜 본문 마지막 장이면서도 reference 쪽 경로와 강하게 이어져야 하는가

## 먼저 읽을 원칙 장

1. [./01-model-evals-vs-harness-evals.md](./01-model-evals-vs-harness-evals.md)
2. [./02-tasks-trials-transcripts-and-graders.md](./02-tasks-trials-transcripts-and-graders.md)
3. [./03-benchmarking-long-running-agent-harnesses.md](./03-benchmarking-long-running-agent-harnesses.md)
4. [./04-production-traces-feedback-loops-and-optimization.md](./04-production-traces-feedback-loops-and-optimization.md)
5. [./05-harness-benchmark-framework.md](./05-harness-benchmark-framework.md)
6. [./06-contract-based-qa-and-skeptical-evaluators.md](./06-contract-based-qa-and-skeptical-evaluators.md)
7. [./09-eval-hygiene-dataset-versioning-and-contamination.md](./09-eval-hygiene-dataset-versioning-and-contamination.md)

## 이어서 읽을 Claude Code 종합 장

1. [./07-claude-code-end-to-end-scenarios.md](./07-claude-code-end-to-end-scenarios.md)
2. [./08-benchmark-oriented-code-reading-guide.md](./08-benchmark-oriented-code-reading-guide.md)

## 필요할 때 함께 볼 곳

- [../06-boundaries-deployment-and-safety/07-governance-risk-and-compliance-mapping.md](../06-boundaries-deployment-and-safety/07-governance-risk-and-compliance-mapping.md)
- [../08-reference/02-key-file-index.md](../08-reference/02-key-file-index.md)
- [../08-reference/01-glossary.md](../08-reference/01-glossary.md)

## Sources / evidence notes

- 이 Part의 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S7`, `S21`, `S22`, `S23`, `S28`, `S29`, `S30`, `S31`, `S32`를 따른다.
- reproducibility bundle과 evidence-pack language는 [./09-eval-hygiene-dataset-versioning-and-contamination.md](./09-eval-hygiene-dataset-versioning-and-contamination.md)에 중심을 둔다.
