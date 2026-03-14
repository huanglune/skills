# AI Coding Skills

个人可复用的 AI 编程技能包，包含 Codex Skills，以及面向 Claude Code 的协作编排协议。

## 快速部署

```bash
git clone <repo-url>

# Codex Skills → ~/.codex/
mkdir -p ~/.codex/skills
cp codex/AGENTS.md ~/.codex/
bash scripts/sync_skills.sh --dry-run
bash scripts/sync_skills.sh

# Claude Code 协作协议可直接作为上下文使用
# 详见 codex/codex-atelier/PROMPT.md
```

`scripts/sync_skills.sh` 会自动发现 `codex/` 下所有包含 `SKILL.md` 的技能目录，并逐个同步到 `~/.codex/skills/`。它不会把 `codex/AGENTS.md` 当作 skill 同步，也不会删除你本机已有的其他无关 skills；对于同名技能目录，会用 `rsync --delete` 按仓库内容镜像更新。`--dry-run` 只预览将要执行的同步动作。

## 同步脚本

仓库根目录提供了 [`scripts/sync_skills.sh`](scripts/sync_skills.sh)，用于把当前仓库里的 skills 同步到本机。

用法：

```bash
bash scripts/sync_skills.sh --dry-run
bash scripts/sync_skills.sh
```

行为说明：

- 自动扫描 `codex/` 下所有包含 `SKILL.md` 的目录
- 目标路径固定为 `~/.codex/skills/`
- 不会把 `codex/AGENTS.md` 误当作 skill 复制
- 不会删除本机其他无关的 skills
- 会对同名 skill 目录做镜像同步

## Codex Skills

### 1. skill-creator — Skill 创建向导

这是一个"用来创建 Skill 的 Skill"，指导如何把某类知识、流程、工具封装成可复用的技能包。

核心结构：

- `SKILL.md`（必需）：YAML 元数据 + Markdown 指令，决定 Skill 何时触发、如何使用
- `scripts/`：可执行脚本，适合需要确定性执行的重复操作
- `references/`：参考文档，按需读入上下文（API 文档、schema 等）
- `assets/`：输出资源（模板、图片、字体），不需要读入上下文

创建流程 6 步：

1. 通过具体例子理解 Skill 要解决什么问题
2. 从例子中抽象可复用内容（脚本、文档、模板）
3. `init_skill.py` 初始化目录骨架
4. 编辑 SKILL.md 和资源文件
5. `package_skill.py` 校验 + 打包成 zip
6. 实际使用后迭代改进

渐进式披露设计：元数据始终在上下文（~100词）→ SKILL.md 触发时加载（<5k词）→ 资源按需展开（无限），最大化节省 token。

### 2. taskmaster — 多步骤任务执行协议（v5）

这是 Codex 处理多步骤工程任务的默认执行协议，核心价值在于把长任务变成可落盘、可验证、可恢复、可升级、可并发的执行流程。

三种任务形态：

| 形态 | 适用场景 | 真相文件 | 示例 |
|------|---------|---------|------|
| Single Task | 单个交付物 | `TODO.csv` 或 `SPEC.md + TODO.csv + PROGRESS.md` | 修一个 OAuth bug |
| Epic Task | 多模块/多依赖链 | `EPIC.md + SUBTASKS.csv + PROGRESS.md` | 跨 API/UI/文档的 billing dashboard |
| Batch Task | 同质行级并发 | `BATCH.md + workers-input/output.csv` | 审计 80 个 Markdown 文件 |

关键设计原则：

- CSV 真相源：磁盘文件优先于聊天记忆
- 显式验证门：没验证就不能标 DONE
- Debug-First：失败必须暴露，不能静默降级
- 上下文恢复：冷启动仅靠文件即可恢复，恢复消息包含 任务/形态/进度/当前/文件/下一步 六个字段
- 支持中途升级：Single→Epic，Single/Epic 步骤→Batch

### 3. todo-list-csv — 轻量级 CSV 任务跟踪

面向"会改动项目内容"的任务，在项目根目录创建临时 CSV 清单，与 `update_plan` 双轨同步，完成后自动删除。

工作流：

1. 拆任务为 3-12 个可验收步骤，同时建立 `update_plan`
2. 在项目根创建 `{任务名} TO DO list.csv`，表头 `id,item,status,done_at,notes`
3. 状态机严格单向：`TODO → IN_PROGRESS → DONE`，任意时刻最多 1 行 IN_PROGRESS
4. 每完成一项，先更新 CSV，再通过 `plan --normalize` 同步到 `update_plan`
5. 全部 DONE 后删除 CSV，避免遗留在仓库

自动化脚本 `todo_csv.py` 支持：`init`（创建）、`advance`（推进一步）、`start`（指定开始）、`plan`（生成 plan JSON）、`status`（查看进度）、`cleanup`（清理）等命令。

### 4. codex-atelier — Claude Code 架构工坊协议

这是一个面向 Claude Code 的协作编排 Skill，用来固定“Claude 做架构与调度，Codex 做执行、评审、验证”的分工。

适用场景：

- 需要先做架构简报，再把任务拆成多个 Codex 工作包
- 中高风险任务不能只依赖单个执行结果，需要 Reviewer 或 Verifier
- 复杂项目需要多个 Codex 并行执行，并由 Claude 统一裁决冲突

核心约束：

- Claude 负责目标澄清、架构拆解、任务编排、质量仲裁
- Codex 按角色承担 `Executor`、`Reviewer`、`Verifier`、`Investigator`
- 每个工作包都要带目标、上下文、文件边界、验证命令、完成定义
- 交付时只汇总真实执行结果和证据，不接受伪成功或静默降级

主要文件：

- `SKILL.md`：说明何时触发、如何路由协作拓扑
- `PROMPT.md`：可直接作为 Claude Code 协议文本使用
- `references/cross-check.md`：交叉检查细则
- `references/examples.md`：工作包样例与模板

### 对比

| | taskmaster | todo-list-csv | skill-creator | codex-atelier |
|---|---|---|---|---|
| 定位 | 重量级任务执行协议 | 轻量级 CSV 跟踪 | 元工具（创建 Skill） | Claude Code 协作编排协议 |
| 适合 | 复杂长任务、自主执行 | 中等复杂度改动任务 | 封装新的可复用技能包 | Claude 做架构、Codex 做执行的多代理协作 |

## 目录结构

```text
skills/
├── README.md
├── scripts/
│   └── sync_skills.sh         # 自动同步 codex/ 下的 skills 到 ~/.codex/skills/
└── codex/
    ├── AGENTS.md              # 全局 Agent 规则（部署到 ~/.codex/，不是 skills/）
    ├── codex-atelier/
    │   ├── SKILL.md
    │   ├── PROMPT.md
    │   └── references/        # cross-check.md, examples.md
    ├── skill-creator/
    │   ├── SKILL.md
    │   ├── LICENSE.txt
    │   └── scripts/           # init_skill.py, package_skill.py, quick_validate.py
    ├── taskmaster/
    │   ├── SKILL.md
    │   └── assets/            # 模板文件（SPEC、PROGRESS、TODO CSV、EPIC、BATCH 等）
    └── todo-list-csv/
        ├── SKILL.md
        └── scripts/           # todo_csv.py
```

## 依赖

- Python 3（辅助脚本）
- rsync（`scripts/sync_skills.sh` 依赖）
- [OpenAI Codex CLI](https://github.com/openai/codex)

## 配置 Codex MCP（在 Claude Code 中调用 Codex）

将 Codex 注册为 Claude Code 的 MCP Server 后，Claude 可以把子任务分发给 Codex 并行执行。

### 1. 安装 Codex CLI

```bash
npm install -g @openai/codex
codex login
```

### 2. 注册 MCP Server

编辑 `~/.claude.json`，在 `mcpServers` 中添加：

macOS / Linux：

```json
{
  "codex": {
    "command": "codex",
    "args": ["mcp-server"],
    "type": "stdio"
  }
}
```

Windows：

```json
{
  "codex": {
    "command": "cmd",
    "args": ["/c", "codex", "mcp-server"],
    "type": "stdio"
  }
}
```

### 3. 重启 Claude Code 并测试

```
mcp__codex__codex
参数: {"prompt": "Say hello", "sandbox": "read-only"}
```

Codex MCP 暴露两个工具：

| 工具 | 功能 |
|------|------|
| `codex` | 启动新的 Codex 会话 |
| `codex-reply` | 继续已有的 Codex 会话 |

## 引用

- 本项目的说明结构与部分组织方式参考了 [lili-luo/aicoding-cookbook](https://github.com/lili-luo/aicoding-cookbook)
