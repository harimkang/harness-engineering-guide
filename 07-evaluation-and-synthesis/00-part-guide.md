# Part 7 Guide: Evaluation And Synthesis

이 Part는 harness를 측정 가능한 시스템으로 읽는 방법과, 앞선 모든 축을 다시 종합하는 방법을 다룹니다. 먼저 model eval과 harness eval의 차이, task/trial/transcript/grader vocabulary, benchmark frame, production trace loop, skeptical evaluator를 읽고, 이어서 eval hygiene를 독립 축으로 끌어올립니다. 그 다음 Claude Code end-to-end scenario와 code reading guide를 통해 전체 구조를 다시 묶습니다.

## 이 Part의 핵심 질문

- model eval과 harness eval은 무엇을 각각 고정하고 무엇을 측정하는가
- task, trial, transcript, grader, outcome을 어떤 artifact 언어로 읽어야 하는가
- production trace와 feedback loop는 optimization에 어떤 입력을 제공하는가
- dataset versioning, contamination, evidence pack은 eval 신뢰성을 어떻게 바꾸는가
- 종합 장에서 ownership handoff와 benchmark question을 어떻게 다시 결합하는가

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

- [../08-reference/02-key-file-index.md](../08-reference/02-key-file-index.md)
- [../08-reference/01-glossary.md](../08-reference/01-glossary.md)
