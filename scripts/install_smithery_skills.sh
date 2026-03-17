#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly CODEX_SOURCE_ROOT="${REPO_ROOT}/codex"

DRY_RUN=0
GLOBAL_INSTALL=0
INSTALL_ALL=0
LIST_ONLY=0
TARGET_AGENT="codex"
TARGET_NAMESPACE="${SMITHERY_NAMESPACE-}"
TARGET_SKILL=""

usage() {
  cat <<'EOF'
用法:
  bash scripts/install_smithery_skills.sh --list [--namespace <namespace>]
  bash scripts/install_smithery_skills.sh --skill <name> --namespace <namespace> [--agent <agent>] [--global] [--dry-run]
  bash scripts/install_smithery_skills.sh --all --namespace <namespace> [--agent <agent>] [--global] [--dry-run]

说明:
  - 只发现 `codex/` 下包含 `SKILL.md` 的目录
  - 实际安装命令为 `smithery skill add <namespace>/<skill> --agent <agent>`
  - 默认做项目级安装，会在当前目录写入 `.agents/skills/` 和 `skills-lock.json`
  - `--global` 改为写入 `~/.agents/skills/` 与 `~/.agents/.skill-lock.json`
  - `taskmaster` 为避开 Smithery 上的 slug 冲突，远端使用 `codex-taskmaster`，安装后本地仍然是 `taskmaster`
  - 对应 skill 必须已经发布到目标 namespace，安装才会成功
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
      --skill)
        shift
        [[ $# -gt 0 ]] || fail "--skill 需要一个技能名"
        TARGET_SKILL="$1"
        ;;
      --all)
        INSTALL_ALL=1
        ;;
      --namespace)
        shift
        [[ $# -gt 0 ]] || fail "--namespace 需要一个命名空间名"
        TARGET_NAMESPACE="$1"
        ;;
      --agent)
        shift
        [[ $# -gt 0 ]] || fail "--agent 需要一个 agent 名"
        TARGET_AGENT="$1"
        ;;
      --global)
        GLOBAL_INSTALL=1
        ;;
      --dry-run)
        DRY_RUN=1
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

  if [[ "$INSTALL_ALL" -eq 1 && -n "$TARGET_SKILL" ]]; then
    fail "--all 与 --skill 不能同时使用"
  fi

  if [[ "$INSTALL_ALL" -eq 0 && -z "$TARGET_SKILL" ]]; then
    fail "请使用 --list、--skill <name> 或 --all"
  fi

  if [[ -z "$TARGET_NAMESPACE" ]]; then
    fail "请使用 --namespace <namespace> 或设置 SMITHERY_NAMESPACE"
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

  if [[ "$LIST_ONLY" -eq 1 || "$INSTALL_ALL" -eq 1 ]]; then
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

qualified_name_for_dir() {
  local skill_dir="$1"
  local skill_name
  local skill_slug

  skill_name="$(basename "$skill_dir")"
  skill_slug="$(skill_slug_for_name "$skill_name")"
  printf '%s/%s\n' "$TARGET_NAMESPACE" "$skill_slug"
}

print_command() {
  printf '%q ' "$@"
  printf '\n'
}

install_one_skill() {
  local skill_dir="$1"
  local qualified_name
  local -a cmd

  qualified_name="$(qualified_name_for_dir "$skill_dir")"
  cmd=(smithery skill add "$qualified_name" --agent "$TARGET_AGENT")

  if [[ "$GLOBAL_INSTALL" -eq 1 ]]; then
    cmd+=(--global)
  fi

  printf '==> %s\n' "$(basename "$skill_dir")"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] '
    print_command "${cmd[@]}"
    return
  fi

  "${cmd[@]}" </dev/null
}

list_skills() {
  local skill_dir
  local skill_name
  local skill_slug

  while IFS= read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    skill_slug="$(skill_slug_for_name "$skill_name")"
    if [[ -n "$TARGET_NAMESPACE" ]]; then
      printf '%s\t%s/%s\t%s\n' "$skill_name" "$TARGET_NAMESPACE" "$skill_slug" "$skill_dir"
      continue
    fi
    printf '%s\t%s\n' "$skill_name" "$skill_dir"
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

  while IFS= read -r skill_dir; do
    [[ -n "$skill_dir" ]] || continue
    install_one_skill "$skill_dir"
  done < <(resolve_targets)
}

main "$@"
