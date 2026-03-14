---
name: codex-atelier
description: >
  Orchestrate Claude Code as architect and Codex as executor, reviewer, and
  verifier. This skill should be used when Claude must stay in the architecture
  and coordination role while Codex handles implementation, debugging,
  refactors, or validation, especially for medium or complex tasks and
  multi-Codex cross-check workflows.
---

# Codex Atelier

在 Claude Code 中启用一套稳定的“架构师 + 执行工坊”协议：Claude 负责目标澄清、架构拆解、任务编排、质量仲裁；Codex 负责实现、调试、评审、验证。

## 何时使用

- 用户明确要求“Claude 做架构，Codex 做执行”。
- 任务需要先拆解为多个明确工作包，再交给 Codex 执行。
- 任务风险较高，不能只依赖单个执行结果，必须增加独立评审或独立验证。
- 复杂项目需要多个 Codex 并行处理，并由 Claude 统一裁决冲突。

## 前置条件

- 已安装并登录 Codex CLI。
- 已在 Claude Code 中注册 Codex MCP。
- 可使用 `mcp__codex__codex` 与 `mcp__codex__codex-reply`。

## 核心约束

- 保持 Claude 只做架构、协调、裁决，不吞回大段实现工作。
- 让每个 Codex 工作包都具备目标、上下文、文件边界、验证命令、完成定义。
- 对中高风险任务，拆分实现、评审、验证角色，不让同一个 Codex 同时承担最终实现和最终验收。
- 保持失败暴露，不为追求“跑通”而加入静默降级、假成功或模糊收口。

## 拓扑路由

| 场景 | 拓扑 | 说明 |
| --- | --- | --- |
| 轻量任务 | Claude -> Executor -> Claude | 单点问题、影响面小 |
| 标准任务 | Claude -> Executor -> Reviewer -> Claude | 中等复杂度，需要独立审查 |
| 复杂任务 | Claude -> 多 Executor + Reviewer + Verifier -> Claude | 跨模块、高风险、需要交叉检查 |

复杂任务通常满足以下任一条件：

- 需要跨前后端、配置、脚本、迁移等多个层次协作。
- 需要两个以上独立文件边界的工作包。
- 根因不明确，必须通过并行探索或独立验证压缩不确定性。
- 失败代价高，必须让实现与验收解耦。

## 使用顺序

1. 阅读 `PROMPT.md`，将协议作为 Claude Code 的工作指令。
2. 需要交叉检查细节时，读取 `references/cross-check.md`。
3. 需要实际任务样例或任务包模板时，读取 `references/examples.md`。

## 产出要求

- 先形成架构简报，再发 Codex 工作包。
- 执行完成后，要求每个 Codex 返回真实执行结果和证据。
- Claude 最终只汇总已验证通过的结论、风险和剩余问题。
