# Repository File Guide

This guide explains every versioned file and the directories that contain them. Build products created on a local workstation are excluded by `.gitignore`.

## Root Files

| File | Purpose |
|---|---|
| `README.md` | Project overview, measured results, requirements, and commands for project creation, simulation, and FPGA implementation. |
| `.gitignore` | Keeps generated Vivado files, build directories, bitstreams, and temporary files out of Git. It does not delete local files. |
| `.gitattributes` | Defines line endings for text files and binary handling for images and document formats. |
| `CITATION.cff` | Machine-readable authorship and citation metadata used by GitHub's citation feature. |
| `CONTRIBUTING.md` | Development conventions and verification expectations for proposed changes. |
| `THIRD_PARTY_NOTICES.md` | Attributes PicoRV32 and describes the original license notice retained in its source. |

## GitHub Templates

`.github/` configures repository collaboration; it is not FPGA source code.

| File under `.github/` | Purpose |
|---|---|
| `ISSUE_TEMPLATE/bug_report.yml` | Structured issue form for RTL, firmware, simulation, or hardware problems. |
| `ISSUE_TEMPLATE/feature_request.yml` | Structured issue form for proposed improvements. |
| `pull_request_template.md` | Checklist and description template for reviewing code changes. |

## RTL Sources

The `CryptoCore_RV32.srcs/` structure follows the original Vivado source organization. `sources_1/` contains design sources; `sim_1/` contains testbenches; `constrs_1/` contains FPGA constraints. The names `imports/` and `new/` reflect Vivado's file organization rather than different functional stages of the design.

| File under `CryptoCore_RV32.srcs/sources_1/` | Purpose |
|---|---|
| `imports/rtl/pynq_z2_top.v` | Board top: 125-to-50 MHz clock generation, reset conditioning, SoC instance, LED selection, and Pmod JB debug outputs. |
| `imports/rtl/riscv_crypto_soc.v` | Integrates the CPU, crossbar, instruction ROM, data RAM, and cryptographic MMIO slave. |
| `imports/rtl/axi_lite_crossbar.v` | Routes the single AXI master to ROM, RAM, or crypto according to the address region. |
| `imports/rtl/axi_lite_mem.v` | Implements both `axi_lite_rom` and `axi_lite_ram`, including ROM initialization and RAM byte writes. |
| `imports/rtl/crypto_coprocessor_axi.v` | Shared control/status registers, buffer, AXI slave, operation dispatch, and mode sequencing for the crypto cores. |
| `imports/rtl/aes128_core.v` | AES-128 block encryption and decryption datapath and control. CBC/CTR sequencing is handled by the coprocessor wrapper. |
| `imports/rtl/sha256_core.v` | SHA-256 compression datapath and state needed for chained blocks. |
| `imports/rtl/chacha20_core.v` | ChaCha20 rounds and 512-bit keystream-block generation. |
| `new/picorv32.v` | Third-party PicoRV32 CPU, AXI wrapper, and associated modules. Its original copyright/permission header must be retained. |

## Firmware Files

Files are located under `CryptoCore_RV32.srcs/sources_1/imports/firmware/`.

| File | Purpose |
|---|---|
| `boot_rom.hex` | Normal 512-word ROM image used to execute coprocessor KATs. It becomes initialized FPGA memory during synthesis. |
| `boot_rom_swcrypto.S` | Human-readable, address-labelled CPU-only benchmark listing with AES-/SHA-/ChaCha-like kernels. It is not the source of `boot_rom.hex` or directly buildable assembly as written. |
| `boot_rom_trap_test.S` | Assembly for deliberate illegal-instruction execution to test CPU trap reporting. |
| `boot_rom_trap.hex` | Prebuilt trap-test ROM image selected by `tb_soc_trap_firmware`. |

The normal ROM's original buildable source and generation process are not included. Use the annotated listing under `docs/` to inspect its instructions.

## Constraints

| File | Purpose |
|---|---|
| `CryptoCore_RV32.srcs/constrs_1/imports/constraints/pynq_z2.xdc` | PYNQ-Z2 pin assignments, I/O standards, and the 125 MHz input-clock constraint. |

## Simulation Testbenches

Files are located under `CryptoCore_RV32.srcs/sim_1/imports/tb/`. They stimulate RTL and check its behavior; they are not synthesized into FPGA hardware.

| File | Purpose |
|---|---|
| `tb_aes128_core.v` | Checks single-block AES-128 encryption and decryption. |
| `tb_sha256_core.v` | Checks SHA-256 initialization and chained-block processing against expected digests. |
| `tb_chacha20_core.v` | Checks a ChaCha20 keystream block against an expected test vector. |
| `tb_aes_modes_axi.v` | Checks two-block CBC encryption/decryption and CTR encryption/decryption through the MMIO interface. |
| `tb_crypto_axi.v` | Checks coprocessor registers, selected operations, results, status, and unsupported-operation handling. |
| `tb_axi_lite_crossbar.v` | Checks crossbar routing and write-channel behavior. |
| `tb_axi_lite_mem.v` | Checks ROM/RAM behavior, independent address/data arrival, and byte-write strobes. |
| `tb_soc_firmware.v` | Boots the normal ROM, observes KAT stages and completion, checks pass status, and reports hardware-assisted benchmark cycles. |
| `tb_soc_trap_firmware.v` | Boots the trap ROM and checks the CPU trap and diagnostic RAM markers. |
| `tb_pynq_z2_top_status.v` | Checks LED mode selection and JB output mapping using forced internal signals. It does not test physical clock generation or reset sequencing. |
| `tb_crypto_perf.v` | Measures crypto processing windows for normalized 64-byte workloads. See `results.md` for the timing boundaries. |

## Waveform Setup Scripts

`manual_sim_runs/` contains display helpers for an already-open XSim simulation. These scripts select useful signals; they do not compile or launch a testbench.

| File | Purpose |
|---|---|
| `wave_common.tcl` | Shared helpers to clear waveforms, find signals, add dividers, set radix, and fit the view. |
| `add_aes128_wave.tcl` | Displays AES core input, output, and control signals. |
| `add_aes_modes_wave.tcl` | Displays CBC/CTR phases, block inputs, keys/counters, results, and wrapper activity. |
| `add_sha256_wave.tcl` | Displays SHA-256 block inputs, control, intermediate state, and digest signals. |
| `add_chacha20_wave.tcl` | Displays ChaCha20 inputs, control, and keystream results. |
| `add_crypto_axi_wave.tcl` | Displays the crypto slave's AXI channels, registers, dispatch state, and core activity. |
| `add_crypto_perf_wave.tcl` | Displays counters and operation state used by the processing-window benchmark. |
| `add_soc_firmware_wave.tcl` | Displays SoC execution, firmware stage/pass markers, and relevant interface activity. |

## Build and Check Scripts

| File under `scripts/` | Purpose |
|---|---|
| `create_project.tcl` | Creates a Vivado project under `build/` from versioned RTL, ROM images, testbenches, and constraints. |
| `run_sim.tcl` | Opens or creates that project, selects a supported testbench, and runs XSim. |
| `build_bitstream.tcl` | Runs synthesis and implementation, generates the bitstream, and exports utilization, timing, and estimated-power reports under `artifacts/`. |
| `check_repository.ps1` | Checks required files, Markdown links, and workstation-specific absolute paths. This structural check does not compile or simulate RTL. |

## Technical Documentation

| File under `docs/` | Purpose |
|---|---|
| `repository-guide.md` | This file: an index of all versioned files and their roles. |
| `architecture.md` | System connections, memory/register maps, selectors, transaction flow, and board status behavior. |
| `firmware.md` | ROM image roles, debug RAM markers, and the limits of firmware rebuild support. |
| `firmware_listing.md` | Annotated disassembly matching all 512 words of the normal ROM image. |
| `verification.md` | Testbench matrix, simulation commands, waveform examples, and verification limits. |
| `results.md` | Resource use, timing, estimated power, benchmark cycles, throughput calculations, and measurement scope. |
| `assets/README.md` | Explains the organization and selection of documentation images. |

## Documentation Images

Files below are under `docs/assets/`. They are illustrations or recorded results, not inputs required by synthesis.

| File | Purpose |
|---|---|
| `diagrams/system_block_diagram.png` | Raster system architecture illustration. |
| `diagrams/system_block_diagram.svg` | Vector architecture illustration from the project assets; it is a separate source drawing and may differ from the PNG revision. |
| `diagrams/firmware_flowchart.png` | Diagram of firmware initialization, KAT stages, polling, comparison, and completion. |
| `board/system_status_mode.jpg` | Board demonstration with the system-status LED mode selected. |
| `board/firmware_result_mode.jpg` | Board demonstration with the firmware pass-mask LED mode selected. |
| `implementation/device_floorplan.png` | Vivado device placement/floorplan capture. |
| `implementation/utilization_report.png` | Resource utilization report capture. |
| `implementation/timing_report.png` | Timing report capture. |
| `implementation/power_report.png` | Estimated-power report capture. |
| `results/lut_ff_utilization.png` | CPU-only versus coprocessor LUT/FF comparison plot. |
| `results/bram_utilization.png` | BRAM usage comparison plot. |
| `results/timing_wns.png` | Setup WNS comparison plot. |
| `results/power_estimate.png` | Estimated on-chip power comparison plot. |
| `results/performance_comparison.png` | Recorded benchmark performance comparison figure. |
| `waveforms/aes_core.png` | AES core simulation capture. |
| `waveforms/aes_cbc_ctr.jpg` | CBC/CTR simulation capture. |
| `waveforms/sha256_core.png` | SHA-256 simulation capture. |
| `waveforms/chacha20_core.png` | ChaCha20 simulation capture. |
| `waveforms/crypto_axi.png` | Coprocessor interface simulation capture. |
| `waveforms/crypto_performance.png` | Processing-window measurement simulation capture. |
| `waveforms/soc_firmware.png` | End-to-end firmware simulation capture. |

## Generated Local Directories

- `build/`: recreated Vivado project and its generated state.
- `artifacts/`: exported bitstream and implementation reports.
- `.git/`: local Git history and metadata; Git creates this automatically and does not commit it as project content.

An existing local `CryptoCore_RV32.xpr` may remain for convenience, but it is ignored by Git. The portable project creation entry point is `scripts/create_project.tcl`.
