# agent-skills

Codex, Claude 같은 LLM 코딩 에이전트에서 재사용할 수 있는 스킬 모음입니다.

## 기본

- `caveman`: 기술적 정확성을 유지하면서 응답을 짧게 압축합니다.
- `deep-interview`: 모호한 요청을 질문으로 구체화해 실행 가능한 요구사항으로 정리합니다.
- `git-upload`: 변경을 목적별로 커밋하고 PR 생성, 검증, squash merge, 브랜치 정리까지 수행합니다.

## superpowers

- `brainstorming`: 구현 전에 요구사항과 설계를 구체화합니다.
- `writing-plans`: 복잡한 작업을 실행 가능한 단계로 나눕니다.
- `executing-plans`: 작성된 계획을 검토하고 단계별로 실행합니다.
- `systematic-debugging`: 버그와 테스트 실패의 근본 원인을 추적합니다.
- `verification-before-completion`: 완료 선언 전에 테스트와 검증 결과를 확인합니다.
- `requesting-code-review`: 변경 사항에 대한 코드 리뷰를 요청하고 피드백을 반영합니다.

## gstack

- `browse`: 헤드리스 브라우저로 페이지를 탐색하고 검증합니다.
- `careful`: 파괴적이거나 위험한 명령에 안전장치를 적용합니다.
- `design-review`: UI의 시각적 일관성, 레이아웃, 사용성을 점검하고 개선합니다.
- `health`: 테스트, lint, type check 등 코드베이스의 품질 상태를 점검합니다.
- `investigate`: 복잡한 장애와 cross-stack 버그의 원인을 조사합니다.
- `qa-only`: 웹 애플리케이션을 테스트하고 수정 없이 결과만 보고합니다.
- `qa`: 웹 애플리케이션을 테스트하고 발견한 버그를 수정합니다.
- `review`: 병합 전에 변경 사항과 리스크를 검토합니다.
- `ship`: 테스트, 리뷰, 버전과 changelog 갱신, commit, push, PR 생성을 수행합니다.

## matt-pocock

- `domain-modeling`: 도메인 용어와 모델을 구체화하고 아키텍처 결정을 기록합니다.
- `grilling`: 계획이나 아이디어를 집중 인터뷰로 검증합니다.
- `grill-me`: `grilling` 인터뷰를 시작합니다.
- `grill-with-docs`: 인터뷰와 함께 ADR 및 용어 문서를 작성합니다.
- `handoff`: 다음 에이전트가 이어받을 수 있도록 대화 맥락을 인계 문서로 정리합니다.
