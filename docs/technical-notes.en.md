# FPGA Calculator — Technical notes

[简体中文](technical-notes.zh-CN.md) · **English** · [日本語](technical-notes.ja.md) · [Overview](../README_EN.md)

<a id="baseline"></a>

## Main version: input and display

[caculator.v](../integer_calculator_buzzer/project_3.srcs/sources_1/new/caculator.v) defines `Caculator`, `cal`, `FreDiv`, `button`, `buzzermusic`, and `Buzzercontrol`. In `cal`, key values 0–9 are digits, 10–13 are arithmetic operators, 14 is equals, and 15 clears. Entry is organized around two decimal digits; state and held-key logic govern acceptance, with two switches involved in repeated identical digits.

a_reg/b_reg/result remain 21/7/21 bits, with negative values represented by magnitude/flag. Display slots 0–5 are scanned and 6–7 blanked. Explicit state/output initialization removes unknown startup dependence in simulation; configuration startup and a complete runtime reset remain physically unverified.

Chaining transfers the result to a_reg and records the new op. The mixed example 8+2= followed by ×3= produces 30; this is not an expression parser or complete overflow protection.

<a id="timing"></a>

## Clock division, sampling, and tones

```math
f_{out}\approx\frac{f_{clk}}{2\max(1,\lfloor25000000/f_{req}\rfloor)}
```

```math
(b_2\land b_1\land b_0)\lor(\neg b_2\land b_1\land b_0)=b_1\land b_0
```

FreDiv retains the source assumption of a 50 MHz input. For positive requests, its half-period is max(1,floor(25000000/f_req)) input cycles; zero disables output. Actual oscillator frequency, primary/generated-clock constraints and cross-domain paths remain unconfirmed, so source settings are not board measurements.

The three-register button expression simplifies to `b1 & b0` above. It does not require three consecutive matching samples or establish a precise 20 ms end-to-end debounce latency. The timed state machine in the 74HC595 directory is a different implementation.

`buzzermusic` selects fixed counts by key; `Buzzercontrol` produces square-wave tones. This is not a separate tune sequencer triggered by successful arithmetic. Actual pitch depends on the input clock and counter endpoints.

<a id="arithmetic"></a>

## Arithmetic and display boundaries

- A zero divisor produces zero result/remainder and retains the error-display path without executing division/modulo.
- Seven-bit res covers two-digit remainders. All 9900 quotient/remainder cases pass, and the two fractional digits for 98/99 are 98.
- Arithmetic width exceeds the displayed range, with no complete overflow protection. Fractional display logic is not floating-point arithmetic.
- [multiplication.v](../integer_calculator_buzzer/project_3.srcs/sources_1/new/multiplication.v) is outside the main active RTL set. Variable-dependent generation and bare assignments to wires contain RTL syntax/structure problems; it is not presented as a synthesized multiplier.
- The [asserting testbench](../tests/tb_calculator.v) is registered in the main sim_1 with tb_calculator as behavioral top. Loose historical tests and the two exploratory directories are retained without being counted as passing tests.

<a id="experiments"></a>

## Status of the exploratory variants

| Module | Source-confirmed content | Integration gap |
| --- | --- | --- |
| 74HC595 `key_scan` / `operation_ctrl` | Two-stage synchronization, timed debouncing, entry states, add/subtract and multiplication handshake | Top-level multiplier instance absent; divider not connected |
| `mult` / `div` | Standalone shift-add multiplier and shift-subtract divider; divider has a zero-divisor branch | Its protection is not part of the buzzer version |
| `hex2bcd` | Shift and add 3 to BCD digits at least 5 | Default 27-bit input needs nine decimal digits/36 output bits; top receives 32, display takes six digits |
| `seg_disp` / `hc595_drive` | Segment decoding and 16-bit shift/latch fragments | Missing scan control; driver segment input only 6 bits; no driver instance drives top-level `ds/sclk/rclk` |
| Floating-point `Top` and conversions | Two input parsers, format conversion and display experiments | Implicit scalar nets, undriven clocks/signals, both converters use the first data input, unconnected digit output; active XDC is empty |
| `ALU_float` | Eight-state control, exponent alignment, mantissa add/subtract/multiply, partial normalization/rounding | No quotient computation in division; multiplication/division sign uses OR rather than XOR; incomplete zero, subnormal, NaN/Inf and rounding handling |

The input parser uses concatenation/truncation rather than complete decimal-to-floating-point conversion. `float_to_ieee754` subtracts the integer from itself to obtain a zero fractional part and cannot convert general values correctly. Output conversion is incomplete too. This remains an unfinished experiment.

The archived 2024-01-23 ModelSim `src/transcript` shows instantiated multiplication, division and shift drivers, with width warnings, unlike the current `top.v`. `src/test.v` and `sim/test.v` have different interfaces/stimuli; the latter uses display ports absent from the current top. Historical “Errors: 0” is not validation of current source.

<a id="evidence"></a>

## Evidence and version boundaries

The main RTL is now a maintenance revision of the local Documents/Vivado/project_3 archive, rather than byte-identical. Floating-point Top variants are not combined. Historical photos do not establish a new board test.

![Historical calculator demonstration](images/demo_fpga_board_calc_40s.jpg)

![Historical board test](images/demo_fpga_board_test_85s.jpg)

These images preserve project context. No current-commit self-test, utilization report, or measured timing accompanies them. Board appearance and device constraints must be checked independently rather than inferring a complete board specification from a photo.

The 2026-10 buzzer-version fixes widen the remainder to seven bits, guard division/modulo by zero, and update op when a new operator follows a result. Calculation state, scan count, divider output and buzzer count have explicit initial values; clear resets result/remainder. Divider half-period endpoints are corrected, zero frequency disables output, and startup does not request a tone without a key.

Icarus Verilog 13.0 compiles and executes the real RTL self-test: all 9900 quotient/remainder combinations for a=0–99, b=1–99, plus 98/99 fractional digits, zero division, mixed chaining, negative subtraction, clear and startup/divider/buzzer boundaries. Tests drive cal button vectors directly and place the divider at known counter states; they do not measure physical keys, pitch or clock frequency. No Vivado synthesis, implementation, timing closure or fresh board test occurred.
