# FPGA Calculator — Technical notes

[简体中文](technical-notes.zh-CN.md) · **English** · [日本語](technical-notes.ja.md) · [Overview](../README_EN.md)

<a id="baseline"></a>

## Main version: input and display

[caculator.v](../integer_calculator_buzzer/project_3.srcs/sources_1/new/caculator.v) defines `Caculator`, `cal`, `FreDiv`, `button`, `buzzermusic`, and `Buzzercontrol`. In `cal`, key values 0–9 are digits, 10–13 are arithmetic operators, 14 is equals, and 15 clears. Entry is organized around two decimal digits; state and held-key logic govern acceptance, with two switches involved in repeated identical digits.

`a_reg`, `b_reg`, and the result register are 21, 7, and 21 bits. Negative differences use a magnitude and flag rather than a complete signed arithmetic interface. The display counter selects digits in slots 0–5 and leaves slots 6–7 blank. A nominal 1 kHz scan clock is not a 1 kHz refresh of every digit. Some clock, scan-counter, and buzzer registers lack deterministic initialization/reset, which can propagate unknown values in simulation.

Chaining branches exist, but selecting another operator in the result state does not always update `op`. Mixed chained calculations require separate tests; branch presence does not establish general expression support.

<a id="timing"></a>

## Clock division, sampling, and tones

```math
f_{out}\approx\frac{f_{clk}}{2(\lfloor25000000/f_{req}\rfloor+1)}
```

```math
(b_2\land b_1\land b_0)\lor(\neg b_2\land b_1\land b_0)=b_1\land b_0
```

`FreDiv` uses 25,000,000 and toggles its output when the counter reaches the integer quotient. The equation is a source-derived estimate for a known input clock. With a 50 MHz input, requested values 1000/50 produce approximately 1 kHz/50 Hz; these are not board measurements. Positive/negative scan-clock edges and lower-rate button sampling introduce clock-domain paths without demonstrated timing/synchronization coverage.

The three-register button expression simplifies to `b1 & b0` above. It does not require three consecutive matching samples or establish a precise 20 ms end-to-end debounce latency. The timed state machine in the 74HC595 directory is a different implementation.

`buzzermusic` selects fixed counts by key; `Buzzercontrol` produces square-wave tones. This is not a separate tune sequencer triggered by successful arithmetic. Actual pitch depends on the input clock and counter endpoints.

<a id="arithmetic"></a>

## Arithmetic and display boundaries

- The calculation executes `result <= a / b` and `%` without guarding a zero divisor. A later error glyph does not prevent the operation.
- Remainder `res` is only 4 bits, truncating remainders above 15 and potentially corrupting the next two fractional digits. General two-digit division accuracy is not established.
- Arithmetic width exceeds the displayed range, with no complete overflow protection. Fractional display logic is not floating-point arithmetic.
- [multiplication.v](../integer_calculator_buzzer/project_3.srcs/sources_1/new/multiplication.v) is outside the main active RTL set. Variable-dependent generation and bare assignments to wires contain RTL syntax/structure problems; it is not presented as a synthesized multiplier.
- Neither `.xpr` includes an independent test file in `sim_1`. Loose tests use `$display`/`$stop` without result assertions; `sim1.v` also references a missing module and contains invalid negative-literal syntax.

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

The main RTL is byte-identical to its local `Documents/Vivado/project_3` copy. The repository floating-point `Top.v` matches local `cacu (1)` and differs from `cacu(2)`; their implementations have not been combined.

![Historical calculator demonstration](images/demo_fpga_board_calc_40s.jpg)

![Historical board test](images/demo_fpga_board_test_85s.jpg)

These images preserve project context. No current-commit self-test, utilization report, or measured timing accompanies them. Board appearance and device constraints must be checked independently rather than inferring a complete board specification from a photo.
