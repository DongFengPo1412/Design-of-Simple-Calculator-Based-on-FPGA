# FPGA Calculator — Setup and operation

[简体中文](setup.zh-CN.md) · **English** · [日本語](setup.ja.md) · [Overview](../README_EN.md)

<a id="open"></a>

## Select and open a project

1. For the main version, open [project_3.xpr](../integer_calculator_buzzer/project_3.xpr). Check device `xc7a35tftg256-1`, top `Caculator`, and active RTL `caculator.v`.
2. Its active pin file is [Con_Caculator.xdc](../integer_calculator_buzzer/project_3.srcs/constrs_1/new/Con_Caculator.xdc). No `create_clock` is present. Establish the actual oscillator and circuit before adding a clock constraint.
3. [cacu.xpr](../float_calculator_ieee754/cacu.xpr), top `Top`, is an unfinished floating-point experiment with an empty XDC. It is not ready for direct bitstream deployment.
4. The 74HC595 directory has no standalone `.xpr` or complete pin constraints. Resolve integration gaps before creating its project. Do not indiscriminately add every `.v` file to the main version.

<a id="pins"></a>

## Check main-version pins

| Signal | Constraint pins, from vector bit 0 upwards |
| --- | --- |
| `clk` | D4 |
| `col[0:3]` | T10, R11, T12, R12; pulldown |
| `row[0:3]` | K3, M6, P10, R10 |
| `seg[0:7]` | P11, N12, L14, K13, K12, P13, M14, L13 |
| `DIG[0:5]` | N11, N14, N13, M12, H13, G12 |
| `buzzer`, `sw1`, `sw2` | L2, F3, H4 |

This transcribes repository constraints, not universal Artix-7 board wiring. Check voltage, polarity, clock, and physical connections before programming.

<a id="validate"></a>

## Validation sequence

First establish reset/initialization and a testbench matching the current top. Check keys, repeated digits, clear, four operations, negative differences, zero division, remainders above 15, overflow, and mixed chained operations. Only then proceed to synthesis, timing constraints, implementation, and board testing.

This review parsed project XML and inspected RTL, constraints, and historical records. It did not run HDL tools or program hardware. Old checkpoints and ModelSim logs do not establish a current pass.

<a id="next"></a>

## Reproduction requirements

A current self-checking testbench and fresh timing reports are missing. Reproduction needs the actual FPGA board, keypad/display/buzzer wiring, and verified clock frequency. The exploratory variants also require algorithm and connection work.

Validate the main integer version first, then develop serial display and floating-point experiments separately. Those are future source changes; this revision changes documentation only.
