#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SOURCE_ROOT="${REPO_ROOT}/codex"
readonly TARGET_ROOT="${HOME}/.codex/skills"

DRY_RUN=0
SKILL_DIRS=()

usage() {
  cat <<'EOF'
用法: bash scripts/sync_skills.sh [--dry-run]

将当前仓库 codex/ 下所有包含 SKILL.md 的技能目录同步到 ~/.codex/skills/。
EOF
}

parse_args() {
  if [[ $# -gt 1 ]]; then
    usage >&2
    exit 1
  fi

  case "${1-}" in
    "")
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '未知参数: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

require_rsync() {
  if ! command -v rsync >/dev/null 2>&1; then
    echo "错误: 未找到 rsync，请先安装 rsync。" >&2
    exit 1
  fi
}

discover_skills() {
  local skill_md
  local skill_dir

  while IFS= read -r skill_md; do
    [[ -z "$skill_md" ]] && continue
    skill_dir="$(dirname "$skill_md")"
    SKILL_DIRS+=("$skill_dir")
  done < <(find "$SOURCE_ROOT" -type f -name 'SKILL.md' | LC_ALL=C sort)

  if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
    echo "错误: 在 ${SOURCE_ROOT} 下未发现任何包含 SKILL.md 的技能目录。" >&2
    exit 1
  fi
}

ensure_target_root() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ ! -d "$TARGET_ROOT" ]]; then
      printf '[dry-run] 将创建目标目录: %s\n' "$TARGET_ROOT"
    fi
    return
  fi

  mkdir -p "$TARGET_ROOT"
}

sync_one_skill() {
  local skill_dir="$1"
  local skill_name
  local target_dir
  local -a rsync_args

  skill_name="$(basename "$skill_dir")"
  target_dir="${TARGET_ROOT}/${skill_name}"
  rsync_args=(-a --delete --itemize-changes)

  if [[ "$DRY_RUN" -eq 1 ]]; then
    rsync_args+=(--dry-run)
  fi

  printf '==> %s\n' "$skill_name"
  rsync "${rsync_args[@]}" "$skill_dir/" "$target_dir/"
}

main() {
  parse_args "$@"
  require_rsync
  discover_skills
  ensure_target_root

  printf '源目录: %s\n' "$SOURCE_ROOT"
  printf '目标目录: %s\n' "$TARGET_ROOT"
  printf '模式: %s\n' "$([[ "$DRY_RUN" -eq 1 ]] && echo dry-run || echo apply)"
  printf '发现 %s 个技能目录。\n' "${#SKILL_DIRS[@]}"

  local skill_dir
  for skill_dir in "${SKILL_DIRS[@]}"; do
    sync_one_skill "$skill_dir"
  done

}

main "$@"
