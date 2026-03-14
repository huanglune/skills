# Codex Skills

个人可复用的 Codex 技能包，用于换机器时一键部署到 `~/.codex/skills/`。

## 快速部署

```bash
# 克隆仓库后，将文件复制到 Codex 配置目录
git clone <repo-url>
cp codex/AGENTS.md ~/.codex/
cp -r codex/skill-creator ~/.codex/skills/
cp -r codex/taskmaster ~/.codex/skills/
cp -r codex/todo-list-csv ~/.codex/skills/
```

## 包含的 Skills

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

### 对比

| | taskmaster | todo-list-csv | skill-creator |
|---|---|---|---|
| 定位 | 重量级任务执行协议 | 轻量级 CSV 跟踪 | 元工具（创建 Skill） |
| 适合 | 复杂长任务、自主执行 | 中等复杂度改动任务 | 封装新的可复用技能包 |

## 目录结构

```text
skills/
├── README.md
└── codex/
    ├── AGENTS.md              # 全局 Agent 规则（部署到 ~/.codex/，不是 skills/）
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
