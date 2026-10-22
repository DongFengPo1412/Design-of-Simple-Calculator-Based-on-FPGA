# FPGA Calculator — 部署与操作

**简体中文** · [English](setup.en.md) · [日本語](setup.ja.md) · [项目首页](../README.md)

<a id="open"></a>

## 选择与打开工程

1. 主要版本打开 [project_3.xpr](../integer_calculator_buzzer/project_3.xpr)，检查器件 `xc7a35tftg256-1`、顶层 `Caculator`、活动文件 `caculator.v`。
2. 活动引脚文件为 [Con_Caculator.xdc](../integer_calculator_buzzer/project_3.srcs/constrs_1/new/Con_Caculator.xdc)。当前没有 `create_clock`；按真实板卡晶振和电路核对后补充时钟约束。
3. 浮点 [cacu.xpr](../float_calculator_ieee754/cacu.xpr) 顶层为 `Top`，是未完成实验。其 XDC 为空，不应直接生成并下载比特流。
4. 74HC595 目录没有独立 `.xpr` 或完整引脚约束，需要先解决顶层缺口后建立独立工程。不要把全部 `.v` 混合加入主版本。

<a id="pins"></a>

## 主版本引脚核对

| 信号 | 约束引脚（按向量从 0 向高位） |
| --- | --- |
| `clk` | D4 |
| `col[0:3]` | T10、R11、T12、R12；下拉 |
| `row[0:3]` | K3、M6、P10、R10 |
| `seg[0:7]` | P11、N12、L14、K13、K12、P13、M14、L13 |
| `DIG[0:5]` | N11、N14、N13、M12、H13、G12 |
| `buzzer`、`sw1`、`sw2` | L2、F3、H4 |

表格仅转录仓库约束，不代表任意 Artix-7 板卡都兼容。下载前核对电平、有效极性、时钟和真实连线。

<a id="validate"></a>

## 验证顺序

先补足复位/初始化，使用与当前顶层匹配的测试平台，再验证按键、重复数字、清除、四则运算、负差值、零除、余数大于 15、溢出和混合连续运算。之后才能进行综合、时序约束检查、实现和硬件验证。

本次只解析了工程 XML 并阅读 RTL/约束/历史记录，未运行上述 HDL 工具或下载。旧检查点和 ModelSim 日志不是当前版本通过证明。

<a id="next"></a>

## 复现条件与后续

仓库缺少与当前源文件一致的自检测试平台和新时序报告。需要实际 FPGA 板、键盘、显示与蜂鸣器连线资料，确认时钟频率；探索目录还需要补全连接和算法。

优先验证主要整数版本，再独立推进串行显示与浮点实验。所有这类修复均属于后续代码工作，本次仅修改文档。
