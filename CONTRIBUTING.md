# Contributing

Contributions that improve correctness, verification, portability, documentation, or FPGA implementation quality are welcome.

## Development Flow

1. Create a branch from `main`.
2. Keep RTL changes focused and preserve the existing AXI4-Lite programming model unless the change explicitly updates it.
3. Add or update a self-checking testbench for behavioral changes.
4. Run the relevant module-level test and `tb_soc_firmware`.
5. For implementation changes, report timing, utilization, and power deltas.
6. Update `docs/architecture.md` when registers, addresses, selectors, or data flow change.

## Style

- Use synthesizable Verilog-2001 unless a file already requires another standard.
- Keep clocked and combinational behavior explicit.
- Use active-low reset naming with the `_n` suffix.
- Avoid absolute file paths.
- Keep generated Vivado output outside version control.

## Pull Requests

Describe the problem, the implementation, tests performed, and any change in FPGA resource use or timing. Do not commit generated runs, caches, bitstreams, waveform databases, or local administrative documents.
