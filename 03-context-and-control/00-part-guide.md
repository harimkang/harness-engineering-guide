# Part 3 Guide: Context And Control

이 Part는 context를 프롬프트 텍스트가 아니라 운영 자원이자 경제 자원으로 읽고, turn loop와 recovery를 상태 기계로 해석합니다. 먼저 context class, compaction, checkpoint, handoff, stop hook 같은 일반 원리를 잡고, 이어서 Claude Code의 query pipeline과 QueryEngine이 그 원리를 어떻게 구현하는지 봅니다. 마지막에는 어떤 turn lifecycle 지점을 trace schema와 replay point로 관찰할 수 있는지도 함께 봅니다.

## 이 Part의 핵심 질문

- context는 어떤 lifetime과 owner를 가져야 하는가
- compaction, memory, checkpoint, handoff artifact는 왜 따로 다뤄야 하는가
- turn loop는 어디서 이어지고 어디서 멈추며 어떻게 회복되는가
- query path와 conversation-global state owner는 왜 분리되는가
- 어떤 turn boundary를 trace/event/checkpoint 관점에서 관찰해야 하는가

## 이 Part를 읽고 나면 기대할 수 있는 산출물

- context를 seed, overlay, working set, durable artifact, economic budget으로 나눠 설명할 수 있다
- checkpoint와 handoff artifact, subagent handoff를 같은 말로 뭉개지 않고 구분할 수 있다
- turn lifecycle의 관찰 지점을 trace, replay, resume 관점에서 다시 표시할 수 있다

## 먼저 읽을 원칙 장

1. [./01-context-as-an-operational-resource.md](./01-context-as-an-operational-resource.md)
2. [./02-context-classes-boundaries-and-scopes.md](./02-context-classes-boundaries-and-scopes.md)
3. [./03-compaction-memory-and-handoff-artifacts.md](./03-compaction-memory-and-handoff-artifacts.md)
4. [./04-turn-loops-stop-hooks-and-recovery.md](./04-turn-loops-stop-hooks-and-recovery.md)

## 이어서 읽을 Claude Code 사례 장

1. [./05-claude-code-context-assembly-and-query-pipeline.md](./05-claude-code-context-assembly-and-query-pipeline.md)
2. [./06-claude-code-query-engine-and-turn-lifecycle.md](./06-claude-code-query-engine-and-turn-lifecycle.md)

## 필요할 때 함께 볼 곳

- [../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)
- [../08-reference/02-key-file-index.md](../08-reference/02-key-file-index.md)
