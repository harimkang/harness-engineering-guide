# Appendix. Instruction Precedence Matrix

> Why this chapter exists: instruction surface를 prose만이 아니라 review matrix로 고정해 precedence 비교를 빠르게 다시 열게 만든다.
> Reader path tags: `builder` / `reviewer` / `volatile re-check`
> Last verified: 2026-04-07
> Freshness class: volatile
> Source tier focus: Tier 1 product docs와 Part 4 instruction-surface synthesis를 condensed review artifact로 재정리한다.

## 장 요약

Part 4/09는 settings, memory files, skills, subagents, MCP, plugins를 layered instruction surface로 읽게 만든다. 이 appendix는 그 핵심을 한 표로 다시 고정한다. 목적은 "무엇이 무엇을 override하는가"만 적는 데 있지 않다. 더 중요한 일은 각 surface가 policy를 바꾸는지, capability를 바꾸는지, 언제 로드되는지, volatility가 어느 정도인지를 같은 눈금으로 비교하게 만드는 것이다.

## 읽는 규칙

1. override rule은 "항상 강하다"는 뜻이 아니라 같은 계층의 충돌과 load timing을 함께 봐야 한다는 뜻이다.
2. `affects policy?`와 `affects capability?`는 분리해서 읽는다.
3. 이 표는 review shorthand다. vendor-specific 전체 사양은 [../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md](../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md)와 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)를 다시 연다.

## Matrix

| surface | owner | scope | load timing | override rule | affects policy? | affects capability? | volatility |
| --- | --- | --- | --- | --- | --- | --- | --- |
| managed settings / policy | platform owner, security owner | org / workspace fleet | session start 이전 | 가장 높은 강제 계층이며 local/project/user 설정보다 우선 | yes | yes | medium |
| CLI flags / session overrides | invoking operator | session | launch time | managed 아래에서 session-scoped override로 작동 | yes | yes | volatile |
| local settings | workstation or repo-local operator | local workspace | session start | CLI와 managed 아래, project/user above | yes | yes | volatile |
| project settings | repo owner or team | repository | session start | local below, user above | yes | yes | volatile |
| user settings | end user | user profile | session start | 기본 preference layer로 다른 scope에 의해 override 가능 | yes | yes | volatile |
| `CLAUDE.md` and memory files | repo owner, user | repo / conversation seed | startup and context assembly | config precedence를 직접 대체하지 않고 instruction memory를 추가 | yes | no direct | volatile |
| skills | task author, team, plugin author | task / project / plugin | invocation time | namespace와 skill precedence 아래 결합되며 config precedence와는 별도 | yes | yes indirect | volatile |
| subagents | operator, skill author, task planner | delegated task | delegation time | parent contract 아래 forked or isolated context로 들어간다 | yes | yes indirect | volatile |
| MCP server configuration | operator, admin, managed policy owner | user / project / managed | startup / connect time | managed allowlist/denylist와 scope rule의 영향을 받음 | yes | yes | volatile |
| plugin packaging | plugin author, platform owner | install / workspace / org | install and startup | plain prompt override가 아니라 packaged surface와 policy rule로 결합 | yes | yes | volatile |

## 해석 팁

- settings 계층은 policy와 capability를 직접 바꾸기 쉽다.
- `CLAUDE.md`와 memory file은 행동 조건을 강하게 바꾸지만, 보통 capability 자체를 직접 추가하지는 않는다.
- skill과 subagent는 text surface이면서 execution metadata surface이기도 하다.
- MCP와 plugin은 capability ingress이지만, managed configuration과 결합하면 policy surface와도 맞닿는다.

## 관련 장

- [../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md](../04-interfaces-and-operator-surfaces/09-instruction-surfaces-settings-hooks-claude-md-subagents.md)
- [../02-runtime-and-session-start/02-startup-contract-trust-boundary-and-initialization.md](../02-runtime-and-session-start/02-startup-contract-trust-boundary-and-initialization.md)
- [../00-front-matter/03-references.md](../00-front-matter/03-references.md)

## Sources / evidence notes

- 이 matrix는 [../00-front-matter/03-references.md](../00-front-matter/03-references.md)의 `S10`, `S11`, `S12`, `S14`, `S24`와 Part 4/09의 synthesis를 함께 압축한 review artifact다.
- settings, skills, MCP, CLI behavior는 drift 가능성이 크므로 `volatile re-check`가 필요한 장을 고칠 때 이 표만 믿지 말고 원 source를 다시 확인해야 한다.
