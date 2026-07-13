---
name: aspice-design-software-architecture
description: 软件架构设计并维护 SWE.2 证据及 Draw.io 架构图。用户要求划分软件组件、定义接口或动态行为、生成 draw.io 架构图，或分析 ROM、RAM、CPU、时序、并发及架构决策时使用
---

# 软件架构设计

## 执行步骤

1. 完整读取 [ASPICE 文档契约](../../references/aspice-document-contract.md)、[过程参考](references/process.md)、[Draw.io 规则](references/drawio.md) 和 [文档模板](assets/template.md)
   - 完成标准：已明确输出位置、证据规则、Draw.io 交付规则和 SWE.2 全部过程成果
2. 检查已约定的软件需求、系统架构、HSI、现有组件、平台约束和历史架构决策
   - 完成标准：每项架构输入已有证据，缺失或未约定输入已列入待确认项
3. 定义静态架构
   - 描述外部接口、软件组件、职责、接口、依赖和需求分配
   - 同步更新 Draw.io 的“静态架构”页面
   - 完成标准：每项范围内软件需求已分配到组件或有明确的跨组件处理方式，组件与依赖在图中可见
4. 定义动态架构
   - 描述模式、状态、数据流、调用关系、中断、任务、线程、时序和并发交互
   - 同步更新 Draw.io 的“动态架构”页面
   - 完成标准：关键运行场景能够从输入追踪到响应，跨上下文交互有明确约束且箭头方向清晰
5. 分析并约定架构
   - 分析功能、ROM、RAM、CPU、时序、可靠性、复用及自研或外购决策
   - 记录替代方案、选择依据、风险和验证方式
   - 完成标准：每项关键决策有依据，每项高风险约束有验证入口
6. 建立需求与架构的双向追溯并检查语义一致性
   - 完成标准：需求分配完整，架构没有无法解释的功能或接口
7. 创建或更新 `software-architecture.md` 和同目录的 `software-architecture.drawio`
   - 新建图时从 [Draw.io 模板](assets/software-architecture.drawio) 开始，Markdown 使用相对链接指向图文件
   - 校验 XML、页面、节点、连接线和模板占位内容；检测到 draw.io CLI 时导出 PNG 预览并检查布局
   - 完成标准：契约检查全部通过，图文件可由 diagrams.net 编辑，包含静态和动态两个页面且与正文一致
