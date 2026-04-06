# 02. task, trial, transcript, outcome, grader

## 장 요약

평가 용어를 흐리게 쓰면 하네스 평가도 흐려진다. 특히 `task`, `trial`, `transcript`, `outcome`, `grader`를 한데 뭉개면 무엇을 비교하는지, 무엇을 반복 실행하는지, 무엇을 판정하는지조차 설명하기 어려워진다. Claude Code의 로컬 코드에는 이 다섯 단위를 직접 구현한 단일 프레임워크는 없지만, 각각을 구성하는 runtime artifact는 분명히 존재한다. 이 장은 그 artifact를 evaluation 언어에 대응시켜 읽는 법을 정리한다.

## 범위와 비범위

이 장이 다루는 것:

- evaluation vocabulary와 local runtime artifact 사이의 대응 관계
- Claude Code에서 transcript/outcome/judge input이 어디서 만들어지는지
- grader가 first-class object로 없을 때도 evaluation 구조를 어떻게 세울 수 있는지

이 장이 다루지 않는 것:

- grading model 자체의 prompt 설계 세부
- 외부 벤치마크 harness의 샘플러/큐/DB 설계 전부
- human labeler 운영 프로세스의 조직적 측면
- contamination 분석과 dataset versioning 운영 세부

이 장은 [01-model-evals-vs-harness-evals.md](01-model-evals-vs-harness-evals.md) 위에서 읽는 것이 좋고, [04-production-traces-feedback-loops-and-optimization.md](04-production-traces-feedback-loops-and-optimization.md), [09-eval-hygiene-dataset-versioning-and-contamination.md](09-eval-hygiene-dataset-versioning-and-contamination.md), [03-references.md](../00-front-matter/03-references.md)로 이어진다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/Task.ts`
- `src/QueryEngine.ts`
- `src/hooks/useLogMessages.ts`
- `src/utils/sessionStorage.ts`
- `src/services/diagnosticTracking.ts`
- `src/services/toolUseSummary/toolUseSummaryGenerator.ts`
- `src/screens/REPL.tsx`

외부 프레이밍:

- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), 2026-01-09
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps), 2026-03-24
- Pan et al., [Natural-Language Agent Harnesses](https://arxiv.org/abs/2603.25723), 2026-03-26, under review

함께 읽으면 좋은 장:

- [01-model-evals-vs-harness-evals.md](01-model-evals-vs-harness-evals.md)
- [03-benchmarking-coding-harnesses.md](03-benchmarking-long-running-agent-harnesses.md)
- [02-task-orchestration-and-long-running-execution.md](../05-execution-continuity-and-integrations/02-task-orchestration-and-long-running-execution.md)
- [06-claude-code-task-model-and-background-execution.md](../05-execution-continuity-and-integrations/06-claude-code-task-model-and-background-execution.md)

## evaluation vocabulary를 local artifact에 매핑하기

| 평가 용어 | evaluation에서의 뜻 | Claude Code에서 가장 가까운 로컬 artifact | 읽을 때의 주의점 |
| --- | --- | --- | --- |
| task | 해결하려는 일 단위 | `TaskStateBase` 또는 한 번의 user request family | 제품의 runtime task와 benchmark task는 완전히 같은 뜻이 아니다 |
| trial | 같은 task의 한 번의 실행 | 한 세션/한 query chain의 run | REPL trial과 SDK trial은 owner가 다르다 |
| transcript | trial에서 발생한 상호작용 기록 | `useLogMessages()` + `recordTranscript()`가 만든 message chain | UI scrollback과 evaluation transcript를 혼동하지 말아야 한다 |
| outcome | trial의 판정 대상 결과 | QueryEngine result packet + cost/usage + denial + diagnostics | pass/fail만이 아니라 friction과 economics를 포함해야 한다 |
| grader | transcript/outcome을 판정하는 기준 또는 기계 | diagnostics summary, tests, rubric, human feedback survey, offline judge prompt | 현재 코드에는 generic `Grader` 타입이 first-class로 존재하지 않는다 |

이 표의 핵심은 evaluation vocabulary가 제품 코드에 1:1로 대응된다는 뜻이 아니라, 제품 코드가 evaluation vocabulary를 구성할 재료를 충분히 드러낸다는 뜻이다.

## task는 제품 용어와 평가 용어가 정확히 겹치지 않는다

`src/Task.ts`는 background/local/remote workflow를 위한 runtime task state를 정의한다.

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

평가 문맥에서 `task`는 흔히 benchmark prompt나 scenario specification을 뜻한다. 반면 Claude Code의 `TaskStateBase`는 이미 실행 중인 background work unit이다. 이 둘은 다르지만, 바로 그 차이를 문서화해야 한다.

- benchmark task는 "무엇을 풀게 할 것인가"를 정한다.
- runtime task는 "그 풀이가 장기 실행 동안 어떤 artifact와 lifecycle을 가지는가"를 드러낸다.

출판용 evaluation 문서라면 이 둘을 같은 단어로 뭉개지 않고, benchmark spec과 runtime task artifact를 나란히 적어야 한다.

## trial은 한 번의 run이며 owner를 포함한다

Claude Code에서 trial에 가장 가까운 단위는 QueryEngine이나 REPL이 실제로 한 번의 query chain을 수행한 run이다. QueryEngine result packet은 그 run의 session ID, turn count, cost, usage, permission denial을 outcome 쪽으로 밀어 넣는다.

```ts
yield {
  type: 'result',
  subtype: 'success',
  duration_ms: Date.now() - startTime,
  num_turns: turnCount,
  session_id: getSessionId(),
  total_cost_usd: getTotalCost(),
  usage: this.totalUsage,
  permission_denials: this.permissionDenials,
  ...
}
```

같은 prompt를 써도 REPL owner와 SDK owner가 다르면 trial의 shape가 달라질 수 있다. इसलिए trial 정의에는 최소한 다음이 들어가야 한다.

- owner: REPL, SDK, background agent
- runtime condition: feature flags, permission mode, remote/local
- outcome packet: 성공/실패뿐 아니라 denial, cost, turns

## transcript는 "보이는 기록"이 아니라 grader 입력이 될 수 있어야 한다

`useLogMessages()`는 UI가 가진 메시지 배열을 transcript chain으로 옮긴다. 이때 단순 dump가 아니라 compaction, rewind, tombstone, parent hint까지 고려해 append-only chain을 관리한다.

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

좋은 evaluation transcript는 두 조건을 만족해야 한다.

1. 사람이나 grader가 나중에 읽을 수 있어야 한다.
2. run을 다시 재구성할 수 있는 chain semantics를 가져야 한다.

Claude Code transcript는 이 둘을 동시에 노린다. 그래서 transcript는 단순 logging artifact가 아니라 evaluation input 후보가 된다.

## outcome은 pass/fail보다 풍부해야 한다

`outcome`을 success boolean 하나로 줄이면 harness 개선이 멈춘다. Claude Code는 최소한 네 가지 층의 outcome 재료를 남긴다.

1. QueryEngine result packet  
   turn count, total cost, usage, denial, stop reason
2. diagnostics  
   `DiagnosticTrackingService.formatDiagnosticsSummary()`는 파일별 diagnostic delta를 사람이 읽을 수 있는 요약으로 만든다.
3. transcript  
   operator-visible interaction과 interruption, retry, compact 흔적을 남긴다.
4. human feedback  
   REPL은 feedback survey, post-compact survey, memory survey를 별도 흐름으로 가진다.

```ts
static formatDiagnosticsSummary(files: DiagnosticFile[]): string {
  ...
  return `${filename}:\n${diagnostics}`
}
```

```ts
const feedbackSurveyOriginal = useFeedbackSurvey(messages, isLoading, submitCount, 'session', hasActivePrompt)
const postCompactSurvey = usePostCompactSurvey(messages, isLoading, hasActivePrompt, ...)
const memorySurvey = useMemorySurvey(messages, isLoading, hasActivePrompt, ...)
```

이런 outcome 구조가 있으면 "성공했는가"보다 더 유용한 질문이 가능해진다. 예를 들어 "성공은 했지만 permission friction이 높았는가", "성공했지만 diagnostics가 늘었는가", "성공했지만 비용이 과도했는가" 같은 질문이다.

## grader는 현재 코드에서 분산된 역할이다

publication-grade 설명에서 특히 중요한 점은, 현재 코드베이스에 generic `Grader` 타입이나 `gradeTrial()` 함수가 first-class surface로 존재하지 않는다는 사실을 정직하게 적는 것이다. 대신 grader 역할은 분산돼 있다.

- diagnostics summary는 static-analysis grader input이다.
- transcript는 human or model grader input이다.
- tool use summary generator는 run을 더 읽기 쉽게 압축하는 labeler다.
- feedback survey는 explicit human judgment를 받는 장치다.

```ts
const TOOL_USE_SUMMARY_SYSTEM_PROMPT = `Write a short summary label describing what these tool calls accomplished...`
```

따라서 Claude Code 사례를 통해 배워야 할 것은 "grader가 이미 구현돼 있다"가 아니라, "grader를 붙일 수 있는 structured input이 충분히 드러나 있다"는 점이다.

## grader input, grading rule, evaluator persona를 분리하라

publication-grade evaluation 설명에서 자주 빠지는 것이 하나 더 있다. grader를 하나의 블랙박스로 적어 버리면, 실제로 무엇이 input이고 무엇이 rule이며 무엇이 persona인지 구분되지 않는다. Anthropic의 2026-03-24 글은 이 셋을 분리해 적는 편이 왜 중요한지 잘 보여 준다.

- grader input: transcript, diagnostics, 실행 중 생성된 artifact, live app inspection 결과
- grading rule: criteria, threshold, fail condition, contract
- evaluator persona: skeptical QA인지, forgiving reviewer인지, design critic인지

이 셋이 분리돼야 grader drift의 원인을 추적할 수 있다. input이 부족한지, rule이 흐린지, evaluator persona가 너무 관대한지 서로 다른 문제를 따로 고칠 수 있기 때문이다.

## skeptical evaluator와 self-grading의 차이

같은 모델이 generator와 evaluator 역할을 모두 수행할 수는 있다. 그러나 self-grading은 구조적으로 lenient해지기 쉽다. agent는 자기가 방금 만든 산출물의 맥락을 가장 잘 알고 있지만, 동시에 그 산출물을 변호할 유인도 강하게 갖는다.

Anthropic의 글은 바로 이 점을 harness problem으로 읽는다.

- generator가 자기 worklog를 설명하는 일
- evaluator가 skeptical하게 fail condition을 적용하는 일

이 둘은 겉보기에는 가까워 보여도 운영상 다른 역할이다. 따라서 grader 설명에서는 "누가 채점하는가"만이 아니라 "그 evaluator가 generator와 어떤 관계인가"를 함께 적는 편이 맞다.

## criteria, threshold, sprint contract는 grader 설계 단위다

grader를 모델 하나로 환원하면 contract와 threshold가 문서에서 사라지기 쉽다. 그러나 실제 long-running harness에서는 grading unit이 더 잘게 나뉜다.

- criteria: 무엇을 볼 것인가
- threshold: 얼마나 잘해야 통과인가
- sprint contract: 이번 chunk에서 무엇을 done으로 볼 것인가

즉 grading은 run이 끝난 뒤 transcript만 읽는 일이 아니라, 그 전에 contract를 세우고 그 contract를 기준으로 통과 여부를 판정하는 구조일 수 있다. grader vocabulary를 문서화할 때는 이 upstream layer도 함께 적는 편이 정확하다.

## 왜 이 구분이 중요한가

평가 문서를 쓸 때 가장 흔한 오류는 다음이다.

- task와 trial을 섞어 "같은 문제를 여러 번 실행했다"는 사실이 사라진다.
- transcript와 outcome을 섞어 "무슨 일이 있었는지"와 "어떻게 판정할지"가 섞인다.
- grader를 누락해 결과 해석 기준이 암묵적이 된다.

이 세 오류는 모두 개선 우선순위를 흐리게 만든다. 예를 들어 transcript는 길고 상세한데 outcome이 빈약하면 grading이 불안정해지고, outcome은 풍부한데 trial 조건이 기록되지 않으면 비교가 무의미해진다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 task, transcript, outcome에 해당하는 artifact를 이미 여러 층으로 남긴다.
- generic grader object는 없지만 diagnostics, transcript, surveys, summary label이 grader input 후보를 이룬다.
- owner와 runtime condition이 trial 정의에 직접 들어가야 한다.

원칙:

- evaluation vocabulary는 반드시 local artifact로 다시 매핑돼야 한다.
- grader가 명시적 객체로 없더라도 grading input과 grading rule은 분리해서 적어야 한다.
- outcome은 pass/fail보다 friction, cost, diagnostic delta, human judgment를 함께 가져야 한다.
- evaluator persona와 grading rule을 같은 것으로 취급하지 말아야 한다.

해석:

- Anthropic의 eval language는 이 코드베이스에서 별도 eval module이 아니라 runtime artifact 조합으로 드러난다.
- Natural-Language Agent Harnesses가 말하는 durable artifact는 transcript/outcome/grader input 분리를 통해 더 명확하게 읽힌다.

권고:

- 새로운 harness를 문서화할 때는 `task -> trial -> transcript -> outcome -> grader` 표를 먼저 만든 뒤, 각 칸에 실제 artifact를 채워 넣어라.
- `grader`가 없으면 없다고 적고, 무엇이 grading input 후보인지 정직하게 분리하라.
- transcript와 outcome을 같은 JSON blob에 넣더라도 독자에게는 서로 다른 역할로 설명하라.
- grader를 적을 때는 input, rule, persona, contract를 최소한 따로 적어라.
- task spec와 dataset version, grader version을 같이 남겨 evaluator drift를 나중에 추적할 수 있게 하라.

## benchmark 질문

1. 이 시스템은 task와 trial을 명시적으로 구분할 수 있는가.
2. transcript가 replay evidence이자 grader input으로 사용될 수 있는가.
3. outcome이 pass/fail보다 풍부한가.
4. grader가 first-class object가 아니라면, 무엇이 grading input이고 무엇이 grading rule인지 분리해 설명할 수 있는가.

## 요약

task, trial, transcript, outcome, grader는 evaluation을 설명하는 최소 단위다. Claude Code는 이 다섯 단위를 한 모듈 안에 담고 있지 않지만, 각각에 해당하는 artifact를 충분히 노출한다. publication-grade 문서는 바로 이 대응 관계를 명확히 적어야 하며, 그래야 평가 결과가 실제 개선 작업과 연결된다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/Task.ts`
   runtime task가 평가 task와 어떻게 다르고 어디서 연결되는지 본다.
2. `src/QueryEngine.ts`
   trial outcome packet을 확인한다.
3. `src/hooks/useLogMessages.ts`
   transcript가 어떤 규칙으로 누적되는지 본다.
4. `src/utils/sessionStorage.ts`
   transcript chain이 replay evidence로 어떻게 유지되는지 확인한다.
5. `src/services/diagnosticTracking.ts`
   diagnostics가 grader input 후보로 어떻게 포맷되는지 본다.
6. `src/screens/REPL.tsx`
   human feedback surface를 확인한다.
7. `src/services/toolUseSummary/toolUseSummaryGenerator.ts`
   run 요약이 어떻게 label 형태로 생성되는지 비교한다.
