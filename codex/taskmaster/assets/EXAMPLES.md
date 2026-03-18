# Taskmaster v5 示例

## 单任务：Compact

**场景**：在一小组脚本里统一重命名一个 CLI flag。

```csv
id,task,status,completed_at,notes
1,定位受影响的脚本,IN_PROGRESS,,
2,重命名 flag,TODO,,
3,执行冒烟测试,TODO,,
```

## 单任务：Full

**场景**：修复一个 OAuth 回调 bug，并保留完整恢复能力。

```text
.codex-tasks/20260313-101530-auth-fix/
├── SPEC.md
├── TODO.csv
├── PROGRESS.md
└── raw/
```

## Epic 任务

**场景**：同时交付账单看板的后端、前端和文档。

```text
.codex-tasks/20260313-103000-billing-epic/
├── EPIC.md
├── SUBTASKS.csv
├── PROGRESS.md
└── tasks/
    ├── 20260313-103500-api/
    ├── 20260313-104200-frontend/
    └── 20260313-104800-docs/
```

```csv
id,task,task_type,status,depends_on,task_dir,acceptance_criteria,validation_command,completed_at,retry_count,notes
1,实现账单 API,single-full,DONE,,tasks/20260313-103500-api,API 测试通过,pytest tests/billing_api.py,2026-03-13 10:12 CST,0,
2,构建账单 UI,single-full,IN_PROGRESS,1,tasks/20260313-104200-frontend,界面能正确渲染发票,npm test -- --grep billing,,0,
3,更新账单文档,batch,TODO,1;2,tasks/20260313-104800-docs,所有文档行都成功,python3 scripts/validate_docs.py,,0,
```

## Batch 任务

**场景**：审计 80 个 Markdown 文件的 frontmatter 一致性。

```text
.codex-tasks/20260313-111500-doc-audit/
├── SPEC.md
├── TODO.csv
├── PROGRESS.md
├── batch/
│   ├── BATCH.md
│   ├── workers-input.csv
│   └── workers-output.csv
└── raw/
```

```csv
id,file_path,target_rule,notes
1,docs/a.md,frontmatter-required,
2,docs/b.md,frontmatter-required,
3,docs/c.md,frontmatter-required,
```

```csv
id,status,summary,changed,evidence_path,error
1,DONE,Frontmatter 已经有效,false,artifacts/a.json,
2,FAILED,缺少 title,false,artifacts/b.json,missing title
3,DONE,Frontmatter 已修复,true,artifacts/c.json,
```

## 混合子任务的 Epic（端到端）

**场景**：交付一个 i18n 系统，包括后端 API（Single）、前端集成
（Single），以及 40 个 locale 文件的批量翻译（Batch）。

### 目录结构

```text
.codex-tasks/20260313-140000-i18n-epic/
├── EPIC.md
├── SUBTASKS.csv
├── PROGRESS.md
└── tasks/
    ├── 20260313-140500-i18n-api/    ← single-full 子任务
    │   ├── SPEC.md
    │   ├── TODO.csv
    │   └── PROGRESS.md
    ├── 20260313-141200-i18n-frontend/ ← single-full 子任务
    │   ├── SPEC.md
    │   ├── TODO.csv
    │   └── PROGRESS.md
    └── 20260313-141900-i18n-translate/ ← batch 子任务
        ├── SPEC.md
        ├── TODO.csv                 ← 3 步 Batch 计划
        ├── PROGRESS.md
        └── batch/
            ├── BATCH.md
            ├── workers-input.csv
            └── workers-output.csv
```

### SUBTASKS.csv

```csv
id,task,task_type,status,depends_on,task_dir,acceptance_criteria,validation_command,completed_at,retry_count,notes
1,实现 i18n API,single-full,DONE,,tasks/20260313-140500-i18n-api,API 能返回翻译后的文案,pytest tests/i18n_api.py,2026-03-13 09:40 CST,0,
2,在前端集成 i18n,single-full,IN_PROGRESS,1,tasks/20260313-141200-i18n-frontend,界面能按所选语言渲染,npm test -- --grep i18n,,0,
3,批量翻译 40 个 locale 文件,batch,TODO,1,tasks/20260313-141900-i18n-translate,所有 locale 行都通过,test -f tasks/20260313-141900-i18n-translate/batch/workers-output.csv,,0,
```

### Batch 子任务 TODO.csv（tasks/20260313-141900-i18n-translate/）

```csv
id,task,status,acceptance_criteria,validation_command,completed_at,retry_count,notes
1,从 locales/ 构建 workers-input.csv,TODO,batch/workers-input.csv exists,test -f batch/workers-input.csv,,0,
2,运行 spawn_agents_on_csv,TODO,batch/workers-output.csv exists,test -f batch/workers-output.csv,,0,
3,合并结果并处理失败项,TODO,所有行都通过或被接受,grep -c FAILED batch/workers-output.csv | grep -q ^0$,,0,
```

### Batch 子任务 workers-input.csv

```csv
id,file_path,source_lang,target_lang
1,locales/en.json,en,zh
2,locales/en.json,en,ja
3,locales/en.json,en,ko
...
40,locales/en.json,en,pt
```

### Batch 子任务 workers-output.csv（运行后）

```csv
id,status,summary,changed,evidence_path,error
1,DONE,已翻译 182 个键,true,artifacts/zh.json,
2,DONE,已翻译 182 个键,true,artifacts/ja.json,
3,FAILED,有 3 个键无法翻译,false,artifacts/ko.json,keys: date_fmt; plural_rule; honorific
```

在这个例子里，Epic 父任务会等待 1-3 号子任务全部到达 `DONE`。
3 号子任务（Batch）会先通过 `workers-input-retry.csv` 内部重试失败行，
再决定是否向上升级处理。

## 任务完成后的追问

**场景**：上一轮刚修完一个 benchmark 报告问题，下一轮用户改问
“`Ready RSS`、`Footprint`、`Thread Amp`、`Search Delta` 分别是什么意思？”

- 先把这四个指标当作当前回合的唯一锚点。
- 可以复用 `SPEC.md`、`PROGRESS.md`、代码和报告作为背景证据。
- 不要重复上一轮的修复总结，也不要把 `task_complete` 的内容当成这轮答案。
