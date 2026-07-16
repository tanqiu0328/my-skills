> 整理：兆鸣嵌入式

# 硬件交互规则

## 导航

- 底层验证与阻塞分析
- 事件驱动和平台差异
- CMSIS-RTOS2 线程与信号量
- DMA、环形缓冲区和 Cache
- 寄存器级检查

## 基本原则：验证到底层

永远不要假设任何硬件相关的API是非阻塞的、安全的或行为符合预期的。
在使用任何HAL函数或硬件接口之前：

1. 追踪调用链到寄存器级别
2. 检查调用链中是否有任何函数可能阻塞
3. 确认项目中实际使用的HAL库版本
4. 检查项目是否自定义了任何底层实现
   （标准HAL行为可能已被修改）

## 阻塞分析

### 什么算阻塞

- 忙等循环（轮询状态寄存器）
- `HAL_Delay()` 或任何延时函数
- 在轮询模式下等待DMA完成
- 等待外设就绪标志
- Flash写入/擦除操作
- I2C/SPI轮询模式下的事务

### 验证流程

在调用任何硬件函数之前：

```
1. 打开函数实现
2. 检查每一行是否有：
   ├── 等待硬件的 while/for 循环
   ├── 调用延时函数
   ├── 调用其他函数（递归检查它们）
   └── 超时参数（意味着可能阻塞）
3. 检查项目使用的HAL版本
4. 检查项目是否重写了任何 weak HAL函数
5. 记录发现结果：阻塞还是非阻塞
```

### 示例：看似无害的API

```c
/* 这个看起来是非阻塞的，但实际上不是 */
HAL_StatusTypeDef HAL_SPI_Transmit(
    SPI_HandleTypeDef *hspi,
    uint8_t *pData,
    uint16_t Size,
    uint32_t Timeout)
{
    /* 内部在 while 循环中轮询 SPI TXE 标志！
     * 会阻塞直到所有数据发送完毕或超时。
     * 使用 HAL_SPI_Transmit_IT 或 HAL_SPI_Transmit_DMA
     * 实现非阻塞操作。 */
}
```

## 事件驱动框架 / RTC合规性

如果应用层使用事件驱动 + 状态机框架（业内有多家成熟实现可选），
或任何 RTC（Run-To-Completion，运行至完成）执行模型：

### 非阻塞强制要求

从应用层到硬件的整个调用链都必须是非阻塞的。这意味着：

1. **活动对象** 处理事件后立即返回
2. **事件处理路径中没有阻塞调用**
3. **没有忙等循环**
4. **事件处理路径中没有互斥锁等待**
5. **延迟处理** 通过内部工作线程处理可能阻塞的操作

### 事件驱动框架 / RTC下的驱动设计

```
┌──────────────────────────────────────────┐
│ 活动对象（运行至完成）                      │
│                                          │
│  on EVENT_SEND_DATA:                     │
│    driver->SendAsync(data, len);  <-- 立即返回
│    /* 继续处理 */                         │
│                                          │
│  on EVENT_DRIVER_DONE:             <-- 回调投递事件
│    handle_result(evt->result);           │
└──────────────────────────────────────────┘
         │                    ▲
         │ 入队               │ 投递事件
         ▼                    │
┌──────────────────────────────────────────┐
│ 驱动内部工作线程                           │
│                                          │
│  while (running):                        │
│    msg = queue_recv(timeout)             │
│    result = hw_operation(msg)  <-- 这里可以阻塞
│    post_event_to_app(result)      （在工作线程中没问题）
└──────────────────────────────────────────┘
```

### 周期性轮询

如果驱动需要周期性硬件轮询：

- 轮询定时器/循环在驱动的工作线程内部运行
- 驱动仅对外暴露异步API和回调
- 应用层绝不直接调用轮询函数
- 轮询间隔可配置，但默认值应定义为宏

## 平台相关注意事项

### HAL库版本

不同的HAL版本对相同API可能有不同的行为。始终检查：

1. 项目使用的HAL版本
2. 是否有HAL源文件被本地修改
3. 是否有weak回调函数被重写
4. DMA通道/流是否按预期配置

### FatFS注意事项

FatFS的不同版本差异很大。在使用任何FatFS API之前：

1. 检查项目中的FatFS版本（`ffconf.h`）
2. 确认启用了哪些可选功能
   （`FF_USE_LFN`、`FF_FS_REENTRANT` 等）
3. 检查磁盘I/O层实现（`diskio.c`）
4. FatFS操作可能阻塞——仅在工作线程中使用
5. 在多线程调用前检查 `FF_FS_REENTRANT` 是否已启用

### 中断优先级

当驱动使用中断时：

1. 文档标明所需的中断优先级
2. 确保不会与RTOS管理的中断发生优先级反转
3. ISR回调必须极简——仅设置标志/投递到队列
4. 绝不在ISR中分配内存或调用复杂函数
5. 使用项目现有的中断优先级方案

### ISR 到应用层的信号架构

先确认项目允许的 ISR API、事件优先级和端到端时限，再选择最小机制：

1. ISR 可安全直接投递且时限最紧时，使用项目提供的 ISR-safe API
2. 需要读取更多硬件状态、重排事件优先级或调用任务级 API 时，延迟到现有高优先级工作队列或线程
3. 裸机项目使用有界状态机、主循环事件或 PendSV 等现有调度机制

无论选择哪种方式，都保持 ISR 有界，不在其中阻塞、分配内存或调用未证明可重入的代码。驱动暴露硬件事件，上层决定业务事件的 FIFO、优先级或丢弃策略

## CMSIS-RTOS2 线程/信号量创建规则

**关键——历史教训导致设备启动崩溃：**

### osThreadNew() 属性约束

FreeRTOS的CMSIS-RTOS2封装对 `osThreadAttr_t` 的内存字段
有严格的配对规则：

| `cb_mem` | `stack_mem` | 结果 |
|----------|-------------|------|
| NULL | NULL | 动态分配（正确） |
| 已提供 | 已提供 | 静态分配（正确） |
| NULL | **已提供** | **非法——返回NULL → 崩溃** |
| 已提供 | NULL | **非法——返回NULL → 崩溃** |

**要么同时提供 `cb_mem` + `stack_mem`，要么两者都不提供。**

在调用 `osThreadNew()` 之前：

1. **搜索项目中** 现有的 `osThreadNew` 调用并严格匹配其属性模式
2. 如果项目使用 `cb_mem = NULL, cb_size = 0` 且没有
   `stack_mem`（全动态），就遵循该模式
3. 绝不将静态栈与动态TCB混用，反之亦然

```c
/* 错误 — stack_mem 没有配对 cb_mem → 崩溃 */
const osThreadAttr_t attr = {
    .name = "my_thread",
    .stack_mem = my_stack,         /* 已提供 */
    .stack_size = sizeof(my_stack),
    .priority = osPriorityHigh,
    /* cb_mem 未设置 → NULL → 非法组合 */
};

/* 正确 — 全动态（匹配项目约定） */
const osThreadAttr_t attr = {
    .name = "my_thread",
    .cb_mem = NULL,
    .cb_size = 0,
    .stack_size = 512,
    .priority = osPriorityHigh,
};
```

### osSemaphoreNew() — 调度器启动前可安全调用

`osSemaphoreNew()` 可以在 `osKernelStart()` 之前调用。
信号量会被创建，但在调度器运行之前没有任务可以等待它。
根据CMSIS-RTOS2规范，`osSemaphoreRelease()` 是ISR安全的。

## DMA + 环形缓冲区非阻塞接收架构

这是嵌入式串口驱动最常用的高性能非阻塞接收方案。
后续会有配套视频详细讲解，B站搜索「兆鸣嵌入式」观看。

### 架构

```
硬件UART --> DMA自动搬运 --> 环形缓冲区 --> 应用层读取
                 |
          中断通知（Idle Line / Half/Full Transfer）
                 |
          释放信号量 --> 唤醒等待的任务
```

### 关键组件

1. **环形缓冲区（Ring Buffer）**：仅在单生产者/单消费者、
   索引访问原子且发布顺序得到保证时，读写索引分离才能无锁
2. **DMA配置为循环模式（Circular）**：硬件自动搬运，
   不需要CPU参与
3. **利用UART Idle Line检测**
   （`HAL_UARTEx_ReceiveToIdle_DMA`）实现不定长接收
4. **ISR中仅做信号量释放**，不处理数据
5. **读写索引分离**：ISR更新写索引，应用任务更新读索引

### 实现要点

```c
/* DMA循环模式接收初始化 */
static uint8_t s_dma_buf[DMA_RX_BUF_SIZE];
static ring_buffer_t s_rx_ring;

static void uart_rx_start(uart_drv_t *self)
{
    HAL_UARTEx_ReceiveToIdle_DMA(
        self->huart, s_dma_buf, DMA_RX_BUF_SIZE);
    /* 关闭Half Transfer中断（如不需要） */
    __HAL_DMA_DISABLE_IT(
        self->huart->hdmarx, DMA_IT_HT);
}

/* Idle Line回调 — 在ISR上下文 */
void HAL_UARTEx_RxEventCallback(
    UART_HandleTypeDef *huart, uint16_t Size)
{
    /* 更新环形缓冲区写索引 */
    ring_buffer_update_write_index(&s_rx_ring, Size);
    /* 仅释放信号量，不处理数据 */
    osSemaphoreRelease(s_rx_sem);
}
```

### D-Cache注意事项

使用 DMA 时如果 MCU 有 D-Cache（如 Cortex-M7），根据传输方向在
正确时点 clean 或 invalidate。传给 Cache API 的起始地址向下对齐到
cache line，结束地址向上对齐，并确认该范围不会覆盖仍由 CPU 修改的邻接数据。

```c
/* DMA写入完成、CPU读取前：示意，实际使用项目的cache line辅助函数 */
cache_invalidate_aligned(s_dma_buf, DMA_RX_BUF_SIZE);
```

或者将DMA缓冲区放在非Cache区域（通过MPU配置或链接器脚本）。

### 错误恢复

UART错误（帧错误、溢出等）发生时：

1. 在错误回调中 abort 当前DMA传输
2. 重新启动DMA接收
3. 通过回调通知上层应用

```c
void HAL_UART_ErrorCallback(
    UART_HandleTypeDef *huart)
{
    HAL_UART_DMAStop(huart);
    ring_buffer_reset(&s_rx_ring);
    uart_rx_start(s_uart_drv);  /* 重新启动 */
    /* 通知上层 */
    if (s_uart_drv->error_cb != NULL) {
        s_uart_drv->error_cb(s_uart_drv,
                             huart->ErrorCode);
    }
}
```

## 寄存器级验证检查清单

编写涉及硬件寄存器的代码时：

- [ ] 寄存器地址和位域定义正确
- [ ] 需要时使用正确的读-改-写序列
- [ ] 所有硬件寄存器指针使用volatile限定符
- [ ] 外设访问宽度正确（8/16/32位）
- [ ] 寄存器访问之间的必要延时（如需要）
- [ ] 访问前已启用外设时钟
- [ ] 引脚复用/GPIO复用功能已配置
