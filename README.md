# agent-skills

Codex, Claude 같은 LLM 코딩 에이전트가 범용적으로 재사용하기 좋은 스킬을 모아둔 저장소입니다. 원본은 `gstack`과 `superpowers`에서 가져왔고, 특정 제품이나 워크플로에만 묶이는 기능보다 대부분의 코드베이스에서 도움이 되는 작업 방식 위주로 선별했습니다.

## Superpowers

Superpowers 계열은 에이전트가 작업을 대충 밀어붙이지 않고, 요구사항 정리부터 구현, 검증까지 일관된 절차를 따르도록 돕는 스킬입니다.

- `brainstorming`: 모호한 요구사항, 기능 설계, UI 방향, API 설계 정리.
- `writing-plans`: 다중 파일, 데이터 흐름 변경 작업의 실행 계획 분리.
- `executing-plans`: 작성된 계획 실행과 단계별 검증.
- `systematic-debugging`: 버그, 테스트 실패, 빌드 오류의 원인 추적.
- `verification-before-completion`: 완료 선언 전 테스트, lint, build 검증.
- `requesting-code-review`: 변경 후 diff 리뷰와 누락 위험 점검.

## gstack

gstack 계열은 QA, 브라우저 검증, 릴리스, 안전장치처럼 작업 후반부의 품질 확인과 운영 리스크 관리에 초점을 둔 스킬입니다. 일반 작업마다 자동으로 쓰기보다는, 더 깊은 검증이 필요할 때 선택적으로 사용하는 편이 좋습니다.

- `browse`: 실제 브라우저 탐색, 상호작용, 스크린샷 검증.
- `qa-only`: 웹 애플리케이션 테스트와 버그 리포트 작성.
- `qa`: 웹 애플리케이션 테스트, 버그 수정, 재검증.
- `design-review`: UI 레이아웃, 간격, 시각적 일관성, 사용성 점검.
- `health`: 테스트, lint, type check, dead code 기반 품질 점검.
- `investigate`: 복잡한 장애나 cross-stack 버그 원인 조사.
- `review`: PR, diff 병합 전 리스크 검토.
- `ship`: 테스트, 리뷰, changelog, commit, push, PR 준비.
- `careful`: 운영, DB, destructive command 전 안전장치.
