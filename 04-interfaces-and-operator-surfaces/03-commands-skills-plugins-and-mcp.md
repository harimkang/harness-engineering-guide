# 03. command, skill, plugin, MCP를 하나의 확장 언어로 읽기

## 장 요약

확장 표면을 이해하려면 command, tool, skill, plugin, MCP를 따로따로 외우기보다 "세션에 capability가 들어오는 서로 다른 문법"으로 읽는 편이 낫다. Claude Code는 이 문법을 꽤 선명하게 드러낸다. `src/commands.ts`는 로컬 command source를 조립하고, `src/skills/loadSkillsDir.ts`는 markdown guidance를 prompt command로 승격하며, `src/services/mcp/client.ts`는 외부 프로토콜에서 tools/commands/skills/resources를 끌어오고, `ToolSearchTool`은 deferred capability를 다시 discover하게 만든다.

## 범위와 비범위

이 장이 다루는 것:

- command, skill, plugin, MCP를 capability ingress surface로 읽는 법
- local source와 remote source가 세션 표면에 어떻게 합류하는지
- remote MCP skill이 왜 일반 file-based skill과 다른 security rule을 갖는지

이 장이 다루지 않는 것:

- 개별 slash command의 기능 카탈로그
- 특정 plugin manifest 포맷 전체
- MCP transport와 auth 구현 전부
- settings scope, `CLAUDE.md`, hooks, CLI system prompt flags, subagent precedence

이 장은 interfaces 파트의 확장 surface 장이며, [01-tool-contracts-and-the-agent-computer-interface.md](01-tool-contracts-and-the-agent-computer-interface.md)와 [02-tool-shaping-permissions-and-capability-exposure.md](02-tool-shaping-permissions-and-capability-exposure.md) 위에서 읽는 것이 좋다.
또한 아래 구분은 현재 공개 build에서 확인 가능한 packaging semantics를 기준으로 하며, built-in plugin, marketplace plugin, bundled skill의 경계는 추후 packaging 변화와 함께 다시 확인해야 한다. settings precedence와 startup-time instruction stack은 [09-instruction-surfaces-settings-hooks-claude-md-subagents.md](09-instruction-surfaces-settings-hooks-claude-md-subagents.md)에서 별도로 다룬다.

## 자료와 독서 기준

대표 발췌 출처:

- `src/commands.ts`
- `src/skills/loadSkillsDir.ts`
- `src/skills/bundledSkills.ts`
- `src/services/mcp/client.ts`
- `src/tools/ToolSearchTool/ToolSearchTool.ts`
- `src/services/mcp/MCPConnectionManager.tsx`

외부 프레이밍:

- Anthropic, [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system), 2025-06-13
- Anthropic, [Writing effective tools for agents — with agents](https://www.anthropic.com/engineering/writing-tools-for-agents), 2025-09-11
- Anthropic Platform Docs, [Agent SDK overview](https://platform.claude.com/docs/en/agent-sdk/overview), 확인 2026-04-02

Sources / evidence notes:
이 장의 reader-facing 외부 검증 축은 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 Part 4 cluster를 따른다. 핵심 source ID는 `S3`, `S9`, `S10`, `S11`, `S12`, `S14`, `S15`, `S16`, `S17`, `S18`, `S19`, `S20`, `S25`다. `S2`는 shared tooling과 orchestration substrate를 설명하는 보조 비교 프레임으로만 사용한다.

함께 읽으면 좋은 장:

- [01-tool-contracts-and-the-agent-computer-interface.md](01-tool-contracts-and-the-agent-computer-interface.md)
- [04-benchmarking-tool-surfaces.md](04-benchmarking-tool-surfaces.md)
- [../11-agent-skill-plugin-mcp-and-coordination.md](../05-execution-continuity-and-integrations/05-claude-code-agent-skill-plugin-mcp-and-coordination.md)

## capability ingress 문법을 구분하라

| surface | 누가 주로 소비하는가 | 무엇을 세션에 추가하는가 |
| --- | --- | --- |
| command | operator | slash-driven steering surface |
| tool | model | structured capability contract |
| skill | operator와 모델 모두 | prompt-style guidance command |
| plugin | 배포/구성 관리자 | 여러 capability source의 bundle metadata |
| MCP | remote server와 local session 사이 | 외부 tools, commands, skills, resources |

이 표의 핵심은 provenance다. capability가 어디서 왔고, 누가 그것을 먼저 소비하며, 세션 안에서 어떤 형태로 보이는지가 다르다.

## commands.ts는 여러 local source를 한 slash surface로 합친다

`src/commands.ts`는 skills, plugin commands, workflow commands, built-in commands를 memoized aggregation seam에서 합친다.

```ts
const [
  { skillDirCommands, pluginSkills, bundledSkills, builtinPluginSkills },
  pluginCommands,
  workflowCommands,
] = await Promise.all([
  getSkills(cwd),
  getPluginCommands(),
  getWorkflowCommands ? getWorkflowCommands(cwd) : Promise.resolve([]),
])

return [
  ...bundledSkills,
  ...builtinPluginSkills,
  ...skillDirCommands,
  ...workflowCommands,
  ...pluginCommands,
  ...pluginSkills,
  ...COMMANDS(),
]
```

이 구조는 command surface가 단일 폴더나 단일 registry가 아니라는 점을 보여 준다. 사용자 입장에서는 모두 slash command처럼 보이지만, provenance는 file-based skill, bundled skill, plugin, workflow, builtin command로 서로 다르다.

## skill은 markdown을 prompt command로 승격한 surface다

`src/skills/loadSkillsDir.ts`의 `createSkillCommand()`는 skill을 `type: 'prompt'` command로 만든다. 이 command는 allowed tools, execution context, model, effort, hooks, paths, base directory 같은 추가 metadata를 가진다.

```ts
return {
  type: 'prompt',
  name: skillName,
  description,
  allowedTools,
  whenToUse,
  model,
  disableModelInvocation,
  userInvocable,
  context: executionContext,
  agent,
  effort,
  paths,
  ...
  async getPromptForCommand(args, toolUseContext) {
    ...
  },
}
```

즉 skill은 단순 문서가 아니다. 그것은 prompt-style guidance를 command surface로 승격한 capability ingress surface다.

## MCP skill은 local skill과 같은 신뢰 모델이 아니다

`src/skills/loadSkillsDir.ts`는 remote MCP skill에 대해 별도 security rule을 둔다.

```ts
// Security: MCP skills are remote and untrusted — never execute inline
// shell commands (!`…` / ```! … ```) from their markdown body.
if (loadedFrom !== 'mcp') {
  finalContent = await executeShellCommandsInPrompt(...)
}
```

이 한 줄이 중요한 이유는 skill surface도 provenance에 따라 신뢰 모델이 달라진다는 점을 보여 주기 때문이다. file-based local skill과 remote MCP skill은 둘 다 prompt command처럼 보이지만, inline shell execution 허용 여부는 다르다.

## MCP는 tool만이 아니라 commands, skills, resources를 함께 싣는다

`src/services/mcp/client.ts`는 연결된 client에 대해 tools, commands, skills, resources를 병렬로 가져온다.

```ts
const [tools, mcpCommands, mcpSkills, resources] = await Promise.all([
  fetchToolsForClient(client),
  fetchCommandsForClient(client),
  feature('MCP_SKILLS') && supportsResources
    ? fetchMcpSkillsForClient!(client)
    : Promise.resolve([]),
  supportsResources ? fetchResourcesForClient(client) : Promise.resolve([]),
])
const commands = [...mcpCommands, ...mcpSkills]
```

이 구조는 MCP를 단순 "외부 tool 주입"으로만 보면 부족하다는 점을 보여 준다. MCP는 protocol-backed capability ingress layer 전체에 가깝다.

- 외부 tool이 들어온다.
- 외부 command/skill이 들어온다.
- resource surface가 들어온다.
- 필요한 경우 resource tool 자체도 보강된다.

최신 MCP 문서를 같이 보면 이 그림은 더 넓어진다. client는 roots로 작업 범위를 시사하고, sampling으로 server가 모델 호출을 요청할 수 있게 하며, elicitation으로 추가 입력을 받고, authorization으로 remote access를 분리한다. 즉 MCP는 tool transport가 아니라 capability ingress와 interaction control을 함께 정의하는 협력 프로토콜이다. 중요한 점은 roots가 coordination signal이지 security boundary가 아니라는 것이다.

## ToolSearch는 deferred capability와 현재 surface를 이어 주는 브리지다

세션에 capability가 다 한 번에 보이지는 않는다. `ToolSearchTool`은 deferred tool set에 대해 exact match, MCP prefix match, keyword scoring을 수행한다.

```ts
if (queryLower.startsWith('mcp__') && queryLower.length > 5) {
  const prefixMatches = deferredTools
    .filter(t => t.name.toLowerCase().startsWith(queryLower))
    .slice(0, maxResults)
    .map(t => t.name)
  ...
}
```

즉 확장 surface를 이해할 때는 "지금 visible한 것"만이 아니라 "어떻게 discover될 수 있는가"까지 포함해야 한다.

## plugin은 capability 자체보다 provenance bundle에 가깝다

commands aggregation에서 plugin command와 plugin skill이 별도 source로 들어오듯, plugin은 capability 그 자체라기보다 여러 capability source와 metadata를 묶는 packaging layer로 읽는 편이 정확하다. 이 distinction이 없으면 plugin을 tool이나 skill과 같은 층으로 오해하게 된다.

그래서 command, skill, plugin, MCP를 한 표에 둘 때는 기능명보다 provenance 열이 더 중요하다. built-in, local skill, shared skill, plugin-delivered skill, local MCP, remote MCP는 겉보기 surface가 비슷해도 신뢰 모델과 장애 모드가 다르다.

## 관찰, 원칙, 해석, 권고

관찰:

- Claude Code는 command, skill, MCP, deferred tool search를 서로 다른 ingress surface로 유지한다.
- local skill과 remote MCP skill은 같은 신뢰 모델이 아니다.
- plugin은 capability bundle/provenance layer로 읽는 편이 더 정확하다.

원칙:

- capability가 세션에 들어오는 경로와 provenance를 분리해서 문서화해야 한다.
- prompt-style guidance surface와 structured tool surface를 같은 층으로 뭉개면 안 된다.
- remote capability ingress에는 local과 다른 security rules를 붙여야 한다.
- ingress grammar와 startup-time instruction stack은 같은 표면이 아니므로 별도 장에서 설명하는 편이 낫다.
- 현대 MCP client semantics는 tool 호출 이후의 sampling, elicitation, authorization까지 고려하게 만든다.

해석:

- multi-agent 연구가 말하는 shared tooling/substrate 문제는 Claude Code에서 command/skill/MCP ingress surface의 조합으로 구현된다.
- 이 codebase는 "확장"을 하나의 plugin system으로 환원하지 않고, 여러 문법의 조합으로 유지한다.

권고:

- 새 하네스를 설명할 때는 command, tool, skill, plugin, MCP를 capability ingress 관점의 표로 먼저 정리하라.
- remote prompt/guidance surface에는 local file-based surface와 다른 trust rule을 명시하라.
- deferred capability가 있다면 discoverability bridge를 별도 설계하라.

## Review scaffold

- 같은 surface에 놓인 command나 skill이 어디서 왔는지 built-in, local, shared, plugin, MCP 중 하나로 바로 답할 수 있어야 한다.
- MCP를 쓴다면 tools, resources, prompts, sampling, elicitation, authorization 중 어떤 client semantics를 실제로 채택했는지 적어 보라.
- roots나 namespace를 trust 표시로만 쓰고 enforcement boundary처럼 오해하고 있지 않은지 검토하라.

## benchmark 질문

1. 이 확장은 operator surface인가, prompt guidance인가, bundle layer인가, protocol ingress인가.
2. provenance가 사용자와 모델 모두에게 충분히 드러나는가.
3. local skill과 remote skill을 같은 trust 모델로 취급하고 있지 않은가.
4. deferred capability가 있을 때 discoverability bridge가 존재하는가.

## 요약

command, tool, skill, plugin, MCP는 서로 경쟁하는 개념이 아니라, 세션에 capability가 들어오는 서로 다른 문법이다. Claude Code는 이 문법들이 한 product shell 안에서 어떻게 공존하는지 보여 준다. 이 구분이 있어야 확장 구조를 실제 provenance와 ownership 언어로 설명할 수 있다.

## 대표 근거 읽기 순서

아래 라벨은 독자가 별도 source를 열어야 한다는 뜻이 아니라, 이 장에서 이미 인용하고 설명한 코드 발췌가 어떤 구현 단면을 대표하는지 다시 묶어 주는 provenance 메모다.

1. `src/commands.ts`
   slash surface aggregation seam을 본다.
2. `src/skills/loadSkillsDir.ts`
   markdown guidance가 prompt command로 승격되는 방식을 본다.
3. `src/services/mcp/client.ts`
   protocol-backed ingress surface를 확인한다.
4. `src/tools/ToolSearchTool/ToolSearchTool.ts`
   deferred capability discoverability를 본다.
5. `src/services/mcp/MCPConnectionManager.tsx`
   session 안에서 MCP connection이 어떤 managed surface로 유지되는지 확인한다.
