#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly CODEX_SOURCE_ROOT="${REPO_ROOT}/codex"

DRY_RUN=0
LIST_ONLY=0
PUBLISH_ALL=0
TARGET_SKILL=""
TARGET_NAMESPACE=""

usage() {
  cat <<'EOF'
用法:
  bash scripts/publish_smithery_skills.sh --list
  bash scripts/publish_smithery_skills.sh --skill <name> [--namespace <namespace>] [--dry-run]
  bash scripts/publish_smithery_skills.sh --all [--namespace <namespace>] [--dry-run]

说明:
  - 只发现 `codex/` 下包含 `SKILL.md` 的目录
  - `--dry-run` 只打印将要执行的 `smithery skill publish` 命令
  - `taskmaster` 会发布到 `codex-taskmaster` slug，以避开 Smithery 上的同名冲突
  - 实际发布前要求本机已完成 `smithery auth login`
EOF
}

fail() {
  printf '错误: %s\n' "$1" >&2
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list)
        LIST_ONLY=1
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --all)
        PUBLISH_ALL=1
        ;;
      --skill)
        shift
        [[ $# -gt 0 ]] || fail "--skill 需要一个技能名"
        TARGET_SKILL="$1"
        ;;
      --namespace)
        shift
        [[ $# -gt 0 ]] || fail "--namespace 需要一个命名空间名"
        TARGET_NAMESPACE="$1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "未知参数: $1"
        ;;
    esac
    shift
  done

  if [[ "$LIST_ONLY" -eq 1 ]]; then
    return
  fi

  if [[ "$PUBLISH_ALL" -eq 1 && -n "$TARGET_SKILL" ]]; then
    fail "--all 与 --skill 不能同时使用"
  fi

  if [[ "$PUBLISH_ALL" -eq 0 && -z "$TARGET_SKILL" ]]; then
    fail "请使用 --list、--skill <name> 或 --all"
  fi
}

require_smithery() {
  command -v smithery >/dev/null 2>&1 || fail "未找到 smithery CLI，请先安装并加入 PATH。"
}

discover_skills() {
  local skill_md
  local skill_dir

  while IFS= read -r skill_md; do
    [[ -n "$skill_md" ]] || continue
    skill_dir="$(dirname "$skill_md")"
    printf '%s\n' "$skill_dir"
  done < <(find "$CODEX_SOURCE_ROOT" -type f -name 'SKILL.md' | LC_ALL=C sort)
}

resolve_targets() {
  local -a available_skills=()
  local skill_dir

  while IFS= read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    available_skills+=("$skill_dir")
  done < <(discover_skills)

  [[ ${#available_skills[@]} -gt 0 ]] || fail "在 ${CODEX_SOURCE_ROOT} 下未发现任何包含 SKILL.md 的技能目录。"

  if [[ "$LIST_ONLY" -eq 1 || "$PUBLISH_ALL" -eq 1 ]]; then
    printf '%s\n' "${available_skills[@]}"
    return
  fi

  skill_dir="${CODEX_SOURCE_ROOT}/${TARGET_SKILL}"
  [[ -f "${skill_dir}/SKILL.md" ]] || fail "未找到技能: ${TARGET_SKILL}"
  printf '%s\n' "$skill_dir"
}

skill_slug_for_name() {
  local skill_name="$1"

  case "$skill_name" in
    taskmaster)
      printf 'codex-taskmaster\n'
      ;;
    *)
      printf '%s\n' "$skill_name"
      ;;
  esac
}

require_auth() {
  if [[ "$LIST_ONLY" -eq 1 || "$DRY_RUN" -eq 1 ]]; then
    return
  fi

  smithery auth whoami >/dev/null 2>&1 || fail "当前未登录 Smithery，请先执行 smithery auth login。"
}

print_command() {
  printf '%q ' "$@"
  printf '\n'
}

publish_one_skill() {
  local skill_dir="$1"
  local skill_name
  local skill_slug
  local -a cmd

  skill_name="$(basename "$skill_dir")"
  skill_slug="$(skill_slug_for_name "$skill_name")"
  cmd=(smithery skill publish "$skill_dir")

  if [[ -n "$TARGET_NAMESPACE" ]]; then
    cmd+=(--namespace "$TARGET_NAMESPACE")
  fi
  cmd+=(--name "$skill_slug")

  printf '==> %s\n' "$skill_name"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] '
    print_command "${cmd[@]}"
    return
  fi

  "${cmd[@]}"
}

list_skills() {
  local skill_dir
  local skill_name
  local skill_slug
  while IFS= read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    skill_slug="$(skill_slug_for_name "$skill_name")"
    printf '%s\t%s\t%s\n' "$skill_name" "$skill_slug" "$skill_dir"
  done < <(resolve_targets)
}

main() {
  local skill_dir

  parse_args "$@"
  require_smithery

  if [[ "$LIST_ONLY" -eq 1 ]]; then
    list_skills
    return
  fi

  require_auth
  while IFS= read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    publish_one_skill "$skill_dir"
  done < <(resolve_targets)
}

main "$@"
