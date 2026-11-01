# agent-skills

Codex, Claude 같은 LLM 코딩 에이전트에서 재사용할 수 있는 스킬 모음입니다.

## 스킬

- `caveman`: 기술적 정확성을 유지하면서 응답을 짧게 압축합니다.
- `deep-interview`: 모호한 요청을 질문으로 구체화해 실행 가능한 요구사항으로 정리합니다.
- `git-upload`: 변경을 목적별로 커밋하고 PR 생성, 검증, squash merge, 브랜치 정리까지 수행합니다.
- `domain-modeling`: 도메인 용어와 모델을 구체화하고 아키텍처 결정을 기록합니다.
- `grilling`: 계획이나 아이디어를 집중 인터뷰로 검증합니다.
- `grill-me`: `grilling` 인터뷰를 시작합니다.
- `grill-with-docs`: 인터뷰와 함께 ADR 및 용어 문서를 작성합니다.
- `handoff`: 다음 에이전트가 이어받을 수 있도록 대화 맥락을 인계 문서로 정리합니다.

## 설치

```bash
./apply-skills.sh                    # 저장소의 모든 스킬 설치
./apply-skills.sh caveman grilling   # 지정한 스킬만 설치
```

- 스킬은 `~/.agents/skills/<name>`에 복사되고, `~/.claude/skills/<name>`에는 이를 가리키는 심볼릭 링크가 만들어집니다.
- 요청한 스킬만 새로 설치하거나 교체하고, 이미 설치된 다른 스킬은 그대로 둡니다.
- 실패하거나 중단되면 이번 실행에서 건드린 스킬을 기존 상태로 복원합니다.
