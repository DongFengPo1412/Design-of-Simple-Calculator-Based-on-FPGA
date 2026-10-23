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

Icarus Verilog 13.0编译并运行真实RTL自检通过：穷举a=0–99、b=1–99的9900组商/余数，另检查98/99的小数两位、零除、混合串联、负减法、清零和启动/分频/蜂鸣器边界。测试直接驱动cal按键向量，分频端点使用已知计数状态，不是实物按键、音程或时钟测量。未执行Vivado综合、实现、时序收敛或重新上板。

<a id="next"></a>

## 复现条件与后续

先确认板卡晶振及主时钟/派生时钟约束，再进行综合与板端验证。74HC595和IEEE754仍是未完成实验；没有把实验缺项包装成主版本完成内容。

[自检](../tests/tb_calculator.v)已加入主项目sim_1并设置为tb_calculator行为仿真顶层；旧松散测试与两个实验目录仍保留，未作为通过结果。

## 维护修订与RTL自检


```shell
iverilog -g2012 -s tb_calculator -o "$BUILD_DIR/calculator.vvp" integer_calculator_buzzer/project_3.srcs/sources_1/new/caculator.v tests/tb_calculator.v
vvp "$BUILD_DIR/calculator.vvp"
```

先安装[Icarus](https://steveicarus.github.io/iverilog/usage/installation.html)，将BUILD_DIR设为已创建的外部输出目录。
