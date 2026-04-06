# 02. task orchestration과 long-running execution

## 장 요약

긴 실행을 운영하려면 단순히 subprocess를 띄우는 것보다 더 많은 것이 필요하다. 실행 단위의 shared vocabulary, family-specific lifecycle, output artifact, notification path, foreground/background handoff, restore path가 함께 있어야 한다. Claude Code는 task를 바로 그 중간 artifact model로 다룬다. 이 장은 task를 UI 표시 요소가 아니라 long-running execution을 가능하게 하는 하네스 구조로 읽는다.

## 범위와 비범위

이 장이 다루는 것:

- shared task vocabulary와 registry의 역할
- local shell, local agent, remote agent family가 왜 서로 다른 lifecycle을 갖는지
- notification/output artifact와 foreground/background handoff가 왜 필요한지
- long-running execution을 평가할 때 어떤 failure mode를 봐야 하는지

이 장이 다루지 않는 것:

- 각 task family의 구현 세부 전부
- remote execution backend protocol의 세부
- team/swarm orchestration 전체
- trace schema, masking, evidence pack 세부
- cost budget, prompt caching, infrastructure noise 세부

이 장은 [05-ui-transcripts-and-operator-control.md](../04-interfaces-and-operator-surfaces/05-ui-transcripts-and-operator-control.md), [01-state-resumability-and-session-ownership.md](01-state-resumability-and-session-ownership.md), [06-claude-code-task-model-and-background-execution.md](06-claude-code-task-model-and-background-execution.md), [08-observability-traces-and-run-artifacts.md](08-observability-traces-and-run-artifacts.md), [09-cost-latency-headroom-and-prompt-caching.md](09-cost-latency-headroom-and-prompt-caching.md)와 이어진다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/Task.ts`
- `src/tasks.ts`
- `src/tasks/LocalShellTask/LocalShellTask.tsx`
- `src/tasks/LocalAgentTask/LocalAgentTask.tsx`
- `src/tasks/RemoteAgentTask/RemoteAgentTask.tsx`
- `src/hooks/useSessionBackgrounding.ts`
- `src/hooks/useBackgroundTaskNavigation.ts`
- `src/screens/REPL.tsx`

외부 프레이밍:

- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

함께 읽으면 좋은 장:

- [03-compaction-memory-and-handoff-artifacts.md](../03-context-and-control/03-compaction-memory-and-handoff-artifacts.md)
- [01-state-resumability-and-session-ownership.md](01-state-resumability-and-session-ownership.md)
- [07-claude-code-end-to-end-scenarios.md](../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)

## 먼저 shared vocabulary를 만든다

`src/Task.ts`는 모든 task family가 공유하는 base state를 제공한다.

```ts
export type TaskStateBase = {
  id: string
  type: TaskType
  status: TaskStatus
  description: string
  startTime: number
  endTime?: number
  outputFile: string
  outputOffset: number
  notified: boolean
}
```

이 구조에서 중요한 것은 task가 process handle이 아니라 artifact라는 점이다. `outputFile`, `outputOffset`, `notified` 같은 필드는 long-running execution이 "어디에 출력이 있고, operator에게 무엇을 통지했는가"를 추적해야 한다는 사실을 드러낸다.

## registry는 runtime family를 좁힌다

`src/tasks.ts`는 모든 task family를 무조건 등록하지 않고, feature gate에 따라 registry membership을 결정한다.

```ts
export function getAllTasks(): Task[] {
  const tasks: Task[] = [
    LocalShellTask,
    LocalAgentTask,
    RemoteAgentTask,
    DreamTask,
  ]
  if (LocalWorkflowTask) tasks.push(LocalWorkflowTask)
  if (MonitorMcpTask) tasks.push(MonitorMcpTask)
  return tasks
}
```

즉 shared vocabulary와 실제 runtime family는 다르다.

- vocabulary는 가능한 task shape를 정의한다.
- registry는 이 build/runtime에서 실제로 살아 있는 family를 결정한다.

이 구분이 없으면 문서는 지원 가능한 task와 실제 활성 task를 섞어 버리기 쉽다.

## LocalAgentTask는 대화형 long-running lifecycle을 가진다

`LocalAgentTaskState`는 shared base 위에 retained transcript, pending message queue, disk bootstrap, eviction deadline 같은 대화형 lifecycle 필드를 추가한다.

```ts
export type LocalAgentTaskState = TaskStateBase & {
  type: 'local_agent';
  agentId: string;
  ...
  messages?: Message[];
  isBackgrounded: boolean;
  pendingMessages: string[];
  retain: boolean;
  diskLoaded: boolean;
  evictAfter?: number;
};
```

이 필드들이 필요한 이유는 local agent task가 단순 "백그라운드 프로세스"가 아니라, 나중에 operator가 다시 열어 보고 메시지를 주고받을 수 있는 transcript-bearing task이기 때문이다.

- `pendingMessages`는 mid-turn에 들어온 메시지를 tool-round boundary에서 drain한다.
- `retain`과 `diskLoaded`는 viewed transcript bootstrap을 제어한다.
- `evictAfter`는 panel visibility와 garbage-collection 타이밍을 제어한다.

즉 local agent family는 long-running execution과 conversation continuity가 결합된 case다.

## LocalShellTask는 output-side prompt detection이 핵심이다

shell family는 agent family와 다른 문제를 푼다. `LocalShellTask`는 stall watchdog을 두고, output tail이 interactive prompt처럼 보이면 notification을 enqueue한다.

```ts
const STALL_CHECK_INTERVAL_MS = 5_000;
const STALL_THRESHOLD_MS = 45_000;
...
if (!looksLikePrompt(content)) {
  lastGrowth = Date.now();
  return;
}
...
enqueuePendingNotification({
  value: message,
  mode: 'task-notification',
  priority: 'next',
  agentId
});
```

이 구조는 shell task가 왜 별도 family여야 하는지 잘 보여 준다.

- shell task의 핵심 위험은 stalled interactive prompt와 output retention이다.
- agent task의 핵심 위험은 pending conversation state와 transcript continuity다.

같은 long-running execution이라도 family마다 failure signature가 다르므로, lifecycle도 달라져야 한다.

## RemoteAgentTask는 identity persistence와 restore를 먼저 본다

remote family는 local shell/local agent와 또 다른 문제를 푼다. 생성 시점부터 output file을 미리 만들고, session sidecar에 identity를 저장한 뒤, resume 시 live remote session에 다시 붙는다.

```ts
const taskState: RemoteAgentTaskState = {
  ...createTaskStateBase(taskId, 'remote_agent', session.title, toolUseId),
  type: 'remote_agent',
  status: 'running',
  sessionId: session.id,
  ...
}
registerTask(taskState, context.setAppState);
...
void persistRemoteAgentMetadata({
  taskId,
  sessionId: session.id,
  title: session.title,
  ...
});
```

```ts
export async function restoreRemoteAgentTasks(context: TaskContext): Promise<void> {
  ...
  const persisted = await listRemoteAgentMetadata();
  ...
  registerTask(taskState, context.setAppState);
  void initTaskOutput(meta.taskId);
  startRemoteSessionPolling(meta.taskId, context);
}
```

이 흐름은 remote family가 "이미 다른 실행 엔진에서 돌아가는 일을 로컬 세션이 다시 붙잡는 문제"를 푼다는 사실을 보여 준다. 따라서 remote agent task의 핵심 artifact는 local process handle이 아니라 persisted identity와 poll loop다.

## foreground/background handoff는 task orchestration의 일부다

`useSessionBackgrounding()`은 foregrounded local agent task의 메시지를 main view에 동기화하고, 다시 background로 되돌릴 때 task state와 main REPL state를 함께 갱신한다.

```ts
if (foregroundedTaskId) {
  ...
  tasks: {
    ...prev.tasks,
    [taskId]: { ...task, isBackgrounded: true },
  },
  ...
  setMessages([])
  resetLoadingState()
  setAbortController(null)
  return
}

onBackgroundQuery()
```

즉 task orchestration은 registry와 spawn만으로 끝나지 않는다. foreground/background handoff, viewed transcript sync, abort routing까지 포함해야 비로소 operator가 long-running execution을 소비할 수 있다.

## chunking만으로는 부족하고 done contract가 필요하다

이 장의 local 근거는 task artifact와 lifecycle에 집중되어 있다. 하지만 Anthropic의 2026-03-24 글을 비교 프레임으로 덧대면, long-running execution에는 또 하나의 층이 보인다. 실행 단위를 tractable하게 쪼개는 것만으로는 충분하지 않고, 각 단위가 무엇을 끝낸 것으로 볼지 미리 합의한 done contract가 필요하다는 점이다.

그 글에서 planner가 만든 high-level spec은 바로 실행으로 떨어지지 않는다. generator와 evaluator는 각 sprint마다 무엇을 만들고 어떻게 검증할지를 먼저 합의한다. 이 contract는 단순 todo list보다 더 강하다.

- 구현할 범위를 좁힌다.
- 검증 행동을 미리 적는다.
- QA가 나중에 "무엇을 봐야 하는가"를 분명히 한다.

즉 chunking은 coherence 문제를 풀고, done contract는 verification ambiguity 문제를 푼다.

## chunking, contract, QA handoff를 분리하라

장기 실행 하네스를 읽을 때 흔한 오해는 "작업을 나눴다"는 사실 하나로 orchestration을 설명하려는 것이다. 실제로는 세 층을 분리하는 편이 더 정확하다.

- chunking: 작업을 어떤 단위로 나눌지 정한다.
- contract: 그 단위에서 무엇이 done이고 어떤 behavior를 확인할지 정한다.
- QA handoff: 실제 실행 뒤 어떤 artifact를 evaluator나 operator가 읽을지 정한다.

Claude Code의 task layer는 이 셋 중 특히 artifact와 lifecycle을 선명하게 보여 주는 사례다. 다른 하네스를 설계하거나 비교할 때는 여기에 contract 층이 명시적으로 있는지 따로 물어보는 편이 좋다.

## 대표 failure mode

1. notification loss  
   완료/실패 signal이 queue나 transcript surface로 돌아오지 않는다.
2. orphan cleanup 실패  
   foreground owner는 사라졌는데 task artifact가 너무 오래 남거나 너무 빨리 사라진다.
3. resume drift  
   remote/local task가 재개될 때 이전 output/state와 새 owner가 어긋난다.
4. family mismatch  
   shell과 agent를 같은 lifecycle로 묶어 양쪽 다 어중간해진다.

long-running execution benchmark는 바로 이런 failure mode를 시나리오로 점검해야 교육적 가치가 생긴다.

여기에 retry, backoff, cancellation semantics를 따로 붙여 읽는 편이 좋다. long-running harness는 단순히 "다시 시도한다"가 아니라, 무엇을 자동 재시도하고, 무엇을 operator approval 뒤에 두며, 언제 orphan cleanup으로 간주하고, 어떤 cancellation을 transcript/trace/task artifact에 남길지를 먼저 정해야 한다. 이 층이 없으면 slow run, flaky dependency, genuine logic failure가 한 바구니에 섞인다.

## 관찰, 원칙, 해석, 권고

관찰:

- task는 process가 아니라 output, notification, transcript, restore path를 가진 artifact다.
- shared vocabulary와 actual runtime family는 별도로 존재한다.
- local shell, local agent, remote agent는 각각 다른 failure signature와 lifecycle을 가진다.

원칙:

- long-running execution은 family-specific lifecycle이 필요하다.
- task orchestration은 spawn보다 notification/handoff/restore를 더 많이 포함한다.
- operator가 task를 소비할 surface를 설계하지 않으면 long-running capability는 사실상 unusable하다.
- long-running execution에서는 chunking과 verification contract를 별도 층으로 보는 편이 낫다.
- retry/backoff/cancel/orphan semantics도 lifecycle의 일부로 문서화해야 한다.

해석:

- Anthropic의 long-running harness 원칙은 이 코드베이스에서 task family별 artifact model로 드러난다.
- NLAH가 말하는 durable artifact도 task orchestration에서는 transcript/output/metadata 조합으로 구체화된다.

권고:

- 새 하네스를 설계할 때는 공통 TaskStateBase를 먼저 만들고, family별로 어떤 필드가 추가되는지 명시적으로 적어라.
- stall detection, pending message queue, persisted identity처럼 family-specific failure를 겨냥한 필드를 억지로 공통화하지 말라.
- background/foreground handoff를 UX 문제로만 두지 말고 execution lifecycle 일부로 문서화하라.
- task list가 있다면, 그 다음에는 done contract와 QA handoff artifact가 있는지 따로 점검하라.
- retry/backoff/cancellation semantics를 cost와 trace artifact에서 다시 읽을 수 있게 연결하라.

## Review scaffold

- task family별로 retry, backoff, cancel, orphan cleanup이 어디서 정의되는지 적어 보라.
- notification loss와 cancellation ambiguity를 서로 다른 failure mode로 분리해 점검하라.
- operator handoff 없이 계속 도는 background execution이 있다면 그 정지 조건과 소유권 회수를 명시하라.

## benchmark 질문

1. 이 시스템은 긴 실행을 task artifact로 승격하는가.
2. shared vocabulary와 family-specific lifecycle을 분리하는가.
3. notification/output/restore path가 task 모델 안에 포함돼 있는가.
4. foreground/background handoff가 operator surface까지 닫혀 있는가.

## 요약

task orchestration은 UI 장식이 아니라 long-running execution의 핵심 구조다. Claude Code는 task를 shared vocabulary, family-specific lifecycle, output artifact, restore path를 가진 중간 모델로 다룬다. 이 구조를 읽어야만 background shell, local agent, remote agent가 왜 서로 다른 실행 계층인지 이해할 수 있다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/Task.ts`
   shared vocabulary를 먼저 본다.
2. `src/tasks.ts`
   runtime family registry를 확인한다.
3. `src/tasks/LocalAgentTask/LocalAgentTask.tsx`
   대화형 long-running lifecycle을 본다.
4. `src/tasks/LocalShellTask/LocalShellTask.tsx`
   output-side prompt detection과 notification path를 확인한다.
5. `src/tasks/RemoteAgentTask/RemoteAgentTask.tsx`
   identity persistence와 restore path를 본다.
6. `src/hooks/useSessionBackgrounding.ts`
   foreground/background handoff를 비교한다.
