---
name: git-upload
description: Organize all current Git changes into purpose-based commits, create and push a new branch, open a GitHub pull request, verify local checks and CI, squash merge automatically, and clean up local and remote branches. Use only when the user explicitly invokes `$git-upload`, either by itself or with an accompanying request such as "$git-upload 깃 업로드 해줘". Do not trigger from an ordinary upload, push, publish, PR, or merge request that does not explicitly name `$git-upload`.
---

# Git Upload

현재 작업 트리의 변경을 새 브랜치에서 목적별 커밋으로 구성하고, 검증된 PR을 squash merge한 뒤 브랜치를 정리한다.

## 핵심 원칙

- 사용자가 명시적으로 제외한 항목이 없으면 추적 파일, 미추적 파일, 삭제 파일을 포함한 모든 변경을 처리한다.
- stage나 commit보다 먼저 최신 원격 기본 브랜치에서 새 작업 브랜치를 만든다.
- 파일 종류가 아니라 변경 목적과 독립적인 rollback 가능성을 기준으로 커밋을 나눈다.
- 로컬 검증이 실패하면 push를 중단하고, CI가 실패하면 merge와 브랜치 정리를 중단한다.
- CI가 없으면 통과한 로컬 테스트, lint, type check를 merge gate로 사용한다.
- CI가 있으면 모두 통과할 때까지 기다린 뒤 추가 승인 없이 squash merge한다.
- 사용자 변경을 버리거나 숨기기 위해 `reset`, `clean`, 강제 checkout, 강제 push를 사용하지 않는다.
- 명백한 credential, private key, token 또는 민감 정보가 보이면 업로드하지 말고 사용자에게 알린다.
- 실행하지 않은 검증, 확인하지 않은 위험, 존재하지 않는 변경을 메시지에 작성하지 않는다.

## 1. 저장소와 변경 확인

1. 저장소 지침 파일과 현재 상태를 확인한다.
   - `AGENTS.md`와 저장소별 지침
   - `git status --short`
   - staged, unstaged, untracked 변경
   - 현재 브랜치와 upstream
   - remote와 원격 기본 브랜치
   - GitHub CLI 설치 및 인증 상태
2. 사용자가 제외한 경로와 변경을 별도 목록으로 기록한다. 제외 요청이 없으면 모든 변경을 대상에 넣는다.
3. diff와 필요한 미추적 파일 내용을 검토해 다음을 파악한다.
   - 전체 변경 목적
   - 서로 독립적인 변경 목적
   - 테스트와 구현의 연결 관계
   - migration, generated file, dependency lockfile 관계
   - credential이나 민감 정보 포함 여부
4. 업로드할 변경이 없으면 중단하고 그 사실을 보고한다.

## 2. 기본 브랜치 최신화와 작업 브랜치 생성

1. `origin/HEAD`를 우선 사용하고, 필요하면 GitHub repository 정보로 원격 기본 브랜치를 확인한다.
2. `git fetch origin`으로 원격 상태를 갱신한다.
3. 현재 HEAD에 원격 기본 브랜치에 포함되지 않은 기존 커밋이 있는지 확인한다.
   - 있으면 새 브랜치에서 누락될 수 있으므로 자동으로 버리거나 재작성하지 않는다.
   - 해당 커밋을 포함할지 판단이 필요하면 중단하고 사용자에게 묻는다.
4. 전체 변경을 대표하는 영문 kebab-case 이름을 만든다.
   - 형식: `<type>/<short-description>`
   - 예: `feat/oauth-login`, `fix/duplicate-payment-retry`
   - remote 또는 local에 같은 이름이 있으면 의미 있는 짧은 suffix로 충돌을 피한다.
5. stage하기 전에 최신 `origin/<default-branch>`를 시작점으로 새 브랜치를 만든다.
6. 브랜치 전환이 작업 트리 충돌로 실패하면 stash나 강제 전환을 하지 말고 실제 충돌을 보고한다.
7. skill 실행 전에 staged된 변경이 있으면 새 브랜치 생성 후 working tree를 보존한 채 unstage하고 목적별로 다시 구성한다.

## 3. 목적별 커밋 구성

변경을 한 커밋에 몰아넣지 말고 다음 기준으로 나눈다.

- 하나의 커밋에는 하나의 설명 가능한 목적만 담는다.
- 함께 적용하고 함께 되돌려야 하는 구현, 테스트, schema, lockfile은 같은 커밋에 둔다.
- 서로 독립적으로 review하거나 rollback할 수 있는 feature, fix, refactor, docs, tooling 변경은 분리한다.
- 순수 formatting이나 generated file 갱신은 원인 변경과 연결되지 않으면 별도 커밋으로 둔다.
- 각 커밋이 가능한 한 자체적으로 일관되고 검증 가능한 상태가 되도록 의존 순서대로 만든다.
- 모든 대상 파일이 정확히 한 커밋에 포함되었는지 마지막에 확인한다.

각 커밋마다 다음 절차를 반복한다.

1. 해당 목적에 속한 경로만 명시적으로 stage한다.
2. `git diff --cached --check`, staged diff, staged file 목록을 확인한다.
3. 다른 목적의 변경이 섞였으면 stage 구성을 바로잡는다.
4. 아래 형식으로 commit한다.

```text
<type>: <한글 핵심 요약>

- <핵심 변경 1>
- <핵심 변경 2>
- <필요한 경우 핵심 변경 3>
```

메시지 작성 규칙:

- 내용은 한글로 작성하고 API, OAuth, Redis, callback, lint처럼 필요한 기술 용어만 영어로 쓴다.
- 제목은 결과 중심으로 간결하게 작성한다.
- 본문은 변경된 핵심 내용을 bullet로 요약한다.
- `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore` 중 목적에 맞는 type을 사용한다.
- 같은 문장을 제목과 bullet에 그대로 반복하지 않는다.

모든 커밋 후 `git status --short`를 다시 확인한다. 명시적 제외 항목 외에 남은 변경이 있으면 push하지 말고 누락을 해결한다.

## 4. 로컬 검증

1. 저장소 지침, package manifest, task runner, CI 설정에서 관련 명령을 찾는다.
2. 변경 범위에 맞는 테스트, lint, type check를 모두 실행한다.
3. 실제 명령, exit code, 통과·실패 개수와 생략 사유를 기록한다.
4. 명령이 존재하지 않으면 실행한 것처럼 쓰지 말고 "설정된 명령 없음"으로 기록한다.
5. 하나라도 실패하면 push와 PR 생성을 중단하고 실패 결과를 보고한다.

## 5. Push와 PR 생성

1. 현재 브랜치를 `origin`에 upstream과 함께 push한다.
2. 모든 커밋과 전체 diff를 종합해 PR 제목을 만든다.
   - 개별 커밋 제목을 이어 붙이지 않는다.
   - 전체 변경의 공통 목적을 한 문장으로 요약한다.
   - 여러 type이 섞이면 가장 중요한 사용자 영향에 해당하는 대표 type을 고른다.
   - 형식: `<type>: <한글 전체 요약>`
3. PR 본문에 다음 섹션을 항상 작성한다.

```md
## Summary

<전체 목적을 간결한 요약형 문장으로 작성>

- <핵심 변경 1>
- <핵심 변경 2>

## Test Coverage

- <추가하거나 수정한 테스트와 검증 범위>

## Risks

- <확인된 위험과 완화 방법>

## Verification

- `<실제 명령>`: <실제 결과>
```

PR 작성 규칙:

- `Summary`, `Test Coverage`, `Risks`, `Verification`을 생략하지 않는다.
- 새로운 테스트가 없으면 그 이유와 기존 테스트가 다루는 범위를 적는다.
- 주요 위험이 없으면 "확인된 주요 위험 없음"이라고 명시하고 위험을 꾸며내지 않는다.
- 실제 출력에 근거해 검증 결과를 작성한다.
- 필요한 경우에만 `Background`, `Implementation Details`, `Breaking Changes`, `Migration`, `Rollback`, `Screenshots`, `Related Issues`를 추가한다.
- 호환성 변경, migration, 운영 위험, UI 변경처럼 review에 필요한 정보를 숨기지 않는다.
4. 원격 기본 브랜치를 base, 현재 작업 브랜치를 head로 지정해 PR을 생성한다.
5. 생성된 PR URL과 번호를 보관한다.

## 6. CI 확인과 자동 squash merge

1. PR의 head commit SHA와 check 목록을 확인한다.
2. check가 있으면 완료될 때까지 감시한다.
   - failure, cancellation, timeout이 발생하면 merge하지 않는다.
   - check 도중 head SHA가 바뀌면 새 변경을 검토하고 로컬 검증과 CI 확인을 다시 수행한다.
3. check가 없으면 로컬 테스트, lint, type check 통과 결과를 merge gate로 사용한다.
4. 전체 diff와 모든 커밋을 다시 종합해 squash commit을 작성한다.

Squash 제목:

```text
<PR 제목> (#<PR 번호>)
```

Squash 본문:

```text
<전체 변경을 나타내는 짧은 요약형 문장>.

- <핵심 변경 1>
- <핵심 변경 2>
- <필요한 경우 핵심 변경 3>
```

Squash 메시지 작성 규칙:

- 첫 문장은 "기능을 추가했습니다" 같은 서술형 대신 "OAuth 로그인 흐름 추가."처럼 간결하게 쓴다.
- 개별 커밋 제목을 복사하지 말고 전체 결과를 요약한다.
- bullet에는 전체 diff의 핵심 변경을 목적 중심으로 담는다.
- 한글을 기본으로 하고 필요한 기술 용어만 영어로 쓴다.

5. 검증한 head SHA를 `--match-head-commit`으로 고정하고, 작성한 제목·본문과 `--delete-branch`를 지정해 `gh pr merge --squash`를 실행한다.
6. merge 명령의 exit code와 관계없이 PR 상태와 merge commit SHA를 다시 조회한다.
   - `OPEN`이면 merge와 브랜치 정리를 중단하고 실패를 보고한다.
   - `MERGED`이면 merge 명령을 반복하지 말고 브랜치 정리 단계로 진행한다.
7. repository가 요구하는 merge queue나 branch protection을 우회하지 않는다. `--admin`을 사용하지 않는다.

## 7. 브랜치 정리와 완료 검증

1. PR 상태가 실제로 `MERGED`인지 확인한다.
2. `gh pr merge --delete-branch`가 원격 작업 브랜치를 삭제했는지 확인한다.
   - 원격 작업 브랜치가 남아 있어도 별도 삭제 명령이나 API로 삭제하지 않고 실제 상태를 보고한다.
3. 기본 브랜치로 전환하고 원격 기본 브랜치를 fast-forward로 최신화한다.
4. 로컬 작업 브랜치가 삭제되었는지 확인한다.
5. 명시적으로 제외된 변경이 있다면 그대로 보존하고 위치를 보고한다.

## 완료 보고

다음을 실제 결과와 함께 간결하게 보고한다.

- 생성한 브랜치
- 목적별 커밋 목록
- 실행한 테스트, lint, type check 명령과 결과
- PR 제목과 URL
- CI 또는 CI 없음에 사용한 merge gate
- squash merge 제목과 merge commit SHA
- 로컬·원격 브랜치 정리 결과
- 제외된 변경이나 남은 위험
