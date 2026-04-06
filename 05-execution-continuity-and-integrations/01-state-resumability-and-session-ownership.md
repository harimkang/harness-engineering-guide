# 02. 상태, resumability, session ownership

## 장 요약

장기 실행형 하네스는 "현재 turn"만 잘 돌면 충분하지 않다. 세션이 끊겼을 때 무엇을 다시 불러오고, 누가 그 상태를 소유하며, 어떤 substrate가 그것을 보존하는지가 중요하다. Claude Code는 resume를 transcript reload 하나로 처리하지 않고, conversation recovery, session metadata, worktree, cost state, agent state, UI injection을 여러 층으로 분리한다. 이 장은 그 ownership model을 읽는 장이다.

## 범위와 비범위

이 장이 다루는 것:

- foreground owner와 durable substrate를 구분하는 이유
- startup resume, in-session resume, headless resume가 어떻게 다른지
- transcript, metadata, worktree, cost state, attribution, todo state가 어디서 복원되는지

이 장이 다루지 않는 것:

- transcript 포맷의 모든 세부 필드
- remote transport 프로토콜과 server-side session model 전부
- context compaction 세부 알고리즘

이 장은 [../context/03-compaction-memory-and-handoff-artifacts.md](../03-context-and-control/03-compaction-memory-and-handoff-artifacts.md), [../context/04-turn-loops-stop-hooks-and-recovery.md](../03-context-and-control/04-turn-loops-stop-hooks-and-recovery.md), [03-task-orchestration-and-long-running-execution.md](02-task-orchestration-and-long-running-execution.md)와 함께 읽는 것이 좋다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/utils/conversationRecovery.ts`
- `src/utils/sessionRestore.ts`
- `src/utils/sessionStorage.ts`
- `src/screens/REPL.tsx`
- `src/QueryEngine.ts`
- `src/cost-tracker.ts`

외부 프레이밍:

- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

함께 읽으면 좋은 장:

- [../13-persistence-config-and-migrations.md](07-claude-code-persistence-config-and-migrations.md)
- [../09-state-ui-and-terminal-interaction.md](../04-interfaces-and-operator-surfaces/08-claude-code-state-ui-and-terminal-interaction.md)
- [../16-risks-debt-and-observations.md](../06-boundaries-deployment-and-safety/06-claude-code-risks-debt-and-failure-modes.md)

## owner와 substrate를 먼저 분리하라

resumability를 설명할 때 가장 흔한 오류는 모든 상태를 한 덩어리로 보는 것이다. Claude Code에서는 적어도 네 층을 나눠 읽는 편이 정확하다.

| 층 | 주된 owner | 예시 |
| --- | --- | --- |
| foreground UI state | REPL/AppState | 현재 screen, viewed task, prompt input, visible messages |
| headless conversation state | QueryEngine | mutableMessages, permissionDenials, usage |
| durable session substrate | sessionStorage | transcript chain, session metadata, content replacement |
| auxiliary restored state | sessionRestore / cost-tracker | file history, attribution, cost state, worktree, agent setting |

이 표가 중요한 이유는 resume가 이 네 층을 한 번에 다루기 때문이다. transcript만 있다고 해서 resume가 되는 것이 아니고, foreground UI state만 바꾼다고 해서 continuity가 생기지도 않는다.

## transcript는 substrate이고, owner는 별도로 복구된다

`src/utils/sessionStorage.ts`는 transcript path를 session/project context에 맞춰 계산한다.

```ts
export function getTranscriptPath(): string {
  const projectDir = getSessionProjectDir() ?? getProjectDir(getOriginalCwd())
  return join(projectDir, `${getSessionId()}.jsonl`)
}
```

하지만 resumability는 이 파일을 다시 여는 것에서 끝나지 않는다. `src/utils/conversationRecovery.ts`는 transcript를 의미 복구 가능한 메시지로 정제하고, `src/utils/sessionRestore.ts`는 owner-facing state를 다시 주입한다. substrate와 owner를 분리하지 않으면 이 두 단계가 흐려진다.

## startup resume와 in-session resume는 다른 문제다

publication-grade execution 문서에서 꼭 분리해야 하는 장면은 두 가지다.

### startup resume

프로세스가 새로 시작된 뒤, transcript와 metadata를 읽어 초기 owner를 다시 세우는 경우다. 이 경로에서는 "누가 이번 세션을 맡을 것인가"가 핵심 질문이 된다.

### in-session resume

이미 살아 있는 interactive REPL 안에서 과거 세션을 foreground로 다시 끌어오는 경우다. 이 경로에서는 "같은 operator surface가 어떤 과거 owner state를 다시 받아들일 것인가"가 핵심이다.

REPL의 `resume` callback은 후자에 해당한다.

```ts
const resume = useCallback(async (sessionId: UUID, log: LogOption, entrypoint: ResumeEntrypoint) => {
  const messages = deserializeMessages(log.messages);
  ...
  restoreSessionStateFromLog(log, setAppState);
  ...
  switchSession(asSessionId(sessionId), log.fullPath ? dirname(log.fullPath) : null);
  ...
  restoreSessionMetadata(log);
  ...
  restoreWorktreeForResume(log.worktreeSession);
  ...
}, ...)
```

이 코드가 보여 주는 것은 in-session resume가 단순 transcript reload가 아니라 session switch, metadata restore, worktree restore, UI message injection을 포함한 foreground transfer라는 점이다.

## restore는 하나의 함수가 아니라 여러 복구기의 협업이다

`restoreSessionStateFromLog()`는 file history, attribution, context-collapse commit log, todo state를 복원한다.

```ts
export function restoreSessionStateFromLog(
  result: ResumeResult,
  setAppState: (f: (prev: AppState) => AppState) => void,
): void {
  if (result.fileHistorySnapshots && result.fileHistorySnapshots.length > 0) {
    fileHistoryRestoreStateFromLog(...)
  }
  ...
  if (!isTodoV2Enabled() && result.messages && result.messages.length > 0) {
    const todos = extractTodosFromTranscript(result.messages)
    ...
  }
}
```

`src/utils/conversationRecovery.ts`는 그보다 앞단에서 invalid message shape를 걸러 낸다. unresolved tool uses, orphaned thinking-only assistant messages, whitespace-only assistant messages를 제거하고, interrupted turn이면 synthetic continuation message를 붙인다.

이 협업 구조가 뜻하는 바는 단순하다. resume는 parser 하나의 책임이 아니라, semantic validity를 회복한 뒤 owner-specific state를 재조립하는 다단계 절차다.

## worktree와 cost state까지 복구해야 continuity가 맞는다

Claude Code는 resume를 message state에만 국한하지 않는다. REPL resume path는 worktree와 cost state도 복원한다.

```ts
const targetSessionCosts = getStoredSessionCosts(sessionId);
saveCurrentSessionCosts();
resetCostState();
switchSession(asSessionId(sessionId), ...)
...
restoreSessionMetadata(log);
...
restoreWorktreeForResume(log.worktreeSession);
```

`src/cost-tracker.ts`도 session ID가 맞는 경우에만 stored cost state를 돌려주고, resume 시 복원한다.

```ts
export function restoreCostStateForSession(sessionId: string): boolean {
  const data = getStoredSessionCosts(sessionId)
  if (!data) {
    return false
  }
  setCostStateForRestore(data)
  return true
}
```

이런 state까지 복구해야 operator는 "같은 세션을 다시 열었다"는 느낌을 받는다. message만 복원하고 cost/worktree/agent state가 어긋나면 continuity는 금방 무너진다.

## QueryEngine은 headless ownership variant를 보여 준다

REPL과 달리 QueryEngine은 headless conversation owner다. 이 경로는 사용자 메시지를 transcript에 먼저 기록해 두어, UI가 없어도 resume contract가 깨지지 않게 만든다.

```ts
// Persist the user's message(s) to transcript BEFORE entering the query loop.
if (persistSession && messagesFromUserInput.length > 0) {
  const transcriptPromise = recordTranscript(messages)
  ...
}
```

즉 same product 안에서도 resume는 owner에 따라 다르게 shaped된다.

- REPL은 visible foreground state를 다시 세운다.
- QueryEngine은 headless continuity와 transcript durability를 우선한다.

resumability를 비교할 때 이 차이를 놓치면 interactive product와 SDK surface를 같은 것으로 오해하게 된다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code의 resume path는 transcript reload를 넘어 worktree, cost, attribution, todo, agent state를 함께 복원한다.
- foreground owner와 durable substrate는 분리돼 있다.
- startup resume와 in-session resume는 같은 기능처럼 보여도 다른 ownership 문제를 푼다.

원칙:

- resumability는 파일 존재 여부가 아니라 ownership restoration 문제로 읽어야 한다.
- restore는 message parsing, semantic cleanup, owner injection, substrate reattachment를 분리해야 한다.
- interactive와 headless surface는 같은 transcript를 써도 다른 owner contract를 가진다고 가정해야 한다.

해석:

- Anthropic의 long-running harness 원칙이 말하는 clean state와 structured artifact는 이 코드베이스에서 owner/substrate 분리로 구체화된다.
- NLAH의 durable artifact framing도 transcript만이 아니라 restore path 전체를 봐야 제대로 적용된다.

권고:

- 새 하네스를 설계할 때는 `무엇을 저장할까`보다 `누가 무엇을 다시 붙일까`를 먼저 문서화하라.
- resume 설계 문서에는 반드시 startup resume와 in-session resume를 분리해 적어라.
- cost, worktree, agent setting처럼 "메시지가 아닌 state"도 continuity에 중요하면 별도 restore 절차를 명시하라.

## benchmark 질문

1. 이 시스템은 foreground owner와 durable substrate를 분리해 설명할 수 있는가.
2. startup resume와 in-session resume가 다른 문제라는 사실이 코드에 드러나는가.
3. restore가 message reload를 넘어 auxiliary state까지 복구하는가.
4. REPL path와 headless path가 같은 transcript를 서로 다른 ownership contract 아래 사용하는가.

## 요약

resumability는 transcript 파일 하나의 문제가 아니라 ownership model의 문제다. Claude Code는 conversation recovery, session restore, worktree restore, cost restore를 분리해 두며, 이 분리가 있어야 장기 실행 continuity가 흔들리지 않는다. execution 장을 읽을 때는 항상 owner와 substrate를 따로 보아야 한다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/utils/conversationRecovery.ts`
   semantic cleanup이 어디서 일어나는지 본다.
2. `src/utils/sessionRestore.ts`
   restored state가 어떤 owner에게 주입되는지 확인한다.
3. `src/utils/sessionStorage.ts`
   durable substrate가 무엇을 저장하는지 본다.
4. `src/screens/REPL.tsx`
   in-session resume가 foreground transfer로 어떻게 작동하는지 본다.
5. `src/QueryEngine.ts`
   headless ownership variant를 비교한다.
6. `src/cost-tracker.ts`
   message 밖의 state가 continuity에 어떻게 기여하는지 확인한다.
