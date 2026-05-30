# Roofline Analysis — CF09
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## Gap Analysis

The hardware accelerator point is plotted at the projected operating point
using cycle counts from ModelSim simulation and the 250 MHz synthesis
frequency. The accelerator lands in the compute-bound region of the
Sky130A roofline at arithmetic intensity 42.7 FLOP/byte (INT8 full-reuse
bound), which is above the ridge point of 8.0 FLOP/byte for the AXI4-Stream
interface (8 GB/s bandwidth, 64 GFLOP/s peak compute).

The dominant uncertainty in this projection is AXI4-Stream interface
overhead. The projection assumes one Q/K/V triple is delivered per clock
cycle with no handshake stalls. In practice, TREADY/TVALID latency and
pipeline fill time will reduce effective throughput by an estimated 10-20%.
A second uncertainty is the assumption of zero off-chip memory latency —
if Q, K, V must be loaded from DRAM each invocation, the effective
arithmetic intensity falls toward the no-reuse lower bound of 10.67
FLOP/byte, placing the design closer to the memory-bound boundary.

To convert the projected point to a measured point, a cocotb-based
cycle-accurate benchmark driving the AXI4-Stream interface with real
handshake timing would be required. This is planned for M4.