# Codex Atelier Examples

## 示例 1：标准任务

用户请求：

```text
修复注册接口偶发返回 500 的问题，并补最关键的回归测试。
```

Claude 的拓扑选择：

- Executor：定位根因并实现修复
- Reviewer：独立审查是否遗漏边界条件

工作包示例：

```text
角色: Executor

任务目标
- 修复注册接口偶发 500 的问题

上下文
- 仓库: /repo
- 背景: 线上日志显示在邮箱重复和验证码超时场景下出现 500
- 关联文件: routes/auth.ts, services/register.ts, tests/register.test.ts

文件边界
- 允许修改: routes/auth.ts, services/register.ts, tests/register.test.ts
- 禁止修改: package.json, infra/*

完成定义
- 重复邮箱与过期验证码都返回明确业务错误，不再抛出 500
- 新增回归测试覆盖两个场景

验证命令
- npm test -- register
```

## 示例 2：复杂任务

用户请求：

```text
把支付模块拆成可扩展结构，并确保历史支付流程不回归。
```

Claude 的拓扑选择：

- Executor A：按支付方式拆分
- Executor B：按职责拆分
- Reviewer：比较两种方案的维护成本和风险
- Verifier：独立跑回归命令

适用原因：

- 实现方案不唯一
- 模块风险高
- 需要把“如何拆”与“拆完是否稳”分开验证

## 示例 3：架构简报模板

```text
目标
- 交付什么:

非目标
- 明确不做什么:

约束
- 技术约束:
- 时间约束:

影响范围
- 模块:
- 文件:

风险
- 已知风险:
- 未知项:

执行拓扑
- 选择: 轻量 / 标准 / 复杂
- 原因:

Codex 工作包
1. 角色:
   目标:
   文件边界:
   验证命令:
2. 角色:
   目标:
   文件边界:
   验证命令:

完成定义
- 必须满足:
```

## 示例 4：冲突复核模板

```text
角色: Investigator

争议点
- Reviewer 认为缓存失效逻辑遗漏，Executor 认为已有覆盖

证据 A
- Executor 提供的单测输出与变更摘要

证据 B
- Reviewer 指出的具体代码路径和未覆盖分支

任务要求
- 判断谁的证据更强
- 如果都不充分，指出下一步最小验证动作
```
