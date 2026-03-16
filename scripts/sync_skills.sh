#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly CODEX_SOURCE_ROOT="${REPO_ROOT}/codex"
readonly CLAUDE_SOURCE_ROOT="${REPO_ROOT}/claude"
readonly CODEX_TARGET_ROOT="${HOME}/.codex/skills"
readonly CLAUDE_TARGET_ROOT="${HOME}/.claude/skills"

DRY_RUN=0
SKILL_RECORDS=()

usage() {
  cat <<'EOF'
用法: bash scripts/sync_skills.sh [--dry-run]

将当前仓库 `codex/` 下所有包含 SKILL.md 的技能目录同步到 ~/.codex/skills/，
并将 `claude/` 下所有包含 SKILL.md 的技能目录同步到 ~/.claude/skills/。
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

discover_skills_in() {
  local source_label="$1"
  local source_root="$2"
  local target_root="$3"
  local skill_md
  local skill_dir

  [[ -d "$source_root" ]] || return 0

  while IFS= read -r skill_md; do
    [[ -z "$skill_md" ]] && continue
    skill_dir="$(dirname "$skill_md")"
    SKILL_RECORDS+=("${source_label}"$'\t'"${skill_dir}"$'\t'"${target_root}")
  done < <(find "$source_root" -type f -name 'SKILL.md' | LC_ALL=C sort)
}

discover_skills() {
  discover_skills_in "codex" "$CODEX_SOURCE_ROOT" "$CODEX_TARGET_ROOT"
  discover_skills_in "claude" "$CLAUDE_SOURCE_ROOT" "$CLAUDE_TARGET_ROOT"

  if [[ ${#SKILL_RECORDS[@]} -eq 0 ]]; then
    echo "错误: 在 ${CODEX_SOURCE_ROOT} 与 ${CLAUDE_SOURCE_ROOT} 下均未发现任何包含 SKILL.md 的技能目录。" >&2
    exit 1
  fi
}

ensure_target_root() {
  local target_root="$1"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ ! -d "$target_root" ]]; then
      printf '[dry-run] 将创建目标目录: %s\n' "$target_root"
    fi
    return
  fi

  mkdir -p "$target_root"
}

ensure_target_roots() {
  ensure_target_root "$CODEX_TARGET_ROOT"
  ensure_target_root "$CLAUDE_TARGET_ROOT"
}

sync_one_skill() {
  local source_label="$1"
  local skill_dir="$2"
  local target_root="$3"
  local skill_name
  local target_dir
  local -a rsync_args

  skill_name="$(basename "$skill_dir")"
  target_dir="${target_root}/${skill_name}"
  rsync_args=(-a --delete --itemize-changes)

  if [[ "$DRY_RUN" -eq 1 ]]; then
    rsync_args+=(--dry-run)
  fi

  printf '==> [%s] %s -> %s\n' "$source_label" "$skill_name" "$target_dir"
  rsync "${rsync_args[@]}" "$skill_dir/" "$target_dir/"
}

main() {
  parse_args "$@"
  require_rsync
  discover_skills
  ensure_target_roots

  printf 'Codex 源目录: %s\n' "$CODEX_SOURCE_ROOT"
  printf 'Codex 目标目录: %s\n' "$CODEX_TARGET_ROOT"
  printf 'Claude 源目录: %s\n' "$CLAUDE_SOURCE_ROOT"
  printf 'Claude 目标目录: %s\n' "$CLAUDE_TARGET_ROOT"
  printf '模式: %s\n' "$( [[ "$DRY_RUN" -eq 1 ]] && echo dry-run || echo apply )"
  printf '发现 %s 个技能目录。\n' "${#SKILL_RECORDS[@]}"

  local record
  local source_label
  local skill_dir
  local target_root
  for record in "${SKILL_RECORDS[@]}"; do
    IFS=$'\t' read -r source_label skill_dir target_root <<< "$record"
    sync_one_skill "$source_label" "$skill_dir" "$target_root"
  done
}

main "$@"
