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

The simulation confirms that mac_correct.v behaves correctly across all
test cases. In the first phase, with inputs a=3 and b=4 applied for three
consecutive clock cycles, the accumulator correctly produces 12, 24, and
36 — demonstrating that the MAC accumulates the product 3×4=12 on each
rising edge. When reset is asserted, the output immediately clears to
zero on the next clock edge, confirming synchronous active-high reset
behavior. In the second phase, with a=-5 and b=2, the accumulator
correctly produces -10 and -20, verifying that signed multiplication and
sign extension are handled correctly for negative operands. All six output
values match the expected results, confirming that the design is
functionally correct for both positive and negative INT8 inputs.

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
logic signed [15:0] product;
assign product = a * b;
```
A named 16-bit signed wire `product` is declared and driven by a
continuous `assign`. This makes the 16-bit intermediate result visible
and named, improving readability and making the sign extension step
unambiguous. Neither LLM output included this intermediate signal —
both computed the product inline inside the always_ff block, which
hides the bit-width of the intermediate result from the reader and
leaves sign extension behavior implicit.

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
and tool-independent method of sign extension in synthesizable
SystemVerilog. It does not rely on implicit promotion rules or cast
behavior, and its correctness can be verified by inspection without
needing to know how a particular synthesis tool handles mixed-width
arithmetic. This makes the design more robust and easier to review
compared to both LLM outputs.

### Summary of Changes

The table below compares the three implementations across key design
aspects. LLM A relies on implicit sign extension which is tool-dependent
and risky for negative operands. LLM B improves on this with an explicit
cast but still computes the product inline. mac_correct.v goes furthest
by naming the intermediate product, making the bit width visible, and
using manual bit replication for sign extension — ensuring correct and
predictable behavior across all synthesis tools. Both LLM outputs use
always_ff correctly with active-high synchronous reset, which matches
the specification, and mac_correct.v preserves these correct behaviors
while fixing the sign extension weakness.

| Aspect | LLM A | LLM B | mac_correct.v |
|--------|-------|-------|---------------|
| Sign extension | Implicit, tool-dependent | Explicit cast `32'($signed(...))` | Manual bit replication `{{16{...}}, product}` |
| Intermediate wire | Not declared | Not declared | Declared as `logic signed [15:0] product` |
| Synthesizability | Compiles but may produce wrong results for negative inputs | Correct and portable | Correct, most explicit and tool-independent |
| Reset behavior | Active-high synchronous, correct per spec | Active-high synchronous, correct per spec | Active-high synchronous, correct per spec |
| always_ff usage | Used correctly | Used correctly | Used correctly |


---

## Yosys Synthesis Output (mac_correct.v)

**Command:** `yosys -p 'read_verilog -sv mac_correct.v; synth; stat'`
**Tool:** Yosys 0.9 (git sha1 1979e0b) — Google Colab

```
=== mac ===

   Number of wires:                607
   Number of wire bits:            683
   Number of public wires:           5
   Number of public wire bits:      50
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:                665
     $_ANDNOT_                     143
     $_AND_                         61
     $_AOI3_                        62
     $_DFF_P_                       32
     $_MUX_                          1
     $_NAND_                        22
     $_NOR_                         23
     $_NOT_                         32
     $_OAI3_                        24
     $_ORNOT_                       18
     $_OR_                          33
     $_XNOR_                        64
     $_XOR_                        150

found and reported 0 problems.
CPU: user 0.47s system 0.02s, MEM: 20.09 MB total
```

The synthesis completed with 0 errors and 0 problems, confirming that
mac_correct.v is fully synthesizable. The stat output shows the design
maps to 665 standard cells after technology mapping. The most notable
result is the presence of exactly 32 `$_DFF_P_` flip-flops, which
corresponds precisely to the 32-bit output accumulator register `out` —
one flip-flop per bit, as expected for a registered accumulator. The
multiplier logic (INT8 × INT8 = 16-bit product) is implemented using a
combination of XOR, XNOR, AND, and carry-chain cells, which is the
standard gate-level representation of a combinational multiplier. The
single `$_MUX_` cell corresponds to the reset mux that selects between
zero (when rst=1) and the accumulated value (when rst=0). The absence
of any memory cells and processes confirms the design is purely
combinational and sequential logic with no latches or unsynthesizable
constructs.
