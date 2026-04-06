# Appendix. Root File Map

## 장 요약

이 부록은 원 upstream 공개 사본 source tree 루트 바로 아래에 놓인 루트 파일 18개를 범주별로 정리한다. top-level 디렉터리만 보면 놓치기 쉬운 조립 파일, 레지스트리 파일, 상태 모델 파일을 한 번에 보는 것이 목적이다.

이 부록은 "루트에 있는 조립 파일과 레지스트리 파일"만 빠르게 보고 싶을 때 우선 참고하는 표다. 디렉터리 전체 배치가 궁금하면 [directory-map.md](./directory-map.md), 핵심 발췌 provenance를 더 촘촘하게 보고 싶다면 [key-file-index.md](./key-file-index.md)가 더 적합하다.

이 표는 경로 목록이 아니라 semantic map으로 읽어야 한다. 각 행에서 먼저 `역할 요약`을, 그다음 `대표 발췌 포인트`를 읽고, 마지막에 파일 라벨을 provenance 메모로 붙이면 source 없이도 의미가 닫힌다. 파일 라벨은 원 upstream 공개 사본의 `src/` 기준 provenance를 따른다.

## 대표 코드 발췌

```ts
profileCheckpoint('main_tsx_entry');
startMdmRawRead();
startKeychainPrefetch();
```

이 발췌는 `src/main.tsx`가 왜 루트 조립 파일로 분류되는지 보여 준다. 루트 파일은 단순 진입점이 아니라 startup 비용, side-effect, orchestration을 먼저 여는 자리다.

## 범주

### 1. Runtime 조립과 launch 파일

| 근거 라벨 | 역할 요약 | 관련 장 | 대표 발췌 포인트 | 주의할 점 |
| --- | --- | --- | --- | --- |
| `src/main.tsx` | 공통 초기화와 launch orchestration의 중심 | `02`, `03`, `04` | import 상단의 side-effect와 `main()` 흐름 | 파일이 매우 크고 feature gate가 많아 장별 절단면으로 읽어야 한다 |
| `src/setup.ts` | Ink root 생성 전 preflight startup 허브 | `03`, `04`, `13` | preflight helper와 startup sequencing | 화면 렌더링보다 먼저 일어나는 작업이 많다 |
| `src/interactiveHelpers.tsx` | onboarding, trust, approval dialog 허브 | `04` | `showSetupScreens()` | bypass permissions와 trust boundary는 다른 경계다 |
| `src/replLauncher.tsx` | `<App><REPL /></App>` mount helper | `03`, `09` | `launchRepl()` | 단순 wrapper처럼 보여도 REPL entry surface를 고정한다 |
| `src/dialogLaunchers.tsx` | assistant, resume, teleport 관련 dialog mount helper | `03`, `15` | launch 함수 군 | 여러 보조 대화상자의 진입점을 묶는다 |

### 2. Core runtime 모델과 엔진 파일

| 근거 라벨 | 역할 요약 | 관련 장 | 대표 발췌 포인트 | 주의할 점 |
| --- | --- | --- | --- | --- |
| `src/context.ts` | system/user context 조립 | `05` | `getGitStatus()`, `getSystemContext()`, `getUserContext()` | memoize 기반 snapshot이라는 점이 중요하다 |
| `src/query.ts` | interactive query orchestration | `05`, `06` | `query()`, `queryLoop()` | `src/QueryEngine.ts` 없이도 핵심 pipeline이 이미 여기에 있다 |
| `src/QueryEngine.ts` | SDK/headless conversation 상태와 turn lifecycle | `06` | `QueryEngine` constructor, `submitMessage()` | REPL 경로와 1:1로 동일한 실행 경로는 아니다 |
| `src/history.ts` | 입력 history와 pasted content ref 보조 저장소 | `09`, `13` | history 저장/복원 관련 함수 | transcript와 같은 개념으로 읽으면 안 된다 |
| `src/projectOnboardingState.ts` | project-level onboarding 상태 | `04`, `13` | onboarding state read/write 지점 | global first-run onboarding과 구분해야 한다 |

### 3. Surface registry와 공통 인터페이스 파일

| 근거 라벨 | 역할 요약 | 관련 장 | 대표 발췌 포인트 | 주의할 점 |
| --- | --- | --- | --- | --- |
| `src/commands.ts` | slash command registry | `07` | command registration 구조 | `commands/` 디렉터리 구현과 구분해서 읽어야 한다 |
| `src/tools.ts` | tool registry와 helper | `08` | `getTools()` | `src/Tool.ts` 인터페이스와 실제 구현을 연결하는 허브다 |
| `src/tasks.ts` | task registry와 helper | `12` | task creation/registry helper | `src/Task.ts` 타입 정의와 함께 읽어야 한다 |
| `src/Tool.ts` | tool 공통 타입과 인터페이스 | `08` | `findToolByName()`, type 정의 | permission과 실행은 여기서 완성되지 않는다 |
| `src/Task.ts` | task 공통 타입과 인터페이스 | `12` | task base type | 실제 lifecycle은 [12-task-model-and-background-execution.md](../12-task-model-and-background-execution.md)의 registry/lifecycle 설명으로 보완된다 |

### 4. UI와 persistence 보조 파일

| 근거 라벨 | 역할 요약 | 관련 장 | 대표 발췌 포인트 | 주의할 점 |
| --- | --- | --- | --- | --- |
| `src/ink.ts` | theme-aware render/createRoot facade | `09` | Ink export와 render helper | 단순 re-export보다 런타임 facade 성격이 있다 |
| `src/cost-tracker.ts` | usage/cost 누적과 복원 | `13` | usage/cost aggregation helper | query/runtime 전반과 연결되지만 persistence 관점이 더 중요하다 |
| `src/costHook.ts` | 종료 시 cost 저장과 요약 출력 hook | `13` | exit hook 성격의 함수 | runtime path에 끼어드는 persistence helper다 |

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 부록의 표에서 어떤 범주를 먼저 읽으면 의미가 가장 빨리 닫히는지 보여 주는 provenance 메모다.

### 전체 runtime 조립을 보고 싶을 때

1. `src/main.tsx`
2. `src/setup.ts`
3. `src/interactiveHelpers.tsx`
4. `src/replLauncher.tsx`
5. `src/dialogLaunchers.tsx`

### 모델 호출 경로를 보고 싶을 때

1. `src/context.ts`
2. `src/query.ts`
3. `src/QueryEngine.ts`

### 사용자가 건드리는 surface를 보고 싶을 때

1. `src/commands.ts`
2. `src/tools.ts`
3. `src/tasks.ts`
4. `src/Tool.ts`
5. `src/Task.ts`

## 관련 부록

- top-level 디렉터리 대응은 [directory-map.md](./directory-map.md)
- 핵심 파일 요약 인덱스는 [key-file-index.md](./key-file-index.md)
