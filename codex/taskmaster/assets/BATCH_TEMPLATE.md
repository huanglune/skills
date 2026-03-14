# Batch 配置

> 这是通过 `spawn_agents_on_csv` 执行同构行级任务时使用的配置文件。

## Batch 目标

- <每一行都要完成什么>

## 为什么适合 Batch

- 同一个指令模板可以描述每一行
- 每一行彼此独立
- 输出可以结构化表达并匹配 schema

## 指令模板

```text
读取 {file_path}，应用 {target_rule}，并报告：
- status
- summary
- changed
- evidence_path
- error
```

## 执行设置

- **id_column**: `id`
- **output_schema**: `{ "status": "string", "summary": "string", "changed": "boolean", "evidence_path": "string", "error": "string" }`
- **max_workers**: `<N>`
- **max_runtime_seconds**: `<seconds>`
- **output_csv_path**: `batch/workers-output.csv`

## 重试策略

- 首轮执行后，把 `workers-output.csv` 中失败的行筛到 `batch/workers-input-retry.csv`。
- 用 `csv_path="batch/workers-input-retry.csv"` 重新执行 `spawn_agents_on_csv`，并把结果追加回 `workers-output.csv`。
- 最多进行 **3 次 Batch 重试**。如果 3 轮后仍失败，就把这些行标记为 `FAILED` 并写明备注，再上报父任务做人工处理。
- 每一轮重试都必须在 `PROGRESS.md` 里记录，还要写清剩余失败行数量。

## 合并策略

- 在所有行通过，或被显式接受为 `FAILED` 之前，父任务都保持 `IN_PROGRESS`。
- 失败行必须保留在 `workers-output.csv` 中，不能删除或隐藏。
- 最终重试结束后，要把总结写进 `PROGRESS.md`：总行数、通过数、失败数、接受为失败的数量。

## 调用形态示例

```text
spawn_agents_on_csv(
  csv_path="batch/workers-input.csv",
  id_column="id",
  instruction="读取 {file_path} ...",
  output_schema={...},
  max_workers=8,
  max_runtime_seconds=600,
  output_csv_path="batch/workers-output.csv"
)
```
