import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def to_signed_8(val):
    return val & 0xFF

@cocotb.test()
async def test_mac_basic(dut):
    """
    Basic MAC test per COPT spec:
      [a=3, b=4] x3 cycles -> 12, 24, 36
      rst                  -> 0
      [a=-5, b=2] x2 cycles -> -10, -20
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert dut.out.value.signed_integer == 0
    cocotb.log.info(f"After reset: out = {dut.out.value.signed_integer}")
    dut.rst.value = 0
    dut.a.value = to_signed_8(3)
    dut.b.value = to_signed_8(4)
    await RisingEdge(dut.clk)
    for expected in [12, 24, 36]:
        await RisingEdge(dut.clk)
        actual = dut.out.value.signed_integer
        assert actual == expected, f"FAIL: expected {expected}, got {actual}"
        cocotb.log.info(f"a=3, b=4 -> out = {actual}")
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    actual = dut.out.value.signed_integer
    assert actual == 0, f"Reset failed: expected 0, got {actual}"
    cocotb.log.info(f"After rst=1: out = {actual}")
    dut.rst.value = 0
    dut.a.value = to_signed_8(-5)
    dut.b.value = to_signed_8(2)
    await RisingEdge(dut.clk)
    for expected in [-10, -20]:
        await RisingEdge(dut.clk)
        actual = dut.out.value.signed_integer
        assert actual == expected, f"FAIL: expected {expected}, got {actual}"
        cocotb.log.info(f"a=-5, b=2 -> out = {actual}")
    cocotb.log.info("test_mac_basic: ALL PASSED")

@cocotb.test()
async def test_mac_overflow(dut):
    """
    Overflow test: drive accumulator toward 2^31 - 1 = 2,147,483,647.
    Use a=127, b=127 (max INT8 product = 16129 per cycle).
    Documents wrap-around (no saturation) behavior.
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    dut.a.value = to_signed_8(127)
    dut.b.value = to_signed_8(127)
    MAX_INT32 = 2**31 - 1
    run_cycles = MAX_INT32 // (127*127) + 5
    prev = 0
    for i in range(run_cycles):
        await RisingEdge(dut.clk)
        current = dut.out.value.signed_integer
        if prev > 0 and current < 0:
            cocotb.log.info(f"WRAP at cycle {i+1}: {prev} -> {current}")
            cocotb.log.info("Behavior: two's complement WRAP-AROUND, no saturation")
            break
        prev = current
    cocotb.log.info("test_mac_overflow: COMPLETE")
