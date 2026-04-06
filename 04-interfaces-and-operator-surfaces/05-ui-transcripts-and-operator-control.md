# 05. UI, transcript, operator control

## 장 요약

하네스에서 UI는 장식이 아니라 제어 표면이다. Claude Code의 REPL은 단순 채팅창이 아니라, 같은 세션 상태를 prompt view, transcript view, permission dialog, background task view, remote attach view로 다시 배치하는 runtime surface다. transcript 역시 단순 scrollback이 아니라 operator가 현재 상태를 읽고 개입 시점을 판단하는 운영 artifact다.

## 범위와 비범위

이 장이 다루는 것:

- REPL이 왜 runtime surface인지
- transcript mode가 단순 로그가 아니라 operator control surface인 이유
- permission dialog, backgrounding, task viewing이 같은 세션 상태와 어떻게 연결되는지

이 장이 다루지 않는 것:

- 개별 permission prompt UI의 미세 인터랙션 전부
- remote session transport 세부
- background task family의 상세 lifecycle 전부

이 주제들은 [02-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md), [03-human-oversight-trust-and-approval.md](../05-execution-continuity-and-integrations/03-human-oversight-trust-and-approval.md), [08-claude-code-state-ui-and-terminal-interaction.md](08-claude-code-state-ui-and-terminal-interaction.md)에서 각각 확장한다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/screens/REPL.tsx`
- `src/hooks/useGlobalKeybindings.tsx`
- `src/hooks/useLogMessages.ts`
- `src/hooks/useSessionBackgrounding.ts`
- `src/components/permissions/PermissionRequest.tsx`
- `src/state/AppStateStore.ts`
- `src/state/AppState.tsx`

외부 프레이밍:

- Anthropic, [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), 2025-11-26
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

Sources / evidence notes:
이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 Part 4 cluster를 따른다. 핵심 source ID는 `S6`, `S8`, `S9`, `S22`, `S28`, `S29`이며, `P1`은 UI artifact 비교의 보조 프레임으로만 사용한다.

전제:

- 이 파트는 현재 공개 build에서 확인 가능한 기본 경로를 기준으로 썼다. `KAIROS`, `TRANSCRIPT_CLASSIFIER`, `COORDINATOR_MODE` 같은 compile-time/feature gate에 따라 일부 UI 표면과 operator flow는 달라질 수 있다.

함께 읽으면 좋은 장:

- [04-turn-loops-stop-hooks-and-recovery.md](../03-context-and-control/04-turn-loops-stop-hooks-and-recovery.md)
- [02-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md)
- [03-human-oversight-trust-and-approval.md](../05-execution-continuity-and-integrations/03-human-oversight-trust-and-approval.md)
- [07-claude-code-end-to-end-scenarios.md](../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)

## REPL은 view가 아니라 owner-facing runtime surface다

`src/screens/REPL.tsx`의 props와 local state를 보면, REPL은 메시지와 프롬프트만 다루는 component가 아니다. task list, remote session, direct connect, ssh session, agent definition, permission context, MCP state, transcript view, foregrounded task view를 한 surface에서 함께 다룬다.

```ts
export type Screen = 'prompt' | 'transcript';
...
const [mainThreadAgentDefinition, setMainThreadAgentDefinition] = useState(...)
const tasks = useAppState(s => s.tasks)
const viewingAgentTaskId = useAppState(s => s.viewingAgentTaskId)
const setAppState = useSetAppState()
```

이 구조가 뜻하는 바는 명확하다. operator는 REPL을 통해 단순히 "메시지를 읽는 것"이 아니라, 현재 세션이 어떤 owner 상태에 있는지 직접 본다.

- 어떤 agent definition이 foreground owner인지
- 어떤 background task를 보고 있는지
- 현재 prompt mode인지 transcript mode인지
- permission queue와 sandbox request가 쌓였는지

UI가 제어 표면이 되는 이유는 바로 이 ownership visibility 때문이다.

## transcript mode는 두 번째 화면이 아니라 같은 세션의 다른 절단면이다

`src/hooks/useGlobalKeybindings.tsx`는 transcript mode를 `ctrl+o`로 토글하고, `ctrl+e`로 show-all, `ctrl+c` 또는 `escape`로 exit하도록 설계한다.

```ts
const handleToggleTranscript = useCallback(() => {
  const isEnteringTranscript = screen !== 'transcript';
  logEvent('tengu_toggle_transcript', {
    is_entering: isEnteringTranscript,
    show_all: showAllInTranscript,
    message_count: messageCount
  });
  setScreen(s => s === 'transcript' ? 'prompt' : 'transcript');
  setShowAllInTranscript(false);
}, ...)
```

이 keybinding이 중요한 이유는 transcript가 별도 export나 audit log가 아니라, 같은 세션 상태를 다른 관찰자 관점으로 다시 펼친다는 점 때문이다. operator는 prompt 입력 surface와 transcript 관찰 surface를 오가며 현재 run을 통제한다.

따라서 transcript mode는 "예전 메시지 보기"가 아니라 다음 판단을 위한 operational mode다.

- 지금 무슨 일이 일어났는지 읽는다.
- compact boundary 뒤의 active context를 구분한다.
- permission prompt나 background task를 해석하는 근거로 쓴다.

## transcript는 별도 persistence substrate와 연결된다

`useLogMessages()`는 REPL의 message 배열을 transcript chain으로 incremental하게 기록한다.

```ts
// messages is append-only between compactions, so track where we left off
// and only pass the new tail to recordTranscript.
void recordTranscript(
  slice,
  ...,
  parentHint,
  messages,
)
```

이 hook이 중요한 이유는 REPL UI가 단순 렌더러가 아니라 transcript persistence의 producer이기도 하기 때문이다. UI state와 persistent evidence가 같은 흐름에서 이어지므로, operator가 보고 있는 표면과 recovery/analysis에 쓰이는 표면이 크게 어긋나지 않는다.

즉 transcript는 UI artifact이면서 동시에 execution artifact다.

## operator control은 permission dialog와 backgrounding에서 구체화된다

Claude Code는 operator 개입을 단순 "stop 버튼" 하나로 구현하지 않는다. `src/components/permissions/PermissionRequest.tsx`는 tool 종류에 따라 다른 permission component를 선택해 붙인다.

```ts
function permissionComponentForTool(tool: Tool): React.ComponentType<PermissionRequestProps> {
  switch (tool) {
    case FileEditTool:
      return FileEditPermissionRequest;
    case BashTool:
      return BashPermissionRequest;
    case ExitPlanModeV2Tool:
      return ExitPlanModePermissionRequest;
    ...
  }
}
```

즉 operator control은 generic modal 하나가 아니라, tool semantics에 맞춰 다르게 shaped된 intervention surface다.

backgrounding도 같은 맥락이다. `useSessionBackgrounding()`은 foregrounded local agent task의 메시지를 main view로 동기화하고, Ctrl+B로 background/foreground 전환을 처리한다.

```ts
if (foregroundedTaskId) {
  setAppState(prev => ({
    ...prev,
    foregroundedTaskId: undefined,
    tasks: {
      ...prev.tasks,
      [taskId]: { ...task, isBackgrounded: true },
    },
  }))
  setMessages([])
  ...
  return
}

onBackgroundQuery()
```

여기서 operator는 프로세스를 종료하지 않고도 "같은 세션 상태를 어떤 표면에서 볼 것인가"를 바꾼다. 이것이 바로 UI를 control surface로 읽어야 하는 이유다.

여기에 masking과 reversible action UX가 붙는다. transcript와 trace가 operator에게 보이는 순간, 민감한 input/output을 그대로 노출할지, 일부를 가린 상태에서 의사결정을 가능하게 할지 설계해야 한다. background task, remote action, destructive tool call은 취소와 되돌리기 가능성까지 같이 보여 줄 때 permission fatigue와 과신을 함께 줄일 수 있다.

## viewed transcript와 live owner를 분리하는 설계도 중요하다

REPL은 `viewingAgentTaskId`와 `retain`, `diskLoaded` 같은 state를 통해 "무엇을 보고 있는가"와 "어떤 task를 UI가 붙잡고 있는가"를 분리한다.

이 분리는 장기 실행형 하네스에서 중요하다.

- 보이는 transcript가 곧 foreground owner는 아니다.
- background task를 보고 있어도 세션 전체의 main owner는 여전히 REPL일 수 있다.
- retained local agent transcript는 disk bootstrap과 live append를 함께 필요로 한다.

즉 operator control의 품질은 버튼 수보다, viewed state와 live owner를 얼마나 잘 구분하느냐에 더 많이 달려 있다.

이 구분은 observability 장과도 맞닿아 있다. transcript만으로는 wait 이유, tool block, approval queue, cancellation point를 충분히 설명하지 못할 수 있다. 따라서 operator-facing UI 설명은 transcript, trace, run artifact adjacency를 함께 적는 편이 낫다.

## 관찰, 원칙, 해석, 권고

관찰:

- REPL은 prompt, transcript, permission, background task, remote/session state를 한 surface에서 다룬다.
- transcript mode는 별도 로그 뷰가 아니라 같은 세션 상태의 alternate cut이다.
- permission dialog와 backgrounding은 tool semantics와 task state에 맞춰 shaped된 operator intervention surface다.

원칙:

- UI는 하네스 바깥 껍질이 아니라 runtime state의 관찰 및 개입 계층이어야 한다.
- transcript는 persistence substrate와 연결돼야 운영 artifact로 기능한다.
- operator control은 generic modal이 아니라 domain-specific intervention surface들의 묶음이어야 한다.
- masking/redaction과 reversible control은 operator UI의 핵심 안전 장치다.

해석:

- Anthropic이 long-running harness에서 강조하는 operator legibility는 Claude Code에서 transcript mode, task foregrounding, permission request dispatch로 구현된다.
- NLAH 관점에서도 UI surface는 단순 편의 기능이 아니라 인간과 하네스 사이의 contract layer로 읽는 편이 맞다.

권고:

- 새 하네스를 설계할 때는 prompt view와 transcript view를 분리하되, 둘이 같은 session state를 공유한다는 사실을 유지하라.
- operator가 보는 surface와 persistence substrate가 완전히 따로 놀지 않게 설계하라.
- permission, backgrounding, transcript review를 한 세션의 서로 다른 모드로 읽히게 만들라.

## Review scaffold

- operator가 live run, viewed transcript, background task를 언제 서로 다른 surface로 만나는지 적어 보라.
- approval, cancel, resume, redact가 같은 control layer 안에서 어떻게 연결되는지 확인하라.
- transcript만으로 설명되지 않는 상태를 trace나 artifact가 어떻게 보완하는지 빠짐없이 적을 수 있어야 한다.

## benchmark 질문

1. transcript가 단순 scrollback이 아니라 operator control surface로 쓰이는가.
2. UI state와 persistent execution artifact가 서로 연결되는가.
3. permission, backgrounding, transcript review가 같은 session model 위에서 일관되게 동작하는가.
4. viewed state와 live owner를 구분해 설명할 수 있는가.

## 요약

Claude Code 사례에서 UI와 transcript는 하네스 외피가 아니다. 그것은 operator가 같은 세션 상태를 읽고, 개입하고, 다시 관찰하는 제어 표면이다. 이 구조를 이해해야 permission, background task, remote attach, resume가 모두 UI 장식이 아니라 execution design의 일부로 보인다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/screens/REPL.tsx`
   REPL이 어떤 state를 한 surface에 모으는지 먼저 본다.
2. `src/hooks/useGlobalKeybindings.tsx`
   transcript mode가 operator control로 어떻게 열리고 닫히는지 본다.
3. `src/hooks/useLogMessages.ts`
   UI message state가 transcript persistence로 어떻게 이어지는지 확인한다.
4. `src/components/permissions/PermissionRequest.tsx`
   tool-specific intervention surface가 어떻게 선택되는지 본다.
5. `src/hooks/useSessionBackgrounding.ts`
   background/foreground 전환이 같은 세션 상태를 어떻게 재배치하는지 확인한다.
