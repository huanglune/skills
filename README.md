# AI Coding Skills

用于维护、同步和发布 Codex skills 的仓库。根目录 `README.md` 只保留仓库级入口信息；每个 skill 的定位、触发条件和具体用法请直接查看对应目录下的 `SKILL.md`。

## Skills

- [skill-creator](codex/skill-creator/SKILL.md)
- [taskmaster](codex/taskmaster/SKILL.md)
- [todo-list-csv](codex/todo-list-csv/SKILL.md)
- [uv](codex/uv/SKILL.md)

全局规则位于 [codex/AGENTS.md](codex/AGENTS.md)。

## 本地同步

```bash
mkdir -p ~/.codex/skills
cp codex/AGENTS.md ~/.codex/
bash scripts/sync_skills.sh --dry-run
bash scripts/sync_skills.sh
```

`scripts/sync_skills.sh` 会扫描 `codex/` 下包含 `SKILL.md` 的目录，并同步到 `~/.codex/skills/`。

## 从 Smithery 直接安装

适合消费已经发布到 Smithery 的版本，而不是直接复制当前工作树。

Quickstart：

```bash
npx @smithery/cli@latest skill add huanglune/skill-creator --agent codex --global
npx @smithery/cli@latest skill add huanglune/codex-taskmaster --agent codex --global
npx @smithery/cli@latest skill add huanglune/todo-list-csv --agent codex --global
npx @smithery/cli@latest skill add huanglune/uv --agent codex --global
```

批量执行：

```bash
for skill in skill-creator codex-taskmaster todo-list-csv uv; do
  npx @smithery/cli@latest skill add "huanglune/${skill}" --agent codex --global
done
```

```bash
npm install -g @smithery/cli

# 列出当前仓库有哪些 skill 可以映射成 Smithery 安装目标
bash scripts/install_smithery_skills.sh --list

# 预览单个 skill 的安装命令
bash scripts/install_smithery_skills.sh --skill taskmaster --namespace <namespace> --dry-run

# 安装单个 skill 到当前项目
bash scripts/install_smithery_skills.sh --skill taskmaster --namespace <namespace>

# 安装全部 skill 到当前项目
bash scripts/install_smithery_skills.sh --all --namespace <namespace>

# 或者全局安装到当前 agent
bash scripts/install_smithery_skills.sh --all --namespace <namespace> --global
```

说明：

- 上面的 `npx @smithery/cli@latest ... --global` 会安装到 `~/.agents/skills/`。
- `scripts/install_smithery_skills.sh` 只根据 `codex/` 下包含 `SKILL.md` 的目录推导安装目标名。
- `taskmaster` 为避开 Smithery 上的 slug 冲突，远端发布名为 `codex-taskmaster`，但安装到本地后仍然是 `taskmaster`。
- 项目级安装会在当前目录生成 `./.agents/skills/` 和 `./skills-lock.json`。
- `--global` 会改为写入 `~/.agents/skills/` 和 `~/.agents/.skill-lock.json`。
- 只有当对应 skill 已经发布到目标 namespace 时，安装才会成功；未发布时会由 `smithery skill add` 显式报错。

## 发布到 Smithery

```bash
npm install -g @smithery/cli
smithery auth login

# 列出可发布的 skills
bash scripts/publish_smithery_skills.sh --list

# 预览单个 skill 的发布命令
bash scripts/publish_smithery_skills.sh --skill taskmaster --dry-run

# 发布单个 skill
bash scripts/publish_smithery_skills.sh --skill taskmaster --namespace <namespace>

# 发布全部 skills
bash scripts/publish_smithery_skills.sh --all --namespace <namespace>
```

`scripts/publish_smithery_skills.sh` 只处理 `codex/` 下包含 `SKILL.md` 的 skill 目录。
其中 `taskmaster` 会发布到 `codex-taskmaster` slug，以避开 Smithery 上的同名条目冲突。
