---
name: orchestrate-embedded-development
description: 统筹本库的嵌入式软件研发技能。用户要求端到端推进需求、架构、详细设计、编码、验证或发布，判断跨阶段下一步，协调多个 Skill，或闭环影响多个工程工作产品的变更与问题时使用
---

# 嵌入式软件研发总控

把本 Skill 当作控制塔：维护当前任务的主线、横切过程、门禁与回环。专项 Skill 是其领域步骤和工作产品的单一事实源；总控只负责选择、编排和验收

## 1. 建立控制视图

读取用户请求、仓库现状和已有工程证据，明确：

- 本次目标与可交付结果
- 当前生命周期位置、已确认事实和输入缺口
- 一个主意图、必要的横切过程及最早受影响阶段
- 可检验的整体完成条件

边界清晰的单过程请求直接路由一个专项 Skill。跨阶段请求、影响多个工作产品的事件或用户明确要求总控时，再建立多 Skill 执行链

本步骤完成于主意图、首个执行 Skill、必要叠加、输入、产物和整体完成条件全部明确

## 2. 选择最小路由

按用户真正需要的产物选择最小 Skill 集。以表中名称显式调用所选 Skill；实际执行前，完整加载其 `SKILL.md` 及其明确要求的参考资料

| 主意图或产物 | 路由 |
|---|---|
| 定义产品问题、价值、范围与发布计划 | `$create-prd` |
| 统一领域术语或记录满足门槛的 ADR | `$domain-modeling` |
| 建立可开发、可验证的软件需求基线 | `$aspice-analyze-software-requirements` |
| 建立软件组件、接口、动态行为与资源约束的正式架构证据 | `$aspice-design-software-architecture` |
| 扫描全仓架构摩擦并生成候选报告 | `$improve-codebase-architecture` |
| 设计局部 module、interface、seam 或 adapter | `$codebase-design` |
| 建立软件单元详细设计并连接实现 | `$aspice-design-and-build-units` |
| 将稳定的计划或规格拆成带依赖的执行票据 | `$to-tickets` |
| 诊断 HardFault、卡死、复位、数据异常、竞态、时序或性能退化 | `$diagnosing-embedded-bugs` |
| 编写、修改或审查嵌入式 C、固件、驱动、HAL 或 RTOS 代码 | `$embedded-c-coding` |
| 审查固定点到 `HEAD` 的代码变更 | `$code-review` |
| 形成静态分析、代码评审、单元测试与覆盖率证据 | `$aspice-verify-software-units` |
| 验证组件行为、接口、交互、时序与集成顺序 | `$aspice-verify-software-integration` |
| 验证集成软件对软件需求的覆盖并形成发布结论 | `$aspice-verify-software` |
| 用户明确要求压力测试计划、决定或想法 | `$grilling` |

按事件或持续治理需要叠加横切过程：

| 横切意图 | 路由 |
|---|---|
| 维护范围、进度、工作包、依赖、里程碑、风险或资源 | `$aspice-manage-project` |
| 管理配置项、分支与版本规则、开发或发布基线 | `$aspice-manage-configuration` |
| 登记、复现、分析、修复、回归和关闭问题 | `$aspice-resolve-problems` |
| 分析并批准对受控工作产品的变更，跟踪实施与关闭 | `$aspice-manage-changes` |

使用以下消歧规则确定主路由：

- `requirements`：产品 why/what 归 `$create-prd`；软件可开发与可验证基线归 SWE.1
- `architecture`：全仓候选扫描归 `$improve-codebase-architecture`；局部接口设计归 `$codebase-design`；正式 ASPICE 架构证据归 SWE.2
- `review`：PRD 评审归 `$create-prd`；固定点代码 diff 归 `$code-review`；嵌入式 C diff 同时采用 `$embedded-c-coding` 的标准
- `plan`：产品范围与发布归 `$create-prd`；项目资源、里程碑和风险归 MAN.3；可执行票据与阻塞边归 `$to-tickets`
- `problem/change`：SUP.9 解释问题及其关闭；需要改变受控工作产品时再由 SUP.10 管理批准与影响
- `diagnosis/problem`：技术根因定位归 `$diagnosing-embedded-bugs`；需要持久化问题状态和关闭证据时叠加 SUP.9
- `verification`：SWE.4 面向软件单元，SWE.5 面向组件与集成，SWE.6 面向软件需求

本步骤完成于每个所选 Skill 都对交付结果承担唯一且必要的职责

## 3. 安排主线、横切与回环

默认工程主线为：

```text
PRD → SWE.1 → SWE.2 → SWE.3 / 嵌入式 C 实现 → SWE.4 → SWE.5 → SWE.6
```

只在术语真实变化时叠加领域建模；只在规格已经稳定时进入票据拆分。MAN.3 和 SUP.8 可随主线持续推进，SUP.9 与 SUP.10 由事件触发

允许前置验证策划和按组件形成流水线：SWE.6 计划可在 SWE.1 稳定后开始，SWE.5 计划可在架构与接口明确后开始，已满足局部准入条件的组件可先进入后续验证。共享同一工作产品或依赖同一未决决定的任务串行执行，其余独立支线可并行

验证异常按以下闭环回流：

```text
验证异常 → 技术诊断 → SUP.9 → 必要时 SUP.10 → 最早受影响的 SWE.1 / SWE.2 / SWE.3
        → 受影响的 SWE.4 / SWE.5 / SWE.6 回归 → SUP.8 更新基线 → 关闭事件
```

已基线化的需求或接口变更先进入 SUP.10；尚未基线化的澄清直接回到相应工程阶段

本步骤完成于每条路由都有明确的前置输入、串并行关系和回流点，所有共享工作产品均由单一路由顺序写入

## 4. 执行并守住门禁

向每个专项 Skill 传递同一份交接包：目标、证据路径、输入状态、预期产物、上游决定、约束、门禁和完成条件。让专项 Skill 自行执行其完整步骤，并在返回后核对产物、证据状态和追溯关系

按以下优先级解决冲突：

1. 用户明确指定的范围与授权
2. `$embedded-c-coding` 的内存、并发、实时性、硬件交互和编辑后安全检查
3. 当前主流程的副作用门禁
4. 已确认的需求、仓库标准、ADR 与领域词汇
5. ASPICE 过程证据要求
6. 通用设计原则和代码味道启发式

守住组合门禁：

- `$grilling` 激活后只进行只读查证和逐问决策，达成共同理解后再恢复实施
- `$improve-codebase-architecture` 先交付候选报告；用户选中候选后再进入接口设计或实施
- `$to-tickets` 先提交方案；获得用户确认后再发布票据
- `$code-review` 在固定点可解析且 diff 非空后开始，保持只读并输出一份双轴报告
- `$code-review` 与 `$embedded-c-coding` 组合为一份双轴报告，由后者提供 Standards 轴约束
- `$improve-codebase-architecture` 单独承担全仓扫描，并复用 `$codebase-design` 的词汇
- 通用设计语境使用 module/interface/seam/adapter；SWE.2 与 SWE.3 工作产品保留 ASPICE 的软件组件、软件单元和接口术语，必要时显式建立映射

本步骤完成于每个路由达到其自身完成条件，且全部跨路由门禁、写冲突和安全约束已核对

## 5. 聚合并闭环

聚合各路由的结果，核对需求、架构、详细设计、代码、验证和配置项之间的追溯。当前执行状态只在本轮控制视图中维护；持久化项目状态归 MAN.3，基线状态归 SUP.8，问题和变更分别归 SUP.9 与 SUP.10

最终摘要至少给出：

- 已完成的路由及其结论
- 已创建或更新的工作产品路径
- 验证与基线状态
- 明确延期或阻塞的影响项及原因
- 下一条最小路由

总控完成于每个受影响项均已完成、明确延期或记录阻塞，且最终摘要能从目标追溯到产物与证据
