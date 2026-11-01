#!/usr/bin/env bash
# 저장소 스킬을 ~/.agents/skills에 설치하고 ~/.claude/skills에 심볼릭 링크를 만든다.
#
# 사용법:
#   ./apply-skills.sh                    # 저장소의 모든 스킬 설치
#   ./apply-skills.sh caveman grilling   # 지정한 스킬만 설치
#
# 요청한 스킬만 교체하고, ~/.agents/skills와 ~/.claude/skills의 다른 항목은 그대로 둔다.
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly HOME_DIR="${HOME:?HOME is required}"
readonly AGENTS_DIR="$HOME_DIR/.agents"
readonly TARGET_SKILLS="$AGENTS_DIR/skills"
readonly CLAUDE_DIR="$HOME_DIR/.claude"
readonly CLAUDE_SKILLS="$CLAUDE_DIR/skills"
readonly CLAUDE_LINK_PREFIX='../../.agents/skills'
readonly MAIN_PID="$$"

STAGING_ROOT=''
MUTATION_STARTED=0
declare -a created_dirs=()
declare -a selected_order=()

die() {
  printf '오류: %s\n' "$*" >&2
  exit 1
}

read_skill_name() {
  local skill_file="$1"
  local name

  name="$(
    awk '
      NR == 1 && $0 == "---" {
        in_frontmatter = 1
        next
      }
      in_frontmatter && $0 == "---" {
        exit
      }
      in_frontmatter && /^[[:space:]]*name:[[:space:]]*/ {
        sub(/^[[:space:]]*name:[[:space:]]*/, "")
        sub(/[[:space:]]*\r$/, "")
        print
        exit
      }
    ' "$skill_file"
  )"

  if [[ "$name" == \"*\" && "$name" == *\" ]]; then
    name="${name:1:${#name}-2}"
  elif [[ "$name" == \'*\' && "$name" == *\' ]]; then
    name="${name:1:${#name}-2}"
  fi
  printf '%s\n' "$name"
}

is_safe_name() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

# 이번 실행에서 건드린 스킬 이름만 백업 시점으로 되돌린다.
restore_backup() {
  set +e
  local name dir i

  for name in "${selected_order[@]}"; do
    rm -rf -- "${TARGET_SKILLS:?}/$name"
    if [[ -e "$STAGING_ROOT/backup/skills/$name" || -L "$STAGING_ROOT/backup/skills/$name" ]]; then
      cp -a -- "$STAGING_ROOT/backup/skills/$name" "$TARGET_SKILLS/$name"
    fi

    # 사전 점검에서 실제 디렉터리가 아님을 확인했으므로 링크만 다룬다.
    [[ -L "$CLAUDE_SKILLS/$name" ]] && rm -f -- "$CLAUDE_SKILLS/$name"
    if [[ -L "$STAGING_ROOT/backup/claude/$name" ]]; then
      cp -a -- "$STAGING_ROOT/backup/claude/$name" "$CLAUDE_SKILLS/$name"
    fi
  done

  # 이번 실행에서 새로 만든 디렉터리는 비어 있으면 깊은 것부터 지운다.
  for ((i = ${#created_dirs[@]} - 1; i >= 0; i--)); do
    dir="${created_dirs[i]}"
    rmdir -- "$dir" 2>/dev/null
  done
  return 0
}

cleanup() {
  if [[ -n "$STAGING_ROOT" && -d "$STAGING_ROOT" ]]; then
    rm -rf -- "$STAGING_ROOT"
  fi
  return 0
}

abort() {
  local status="$1"
  local message="$2"

  # set -E 때문에 $(...) 서브셸에서도 트랩이 실행된다. 서브셸이 복원/정리를 하면
  # 스테이징 백업이 먼저 지워지므로, 복원은 메인 셸에서만 수행한다.
  if [[ "$BASHPID" != "$MAIN_PID" ]]; then
    exit "$status"
  fi

  trap - ERR HUP INT TERM
  if ((MUTATION_STARTED)); then
    printf '%s: 기존 설정을 복원합니다.\n' "$message" >&2
    restore_backup
  fi
  cleanup
  exit "$status"
}

trap 'abort $? "적용 실패"' ERR
trap 'abort 129 "적용 중단"' HUP
trap 'abort 130 "적용 중단"' INT
trap 'abort 143 "적용 중단"' TERM
trap cleanup EXIT

# ---------------------------------------------------------------------------
# 사전 점검
# ---------------------------------------------------------------------------
for dir in "$AGENTS_DIR" "$TARGET_SKILLS" "$CLAUDE_DIR" "$CLAUDE_SKILLS"; do
  [[ ! -e "$dir" || (-d "$dir" && ! -L "$dir") ]] ||
    die "경로가 일반 디렉터리가 아닙니다: $dir"
done

# ---------------------------------------------------------------------------
# 저장소 스킬 목록: 루트 바로 아래에서 SKILL.md가 있는 폴더
# ---------------------------------------------------------------------------
declare -A available=()
declare -a all_skill_names=()
for skill_file in "$SCRIPT_DIR"/*/SKILL.md; do
  [[ -f "$skill_file" ]] || continue
  dir="$(dirname -- "$skill_file")"
  name="${dir##*/}"
  is_safe_name "$name" || die "안전하지 않은 스킬 폴더 이름입니다: $name"

  declared="$(read_skill_name "$skill_file")"
  [[ "$declared" == "$name" ]] ||
    die "폴더 이름과 SKILL.md의 name이 다릅니다: $name (name: ${declared:-없음})"

  available["$name"]=1
  all_skill_names+=("$name")
done
((${#all_skill_names[@]} > 0)) || die '저장소에서 스킬을 찾지 못했습니다.'

# ---------------------------------------------------------------------------
# 인자 해석: 인자가 없으면 전체, 있으면 지정한 스킬만
# ---------------------------------------------------------------------------
declare -A selected=()
if (($# == 0)); then
  set -- "${all_skill_names[@]}"
fi
for name in "$@"; do
  name="${name%/}"
  is_safe_name "$name" || die "안전하지 않은 스킬 이름입니다: $name"
  [[ -n "${available[$name]+set}" ]] || die "저장소에서 스킬을 찾지 못했습니다: $name"
  [[ -z "${selected[$name]+set}" ]] || continue
  selected["$name"]=1
  selected_order+=("$name")
done

for name in "${selected_order[@]}"; do
  target="$TARGET_SKILLS/$name"
  [[ ! -L "$target" ]] || die "설치 경로가 심볼릭 링크입니다: $target"
  link="$CLAUDE_SKILLS/$name"
  [[ ! -e "$link" || -L "$link" ]] ||
    die "Claude 스킬 경로에 심볼릭 링크가 아닌 항목이 있습니다: $link"
done

# ---------------------------------------------------------------------------
# 스테이징과 백업 (요청한 스킬 이름에 해당하는 항목만)
# ---------------------------------------------------------------------------
STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/apply-skills.XXXXXX")"
mkdir -p -- "$STAGING_ROOT/selected" "$STAGING_ROOT/backup/skills" "$STAGING_ROOT/backup/claude"

for name in "${selected_order[@]}"; do
  cp -a -- "$SCRIPT_DIR/$name" "$STAGING_ROOT/selected/$name"
  if [[ -e "$TARGET_SKILLS/$name" ]]; then
    cp -a -- "$TARGET_SKILLS/$name" "$STAGING_ROOT/backup/skills/$name"
  fi
  if [[ -L "$CLAUDE_SKILLS/$name" ]]; then
    cp -a -- "$CLAUDE_SKILLS/$name" "$STAGING_ROOT/backup/claude/$name"
  fi
done

# ---------------------------------------------------------------------------
# 적용
# ---------------------------------------------------------------------------
MUTATION_STARTED=1
for dir in "$AGENTS_DIR" "$TARGET_SKILLS" "$CLAUDE_DIR" "$CLAUDE_SKILLS"; do
  if [[ ! -d "$dir" ]]; then
    mkdir -- "$dir"
    created_dirs+=("$dir")
  fi
done

for name in "${selected_order[@]}"; do
  rm -rf -- "${TARGET_SKILLS:?}/$name"
  cp -a -- "$STAGING_ROOT/selected/$name" "$TARGET_SKILLS/$name"
  rm -f -- "$CLAUDE_SKILLS/$name"
  ln -s -- "$CLAUDE_LINK_PREFIX/$name" "$CLAUDE_SKILLS/$name"
done

MUTATION_STARTED=0
printf '적용 완료 (%d개): %s\n' "${#selected_order[@]}" "${selected_order[*]}"
