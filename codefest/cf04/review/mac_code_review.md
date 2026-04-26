# MAC Code Review
## Codefest 4 — ECE 410/510 Spring 2026

---

## LLM Attribution

| File | LLM | Model Version |
|------|-----|---------------|
| `mac_llm_A.v` | ChatGPT | GPT-4o (April 2026) |
| `mac_llm_B.v` | Claude | Claude Sonnet 4.6 |

---

## Compile Results

**Simulator:** ModelSim - Intel FPGA Edition vlog 10.5b (2016.10)

### mac_tb.v + mac_correct.v
```
vlog -sv "codefest/cf04/hdl/mac_tb.v"
# Model Technology ModelSim - Intel FPGA Edition vlog 10.5b Compiler 2016.10 Oct  5 2016
# Start time: 01:52:19 on Apr 25,2026
# -- Compiling module mac_tb
#
# Top level modules:
#     mac_tb
# End time: 01:52:19 on Apr 25,2026, Elapsed time: 0:00:00
# Errors: 0, Warnings: 0
```

### mac_llm_A.v
```
vlog -sv "codefest/cf04/hdl/mac_llm_A.v"
# Model Technology ModelSim - Intel FPGA Edition vlog 10.5b Compiler 2016.10 Oct  5 2016
# -- Compiling module mac
# Top level modules:
#     mac
# Errors: 0, Warnings: 0
```

### mac_llm_B.v
```
vlog -sv "codefest/cf04/hdl/mac_llm_B.v"
# Model Technology ModelSim - Intel FPGA Edition vlog 10.5b Compiler 2016.10 Oct  5 2016
# -- Compiling module mac
# Top level modules:
#     mac
# Errors: 0, Warnings: 0
```

Both files compile without syntax errors but mac_llm_A.v contains a
functional correctness issue identified below.

---

## Simulation Results (mac_correct.v + mac_tb.v)

**Tool:** ModelSim - Intel FPGA Edition | Command: `vsim mac_tb` → `run -all`

```
vsim mac_tb
# vsim mac_tb
# Start time: 01:52:19 on Apr 25,2026
# Loading sv_std.std
# Loading work.mac_tb
# Loading work.mac

run -all
# Cycle 1 output = 12
# Cycle 2 output = 24
# Cycle 3 output = 36
# After reset output = 0
# Negative cycle 1 output = -10
# Negative cycle 2 output = -20
# ** Note: $finish    : codefest/cf04/hdl/mac_tb.v(63)
#    Time: 66 ns  Iteration: 0  Instance: /mac_tb
```

mac_correct.v passes all testbench cases correctly.
All 6 output values match expected results — accumulation, reset, and negative multiplication verified.

---

## Issue 1 — Implicit Sign Extension (mac_llm_A.v)

### Offending line:
```systemverilog
out <= out + (a * b);
```

### Why it is wrong:
`a` and `b` are both `signed [7:0]`. Their product is a 16-bit signed
value. When added directly to the 32-bit accumulator `out` without
explicit sign extension, the behavior depends on how the synthesis tool
handles implicit width promotion. Some tools zero-extend the 16-bit
product to 32 bits before adding, which treats negative products as
large positive numbers. For example, `a=-5, b=2` gives a 16-bit product
of `0xFFF6`. Without sign extension this becomes `0x0000FFF6 = 65526`
instead of `-10`, silently corrupting the accumulator for all negative
products. The code compiles without error but produces wrong results on
many synthesis flows.

### Corrected version:
```systemverilog
logic signed [15:0] product;
assign product = a * b;
out <= out + {{16{product[15]}}, product};
```

---

## Issue 2 — Implicit vs Explicit Sign Extension: LLM A vs LLM B

### Comparison:
```systemverilog
// LLM A (ambiguous — implicit)
out <= out + (a * b);

// LLM B (explicit and unambiguous)
out <= out + 32'($signed(a) * $signed(b));
```

### Explanation:
LLM B uses `32'($signed(a) * $signed(b))` which is valid SystemVerilog
syntax. The `32'(...)` cast explicitly promotes the signed product to 32
bits with correct sign extension before accumulation. This is
unambiguous across all synthesizers. LLM A relies on implicit promotion
which is tool-dependent and can produce silent errors on negative inputs.
LLM B's approach is therefore more correct and portable than LLM A's.

---

## What Was Changed in mac_correct.v

`mac_correct.v` was written to be the most explicit and portable version,
fixing the sign extension issue in a way that is clear to both the
synthesizer and the reader. Here is exactly what changed versus the LLM
outputs:

### Change 1 — Explicit intermediate product register added
```systemverilog
// Added (not present in either LLM output):
logic signed [15:0] product;
assign product = a * b;
```
A named 16-bit signed wire `product` is declared and driven by a
continuous `assign`. This makes the 16-bit intermediate result visible
and named, improving readability and making the sign extension step
unambiguous.

### Change 2 — Manual sign extension via concatenation
```systemverilog
// LLM A wrote:
out <= out + (a * b);

// LLM B wrote:
out <= out + 32'($signed(a) * $signed(b));

// mac_correct.v uses:
out <= out + {{16{product[15]}}, product};
```
The expression `{{16{product[15]}}, product}` manually replicates the
sign bit (`product[15]`) 16 times and concatenates it with the 16-bit
product to form a correct 32-bit signed value. This is the most explicit
and tool-independent way to sign-extend in synthesizable SystemVerilog —
no reliance on implicit promotion rules or cast behavior.

### Summary of changes

| Aspect | LLM A | LLM B | mac_correct.v |
|--------|-------|-------|---------------|
| Sign extension | Implicit (ambiguous) | `32'($signed(...))` cast | Manual `{{16{...}}, product}` |
| Intermediate wire | None | None | `logic signed [15:0] product` |
| Synthesizability | Compiles, may fail | Correct | Correct, most explicit |
| Reset behavior | Active-high ✅ | Active-high ✅ | Active-high ✅ |
| `always_ff` used | ✅ | ✅ | ✅ |

