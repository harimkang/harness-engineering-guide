# Part 6 Guide: Boundaries, Deployment, And Safety

이 Part는 autonomy를 가능하게 하는 경계 설계를 다룹니다. 먼저 boundary engineering, sandboxing, policy surfaces, local/remote family, safety-autonomy benchmark를 읽고, 이어서 governance/risk/compliance mapping을 별도 축으로 끌어올립니다. 그 다음 Claude Code의 remote/bridge/direct-connect 구조와 design tension을 사례로 확인합니다.

## 이 Part의 핵심 질문

- safety는 permission prompt 숫자가 아니라 어떤 경계 설계의 문제인가
- local, remote, bridge, direct-connect는 왜 서로 다른 family인가
- boundary placement는 autonomy와 operator legibility를 어떻게 바꾸는가
- deployment boundary가 유지보수 비용과 failure mode를 어떻게 재구성하는가
- 이 기술 설명을 architecture review language로 어떻게 번역할 것인가

## 먼저 읽을 원칙 장

1. [./01-boundary-engineering-and-autonomy.md](./01-boundary-engineering-and-autonomy.md)
2. [./02-sandboxing-permissions-and-policy-surfaces.md](./02-sandboxing-permissions-and-policy-surfaces.md)
3. [./03-local-remote-bridge-and-direct-connect.md](./03-local-remote-bridge-and-direct-connect.md)
4. [./04-safety-autonomy-benchmark.md](./04-safety-autonomy-benchmark.md)
5. [./07-governance-risk-and-compliance-mapping.md](./07-governance-risk-and-compliance-mapping.md)

## 이어서 읽을 Claude Code 사례 장

1. [./05-claude-code-remote-bridge-server-and-upstream-proxy.md](./05-claude-code-remote-bridge-server-and-upstream-proxy.md)
2. [./06-claude-code-risks-debt-and-failure-modes.md](./06-claude-code-risks-debt-and-failure-modes.md)

## 필요할 때 함께 볼 곳

- [../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md](../07-evaluation-and-synthesis/07-claude-code-end-to-end-scenarios.md)
- [../08-reference/05-conditional-features-map.md](../08-reference/05-conditional-features-map.md)
