"""
attention_mac_core_tb.py
cocotb testbench stub for attention_mac_core.sv
Project: Hardware Accelerator for Transformer Self-Attention Inference
ECE 510 Spring 2026

Goal: Working simulation harness — drives reset and one representative
      Q x K dot product sequence. Complex assertions not required for COPT.

Run in Google Colab:
  !pip install cocotb
  !apt-get install -y iverilog
  !make SIM=icarus VERILOG_SOURCES=attention_mac_core.sv TOPLEVEL=attention_mac_core MODULE=attention_mac_core_tb
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def to_signed_8(val):
    """Convert Python int to unsigned 8-bit for cocotb signal assignment."""
    return val & 0xFF


@cocotb.test()
async def test_attention_mac_reset(dut):
    """
    Test 1: Verify synchronous active-high reset clears accumulator.
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Assert reset
    dut.rst.value      = 1
    dut.q_in.value     = 0
    dut.k_in.value     = 0
    dut.valid_in.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert dut.accum_out.value.signed_integer == 0, \
        f"Reset failed: expected 0, got {dut.accum_out.value.signed_integer}"
    cocotb.log.info(f"Reset OK: accum_out = {dut.accum_out.value.signed_integer}")


@cocotb.test()
async def test_attention_mac_dot_product(dut):
    """
    Test 2: Representative QxK^T dot product.
    Compute dot product of q=[3,2,1] and k=[4,5,6]:
      3x4=12, 2x5=10, 1x6=6 → expected accumulation: 12, 22, 28
    This mimics one element of the QK^T matrix computation in self-attention.
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value      = 1
    dut.q_in.value     = 0
    dut.k_in.value     = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    # Feed 3 Q,K pairs (one dot product element per cycle)
    pairs = [(3, 4), (2, 5), (1, 6)]
    # Pipeline depth = 2, so expected values appear 2 cycles after input
    expected_accum = [12, 22, 28]

    for q_val, k_val in pairs:
        dut.q_in.value     = to_signed_8(q_val)
        dut.k_in.value     = to_signed_8(k_val)
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)

    dut.valid_in.value = 0

    # Wait for pipeline to drain (2 extra cycles)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    final = dut.accum_out.value.signed_integer
    cocotb.log.info(f"Dot product result: accum_out = {final} (expected 28)")
    cocotb.log.info("test_attention_mac_dot_product: COMPLETE")


@cocotb.test()
async def test_attention_mac_negative_inputs(dut):
    """
    Test 3: Negative Q and K values (important for INT8 attention weights).
    q=-5, k=3 → product=-15 → accum should decrease.
    Verifies correct signed multiplication in the compute core.
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset
    dut.rst.value      = 1
    dut.q_in.value     = 0
    dut.k_in.value     = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    # Apply negative input
    dut.q_in.value     = to_signed_8(-5)
    dut.k_in.value     = to_signed_8(3)
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0

    # Wait for pipeline
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    result = dut.accum_out.value.signed_integer
    cocotb.log.info(f"Negative input test: q=-5, k=3 → accum = {result} (expected -15)")
    cocotb.log.info("test_attention_mac_negative_inputs: COMPLETE")
