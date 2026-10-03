# Firmware

## Included Images

| File | Purpose |
|---|---|
| `boot_rom_swcrypto.S` | Address-labelled instruction listing for the CPU-only AES-/SHA-/ChaCha-like benchmark; it does not access the coprocessor |
| `boot_rom.hex` | Prebuilt ROM image loaded by the normal design |
| `boot_rom_trap_test.S` | Deliberately executes an illegal instruction to exercise the PicoRV32 trap path |
| `boot_rom_trap.hex` | Prebuilt ROM image used by `tb_soc_trap_firmware` |

`boot_rom_swcrypto.S` is not the source of the normal `boot_rom.hex`. Its address prefixes make it a human-readable listing rather than a file that can be passed unchanged to a standard assembler. The normal coprocessor ROM is supplied as a prebuilt image; the original buildable source and ROM-generation script are not currently included.

The [annotated normal-ROM listing](firmware_listing.md) explains every instruction and was checked word-for-word against all 512 entries of the checked-in `boot_rom.hex`. It is provided for inspection and does not replace a firmware build process.

The normal firmware executes AES-128, SHA-256, and ChaCha20 known-answer tests through the coprocessor MMIO interface. It stores progress and results in the first data-RAM words:

| Data RAM offset | Symbol | Meaning |
|---:|---|---|
| `0x00` | `fw_magic` | Overall firmware completion/pass or failure marker |
| `0x04` | `fw_passmask` | Algorithm pass bits: AES, SHA-256, ChaCha20 |
| `0x08` | `fw_stage` | Current firmware stage |
| `0x0C` | `fw_detail` | First mismatch or diagnostic detail |

The firmware polls `STATUS.DONE`; interrupts and timeout recovery are not implemented in the demonstration firmware. A mismatch is recorded in `fw_detail`, after which execution continues so all algorithm stages can be observed.

## ROM File Portability

RTL refers to the ROM images by basename (`boot_rom.hex` and `boot_rom_trap.hex`). `scripts/create_project.tcl` adds both files as Vivado memory initialization sources, allowing synthesis and XSim to stage them without an absolute path tied to one workstation.
