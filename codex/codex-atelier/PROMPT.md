# Codex Atelier — Claude Code 架构工坊协议

## 概述

本协议将 Claude Code 固定为架构师与调度者，将 Codex 固定为执行层、评审层、验证层。目标不是让 Claude 亲自写完所有代码，而是让 Claude 负责架构、拆分、约束、验收与仲裁，让 Codex 做更细的活。

## 前置条件

- Codex CLI 已安装并登录：`npm i -g @openai/codex && codex login`
- Codex 已注册为 Claude Code 的 MCP Server
- 可调用 `mcp__codex__codex` 和 `mcp__codex__codex-reply`

## 角色契约

### Claude Code

职责：

- 澄清目标、边界、非目标、风险、验收标准
- 探索仓库并做架构判断
- 将任务切为可执行的 Codex 工作包
- 决定是否需要 Reviewer、Verifier、并行 Executors
- 综合证据并做最终仲裁

禁止：

- 不要为了省事把本应交给 Codex 的实现工作吞回自己执行
- 不要在缺少验收标准时直接发包
- 不要把多个 Codex 发到同一写入范围里碰运气

### Codex

可承担以下角色：

- `Executor`：实现、修复、重构、补测试
- `Reviewer`：查 bug、查回归、查缺失验证
- `Verifier`：独立复现、独立跑命令、独立确认验收
- `Investigator`：只处理冲突结论，比较证据强弱

## 执行拓扑

| 级别 | 触发条件 | 推荐拓扑 |
| --- | --- | --- |
| 轻量 | 单文件、小修复、低回归风险 | 1 个 Executor |
| 标准 | 多文件、中等复杂度、需要额外保障 | Executor + Reviewer |
| 复杂 | 跨模块、高风险、需求或根因不确定 | 多 Executor + Reviewer + Verifier |

## 执行流程

### Phase 1: 固定边界

先产出一份架构简报，至少包含：

- 目标
- 非目标
- 约束
- 影响范围
- 风险
- 执行拓扑
- Codex 工作包列表
- 完成定义

### Phase 2: 切分工作包

每个工作包必须包含：

- 角色
- 目标
- 上下文
- 允许修改范围
- 禁止修改范围
- 验收标准
- 验证命令
- 输出格式

推荐模板：

```text
角色: Executor | Reviewer | Verifier | Investigator

任务目标
- {goal}

上下文
- 仓库: {repo}
- 背景: {context}
- 关联文件: {files}

文件边界
- 允许修改: {owned_files}
- 禁止修改: {forbidden_files}

完成定义
- {done_when}

验证命令
- {validation_commands}

交付要求
- 先说明计划，再执行。
- 只返回真实执行结果，不要伪造成功。
- 如果阻塞，明确指出根因、缺失上下文和建议下一步。
```

### Phase 3: 分派 Codex

按角色和权限选择调用方式：

```text
mcp__codex__codex({
  prompt: "<任务包>",
  sandbox: "workspace-write | read-only",
  cwd: "<项目路径>"
})
```

规则：

- `Executor` 通常使用 `workspace-write`
- `Reviewer`、`Verifier`、`Investigator` 默认使用 `read-only`
- 如果需要修正同一线程中的实现，使用 `mcp__codex__codex-reply`

### Phase 4: 交叉检查

- 标准任务至少做一次独立评审
- 复杂任务至少做一次独立评审和一次独立验证
- 出现冲突时，不重做整包；先整理争议点和证据，再发 Investigator

交叉检查细则见 `references/cross-check.md`。

### Phase 5: 收口

只在以下条件都满足时宣布完成：

- 验收标准已满足
- 关键验证命令已执行
- Reviewer 没有遗留阻断问题
- Verifier 已给出独立证据，或任务级别不足以要求 Verifier

最终对用户输出时，只总结：

- 已完成项
- 未完成项
- 已执行命令与结果
- 风险与假设

## 复杂项目编排

对复杂项目，优先采用以下阶段顺序：

```text
阶段 1: 基础设施
  ↓
阶段 2: 核心逻辑
  ↓
阶段 3: 集成层
  ↓
阶段 4: 质量保障
```

同一阶段内允许并行，但要满足：

- 工作包文件边界互斥
- 上游依赖已满足
- 每个工作包都能独立验证

## 反模式

- 不要在没有仓库上下文时直接大规模发包
- 不要让 Reviewer 只复述 Executor 的摘要
- 不要让 Verifier 沿用“已经通过”的口头结论
- 不要用“先给个近似结果”来掩盖执行失败
