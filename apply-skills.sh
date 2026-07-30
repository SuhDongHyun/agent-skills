#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SOURCE_AGENTS="$SCRIPT_DIR/AGENTS.md"
readonly AGENTS_DIR="${HOME:?HOME is required}/.agents"
readonly CODEX_DIR="${HOME:?HOME is required}/.codex"
readonly TARGET_SKILLS="$AGENTS_DIR/skills"
readonly TARGET_AGENTS="$CODEX_DIR/AGENTS.md"

STAGING_ROOT=''
MUTATION_STARTED=0
AGENTS_DIR_EXISTED=0
SKILLS_DIR_EXISTED=0
CODEX_DIR_EXISTED=0
AGENTS_EXISTED=0
AGENTS_TEMP=''

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

validate_name() {
  local name="$1"
  [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] ||
    die "안전하지 않은 스킬 이름입니다: $name"
}

remove_user_skills() {
  [[ -d "$TARGET_SKILLS" ]] || return 0
  find "$TARGET_SKILLS" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
}

restore_backup() {
  set +e
  remove_user_skills
  if [[ -d "$STAGING_ROOT/backup/skills" ]]; then
    cp -a -- "$STAGING_ROOT/backup/skills/." "$TARGET_SKILLS/"
  fi

  rm -f -- "$TARGET_AGENTS"
  if [[ -n "$AGENTS_TEMP" ]]; then
    rm -f -- "$AGENTS_TEMP"
  fi
  if ((AGENTS_EXISTED)); then
    cp -a -- "$STAGING_ROOT/backup/AGENTS.md" "$TARGET_AGENTS"
  fi

  if ((!SKILLS_DIR_EXISTED)); then
    rmdir -- "$TARGET_SKILLS" 2>/dev/null || true
  fi
  if ((!AGENTS_DIR_EXISTED)); then
    rmdir -- "$AGENTS_DIR" 2>/dev/null || true
  fi
  if ((!CODEX_DIR_EXISTED)); then
    rmdir -- "$CODEX_DIR" 2>/dev/null || true
  fi
}

cleanup() {
  if [[ -n "$AGENTS_TEMP" ]]; then
    rm -f -- "$AGENTS_TEMP"
  fi
  if [[ -n "$STAGING_ROOT" && -d "$STAGING_ROOT" ]]; then
    rm -rf -- "$STAGING_ROOT"
  fi
}

on_error() {
  local status=$?
  trap - ERR HUP INT TERM
  if ((MUTATION_STARTED)); then
    printf '적용 실패: 기존 설정을 복원합니다.\n' >&2
    restore_backup
  fi
  cleanup
  exit "$status"
}

on_signal() {
  local status="$1"

  trap - ERR HUP INT TERM
  if ((MUTATION_STARTED)); then
    printf '적용 중단: 기존 설정을 복원합니다.\n' >&2
    restore_backup
  fi
  cleanup
  exit "$status"
}

trap on_error ERR
trap 'on_signal 129' HUP
trap 'on_signal 130' INT
trap 'on_signal 143' TERM
trap cleanup EXIT

(($# > 0)) || die '적용할 스킬 이름을 한 개 이상 전달하세요.'
[[ -f "$SOURCE_AGENTS" ]] || die "저장소 AGENTS.md가 없습니다: $SOURCE_AGENTS"
[[ ! -e "$AGENTS_DIR" || -d "$AGENTS_DIR" ]] ||
  die "에이전트 경로가 디렉터리가 아닙니다: $AGENTS_DIR"
[[ ! -e "$TARGET_SKILLS" || -d "$TARGET_SKILLS" ]] ||
  die "스킬 경로가 디렉터리가 아닙니다: $TARGET_SKILLS"
[[ ! -e "$CODEX_DIR" || -d "$CODEX_DIR" ]] ||
  die "Codex 경로가 디렉터리가 아닙니다: $CODEX_DIR"
[[ ! -e "$TARGET_AGENTS" || -f "$TARGET_AGENTS" ]] ||
  die "전역 AGENTS.md 경로가 파일이 아닙니다: $TARGET_AGENTS"

declare -A requested_names=()
declare -a requested_order=()
for name in "$@"; do
  validate_name "$name"
  [[ -z "${requested_names[$name]+set}" ]] ||
    die "스킬 이름을 중복해서 전달했습니다: $name"
  requested_names["$name"]=1
  requested_order+=("$name")
done

declare -a repository_skill_files=()
mapfile -d '' -t repository_skill_files < <(
  find "$SCRIPT_DIR" -type f -name 'SKILL.md' \
    ! -path "$SCRIPT_DIR/.git/*" -print0
)

declare -A selected_directories=()
for name in "${requested_order[@]}"; do
  declare -a matches=()
  for skill_file in "${repository_skill_files[@]}"; do
    if [[ "$(read_skill_name "$skill_file")" == "$name" ]]; then
      matches+=("$(dirname -- "$skill_file")")
    fi
  done

  ((${#matches[@]} > 0)) || die "저장소에서 스킬을 찾지 못했습니다: $name"
  ((${#matches[@]} == 1)) ||
    die "저장소에서 같은 이름의 스킬이 여러 개 발견됐습니다: $name"
  selected_directories["$name"]="${matches[0]}"
done

STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/apply-skills.XXXXXX")"
mkdir -p -- "$STAGING_ROOT/selected" "$STAGING_ROOT/backup/skills"

for name in "${requested_order[@]}"; do
  cp -a -- "${selected_directories[$name]}" "$STAGING_ROOT/selected/$name"
done

[[ -d "$AGENTS_DIR" ]] && AGENTS_DIR_EXISTED=1
[[ -d "$CODEX_DIR" ]] && CODEX_DIR_EXISTED=1
[[ -d "$TARGET_SKILLS" ]] && SKILLS_DIR_EXISTED=1
[[ -e "$TARGET_AGENTS" || -L "$TARGET_AGENTS" ]] && AGENTS_EXISTED=1

if ((SKILLS_DIR_EXISTED)); then
  cp -a -- "$TARGET_SKILLS/." "$STAGING_ROOT/backup/skills/"
fi
if ((AGENTS_EXISTED)); then
  cp -a -- "$TARGET_AGENTS" "$STAGING_ROOT/backup/AGENTS.md"
fi

MUTATION_STARTED=1
mkdir -p -- "$TARGET_SKILLS" "$CODEX_DIR"
remove_user_skills

while IFS= read -r -d '' entry; do
  cp -a -- "$entry" "$TARGET_SKILLS/"
done < <(find "$STAGING_ROOT/selected" -mindepth 1 -maxdepth 1 -print0)

AGENTS_TEMP="$(mktemp "$CODEX_DIR/.AGENTS.md.apply-skills.XXXXXX")"
cp -- "$SOURCE_AGENTS" "$AGENTS_TEMP"
mv -f -- "$AGENTS_TEMP" "$TARGET_AGENTS"
AGENTS_TEMP=''

MUTATION_STARTED=0
printf '적용 완료: %s\n' "${requested_order[*]}"
