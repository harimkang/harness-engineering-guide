# 02. 워크플로, 에이전트, 런타임, 하네스

> Why this chapter exists: workflow, agent, runtime, harness, eval harness를
> 같은 말처럼 쓰지 않도록 좌표계를 고정하고, instruction surface와 deployment
> family가 이 구분을 어떻게 보조하는지 설명한다.
> Reader level: beginner / advanced / reviewer
> Last verified: 2026-04-06
> Freshness class: stable
> Verified canonical registry sources: `S1`, `S4`, `S7`, `S21`, `S24`

## Core claim

하네스 엔지니어링 문서를 읽을 때 가장 먼저 생기는 혼란은 `workflow`,
`agent`, `runtime`, `harness`, `eval harness`가 같은 말처럼 섞인다는 점이다.
이 장의 목적은 완벽한 사전식 정의를 주는 것이 아니라, 시스템을 읽을 때 어떤
질문을 어디에 던져야 하는지 고정하는 데 있다.

`S1`은 workflow와 agent를 구분해 가장 단순한 시스템에서 출발하라고 말한다.
`S21`은 agent SDK를 additional context, tools, handoffs, streaming, full
trace를 가진 실행 구조로 설명한다. `S7`은 task, trial, transcript, grader가
production harness와 eval harness를 다른 층으로 만든다는 점을 보여 준다.
이 세 source를 합치면, 다섯 용어는 기능 이름이 아니라 귀속점 표가 된다.

## What this chapter is not claiming

- 이 용어들에 하나의 절대 정의만 존재한다는 주장
- 외부 SDK 용어와 이 책의 용어가 1:1로 대응한다는 주장
- instruction surface나 deployment family가 다섯 용어를 대체한다는 주장

## 다섯 핵심 용어

| 용어 | 핵심 질문 | 대표 artifact |
| --- | --- | --- |
| workflow | 무엇이 어떤 순서로 일어나는가 | task list, sprint contract, handoff sequence |
| agent | 누가 다음 행동을 고르고 tool을 쓰는가 | instructions, tool calls, handoff decision |
| runtime | 그 agent가 어떤 owner-facing 환경에서 실행되는가 | REPL, SDK runner, background worker |
| harness | workflow와 runtime, tools, permissions, memory, operator control을 묶는 운영 시스템은 무엇인가 | transcript, trace, policy surface, task artifact |
| eval harness | 위 시스템을 반복 가능하게 비교하고 채점하는 구조는 무엇인가 | trial record, grader criteria, outcome artifact |

이 표가 중요한 이유는 용어를 외우기 위해서가 아니라, 지금 보는 문제가 절차
문제인지, decision loop 문제인지, 실행 환경 문제인지, 운영 시스템 문제인지,
비교 시스템 문제인지 빠르게 나누기 위해서다.

## workflow와 agent를 먼저 분리하라

workflow는 "무엇이 먼저 일어나고 무엇이 다음에 오는가"를 다루는 언어다.
agent는 "누가 무엇을 보고 다음 행동을 결정하는가"를 다루는 언어다.

둘을 섞으면 흔히 다음 오해가 생긴다.

- task 분해 실패를 모델 reasoning 실패로만 본다.
- tool permission 대기를 workflow stall이 아니라 agent weakness로만 읽는다.
- handoff design 실패를 prompt quality 문제로만 번역한다.

`S1`의 핵심 교훈은 agentic complexity를 늘리기 전에 workflow를 먼저 단순하게
설계하라는 것이다. 이는 곧 "순서의 문제"와 "판단 주체의 문제"를 먼저 분리해
보라는 뜻이다.

## runtime은 owner와 deployment family의 문제다

runtime은 agent loop가 실제로 어떤 owner-facing 환경에서 굴러가는가를 묻는
언어다. 같은 agent라도 deployment family가 달라지면 관찰성, latency budget,
human oversight, recovery path가 달라진다.

대표 deployment family는 아래처럼 나눌 수 있다.

| deployment family | 대표 특징 | 먼저 보는 artifact |
| --- | --- | --- |
| interactive runtime | operator가 즉시 개입하고 transcript를 바로 본다 | UI transcript, approval queue, command surface |
| headless SDK runtime | API or service owner가 run을 호출하고 결과를 수집한다 | run config, trace, result object |
| long-running worker runtime | 백그라운드 작업, handoff, flush, delayed review가 중요하다 | task record, handoff note, trace export |

`S21`과 `S22`는 SDK run이 full trace와 handoff-aware execution을 남길 수 있음을
보여 준다. 그래서 runtime 구분은 UI가 있느냐 없느냐보다 owner, deployment,
artifact retention이 어떻게 달라지는가를 중심으로 읽는 편이 정확하다.

## instruction/configuration surface는 보조 구분이다

같은 runtime과 같은 agent라도, 어떤 instruction surface가 깔렸는지에 따라
실제 행동은 크게 달라진다. 이 책에서는 instruction/configuration surface를
다섯 용어를 대체하는 여섯 번째 명사로 쓰기보다, 나머지 층을 가로지르는 보조
구분으로 둔다.

대표 surface는 아래와 같다.

- repo-level rules와 local instructions
- run config와 model/tool settings
- tool schema와 permission policy
- evaluator contract와 done criteria
- handoff artifact 안에 포함된 next-step instructions

`S24`의 `AGENTS.md` 가이드는 repo-level instruction surface가 실제 실행을
형성한다는 점을 명시적으로 보여 준다. `S4`도 context engineering이 단지 긴
대화를 쌓는 일이 아니라, 어떤 정보를 언제 어떤 형태로 agent에게 주는가의
문제라고 본다. 따라서 instruction surface는 context와 control, evaluation을
모두 가로지르는 설명면이다.

## harness는 왜 더 넓은 언어인가

harness는 workflow, agent, runtime을 묶은 뒤, 그 위에 tools, permissions,
memory, observability, economics, reviewability를 얹은 전체 운영 시스템을
가리킨다. 이 책에서 harness라는 단어를 쓸 때는 최소한 아래를 함께 떠올리는
편이 맞다.

- 어떤 workflow가 돌고 있는가
- 어떤 agent가 어떤 instruction surface 아래서 행동하는가
- 어떤 runtime / deployment family가 그것을 실행하는가
- 어떤 tool, policy, memory, trace, grader artifact가 이를 둘러싸는가

즉 harness는 "모델이 일하는 환경 전체"에 가깝다.

## eval harness는 실행 시스템이 아니라 비교 시스템이다

production harness는 실제 사용자나 operator가 일하는 환경이다. eval harness는
그 환경을 비교 가능한 task, trial, transcript, grader 구조로 묶는 시험
시스템이다.

`S7`은 eval harness를 stable environment, isolated trial, transcript,
grader, production monitoring과 함께 설명한다. 따라서 eval harness를 단순한
테스트 스크립트로 축소하면 안 된다. 그것은 비교 가능한 입력, 실행, artifact,
판정 규칙을 동시에 설계하는 구조다.

## Design implications

- 문서를 쓸 때는 먼저 지금 설명하는 층이 workflow인지 agent인지 runtime인지
  harness인지 eval harness인지 적어 두는 편이 좋다.
- deployment family를 적지 않으면 runtime 차이가 잘 보이지 않는다.
- instruction/configuration surface를 적지 않으면 같은 agent가 왜 다른 결과를
  냈는지 설명하기 어렵다.
- eval harness는 production harness를 복사하는 것이 아니라, 비교 가능한
  artifact를 추가로 조직하는 층이라고 보는 편이 정확하다.

## What to measure

- workflow 단계별 handoff completeness
- runtime family별 trace visibility와 approval latency
- instruction surface drift가 결과에 미친 영향
- eval harness에서 isolated trial 재현 성공률

## Failure signatures

- workflow 문제인데 agent capability 문제로만 논의한다.
- deployment family가 다른 두 run을 같은 runtime으로 취급한다.
- instruction surface 차이를 빼고 결과 차이를 설명하려 한다.
- production harness artifact와 eval harness artifact를 같은 것으로 본다.

## Review questions

1. 지금 설명하는 문제는 workflow, agent, runtime, harness, eval harness 중 어느 층인가.
2. deployment family가 달라졌을 때 owner와 artifact retention도 함께 달라지는가.
3. 같은 runtime에서도 instruction/configuration surface가 바뀌면 어떤 결과 차이가 나는가.
4. eval harness가 production harness와 구분되는 이유를 artifact 수준에서 설명할 수 있는가.

## Sources / evidence notes

- `S1`은 workflow와 agent를 구분해 가장 단순한 시스템에서 출발하라고 말한다.
- `S4`는 context engineering이 어떤 정보를 어떤 형태로 model-visible set에
  올릴지의 문제라고 본다. instruction surface 설명의 보조 근거다.
- `S21`은 agent SDK를 context, tools, handoffs, streaming, full-trace를 가진
  실행 구조로 설명한다. runtime과 deployment family 구분의 근거다.
- `S24`는 repo-level instruction surface가 실행 결과를 형성함을 보여 준다.
- `S7`은 task, trial, transcript, grader, stable environment를 통해 eval
  harness를 production harness와 구분한다.
