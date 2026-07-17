# my-skills

面向嵌入式软件研发的个人 Agent Skills 库，覆盖产品范围、ASPICE 软件工程过程、嵌入式 C 实现与审查、问题诊断和工程治理

## 使用入口

- 边界明确的单项任务直接描述目标，由对应 model-invoked skill 自动触发
- 跨需求、架构、编码、验证或发布的任务显式使用 `$orchestrate-embedded-development`
- 不确定该走哪条工程路径时，也从总控开始；它只选择最小 skill 集，不重复专项流程内容

## 三层结构

| 层级 | 责任 | 主要内容 |
|---|---|---|
| 路由层 | 选择主线、横切过程和回流点 | `orchestrate-embedded-development` |
| 工作流层 | 执行一个可验收的工程活动 | ASPICE、诊断、编码、评审、PRD、票据 |
| 参考层 | 按分支提供规则、模板和平台事实 | `references/`、`assets/` |

总控默认不隐式调用，以免普通任务承担路由负载。嵌入式 C、诊断和各 ASPICE skill 使用窄触发 description，只在任务确实需要时进入上下文

## 推荐工程路径

```text
PRD → SWE.1 → SWE.2 → SWE.3 / 嵌入式 C → SWE.4 → SWE.5 → SWE.6
                         ↑
                    技术问题诊断
                         ↓
                 SUP.9 → 必要时 SUP.10
```

- `diagnosing-embedded-bugs` 负责复现、定位和验证根因
- `aspice-resolve-problems` 负责问题状态、行动和关闭证据
- `embedded-c-coding` 默认遵循项目规范，只在检测到对应平台特征时加载项目架构资料
- `to-tickets` 没有 tracker 配置时默认生成本地票据，发布外部 issue 前由用户选择目标

## 可选项目配置

需要连接真实 issue tracker 时，可在项目中创建 `docs/agents/issue-tracker.md`，写明平台、仓库或项目标识、标签和阻塞关系能力。没有该文件不会阻塞本地工作流

## 维护

运行静态校验：

```powershell
pwsh -File .\scripts\validate-skills.ps1
```

ASPICE skills 为了支持独立安装，各自携带一份文档契约。唯一编辑源是 `references/aspice-document-contract.md`，修改后运行：

```powershell
pwsh -File .\scripts\sync-aspice-contract.ps1
pwsh -File .\scripts\validate-skills.ps1
```

校验覆盖 frontmatter、目录命名、`agents/openai.yaml`、skill 调用引用、Markdown 相对链接和 ASPICE 契约一致性

`references/` 根目录保存维护者使用的原始资料，不随单个 skill 加载；运行时需要的内容只放在对应 skill 的 `references/` 或 `assets/`
