# Annotated Boot ROM Listing

ROM image loaded by Vivado: `CryptoCore_RV32.srcs/sources_1/imports/firmware/boot_rom.hex`.

Verification: all 512 machine-code words in this listing match the checked-in ROM image. This is a disassembly reference, not buildable assembly source.

This document explains the firmware and must not replace `boot_rom.hex` during synthesis. Each line of the ROM image contains one 32-bit RV32I instruction. PicoRV32 fetches instructions from ROM starting at PC `0x00000000`.

## Reading the Table

- `#`: word index in ROM.
- `PC`: instruction byte address.
- `Hex`: machine-code word from the ROM image.
- `Disassembly`: corresponding RISC-V instruction.
- `Explanation`: the instruction's role in the firmware.

## Firmware Memory Map

- `0x10000000`: RAM debug/status: `fw_magic`, `fw_passmask`, `fw_stage`, `fw_detail`.
- `0x20000000`: crypto coprocessor AXI-Lite.
- `0x20000000 + 0x00`: `CTRL`.
- `0x20000000 + 0x04`: `STATUS`.
- `0x20000000 + 0x08`: `ALGO_SEL`.
- `0x20000000 + 0x10`: `BUF[0]`.

## Control and Status Bits

- `STATUS.DONE` is bit 1. Firmware polls it with the instruction sequence `lw STATUS`, `andi ..., 2`, and `beq ..., zero, loop`.
- `CTRL.START` is bit 0. Firmware writes `1` to `CTRL` to request an operation.

## Execution Flow

1. Initialize the status words in data RAM.
2. Request AES-128 encryption.
3. Poll `STATUS.DONE` and compare the ciphertext with the expected result.
4. Request one-block SHA-256 processing.
5. Poll `STATUS.DONE` and compare the digest with the expected result.
6. Request a ChaCha20 keystream block.
7. Poll `STATUS.DONE` and compare the keystream with the expected result.
8. If all tests pass, write `fw_magic = 0x600d0001` and `fw_passmask = 0x7`.
9. Enter the idle loop.

## Instruction Listing

| # | PC | Hex | Disassembly | Explanation |
|---:|---:|---|---|---|
| 000 | `0x0000` | `10001137` | `lui x2/sp, 0x10001` | Set x2/sp = 0x10001000. |
| 001 | `0x0004` | `00010113` | `addi x2/sp, x2/sp, 0` | x2/sp = x2/sp + 0 -> 0x10001000. |
| 002 | `0x0008` | `100001b7` | `lui x3/gp, 0x10000` | Set x3/gp = 0x10000000. |
| 003 | `0x000c` | `00018193` | `addi x3/gp, x3/gp, 0` | x3/gp = x3/gp + 0 -> 0x10000000. |
| 004 | `0x0010` | `20000237` | `lui x4/tp, 0x20000` | Set x4/tp = 0x20000000. |
| 005 | `0x0014` | `00020213` | `addi x4/tp, x4/tp, 0` | x4/tp = x4/tp + 0 -> 0x20000000. |
| 006 | `0x0018` | `0000c2b7` | `lui x5/t0, 0x0000c` | Set x5/t0 = 0x0000c000. |
| 007 | `0x001c` | `0de28293` | `addi x5/t0, x5/t0, 222` | x5/t0 = x5/t0 + 222 -> 0x0000c0de. |
| 008 | `0x0020` | `0051a023` | `sw x5/t0, 0(x3/gp)` | Write 0x0000c0de from x5/t0 to RAM fw_magic (0x10000000). Mark firmware as started. |
| 009 | `0x0024` | `00000a13` | `addi x20/s4, x0/zero, 0` | x20/s4 = x0/zero + 0 -> 0x00000000. |
| 010 | `0x0028` | `0141a223` | `sw x20/s4, 4(x3/gp)` | Write 0x00000000 from x20/s4 to RAM fw_passmask (0x10000004). Update passmask/debug = 0x00000000. |
| 011 | `0x002c` | `0141a423` | `sw x20/s4, 8(x3/gp)` | Write 0x00000000 from x20/s4 to RAM fw_stage (0x10000008). Update stage = 0. |
| 012 | `0x0030` | `0141a623` | `sw x20/s4, 12(x3/gp)` | Write 0x00000000 from x20/s4 to RAM fw_detail (0x1000000c). Store fail detail or mismatch value. |
| 013 | `0x0034` | `00100293` | `addi x5/t0, x0/zero, 1` | x5/t0 = x0/zero + 1 -> 0x00000001. |
| 014 | `0x0038` | `0051a423` | `sw x5/t0, 8(x3/gp)` | Write 0x00000001 from x5/t0 to RAM fw_stage (0x10000008). Update stage = 1. |
| 015 | `0x003c` | `ccddf2b7` | `lui x5/t0, 0xccddf` | Set x5/t0 = 0xccddf000. |
| 016 | `0x0040` | `eff28293` | `addi x5/t0, x5/t0, -257` | x5/t0 = x5/t0 + -257 -> 0xccddeeff. |
| 017 | `0x0044` | `00522823` | `sw x5/t0, 16(x4/tp)` | Write 0xccddeeff from x5/t0 to CRYPTO BUF[0] (0x20000010). |
| 018 | `0x0048` | `8899b2b7` | `lui x5/t0, 0x8899b` | Set x5/t0 = 0x8899b000. |
| 019 | `0x004c` | `abb28293` | `addi x5/t0, x5/t0, -1349` | x5/t0 = x5/t0 + -1349 -> 0x8899aabb. |
| 020 | `0x0050` | `00522a23` | `sw x5/t0, 20(x4/tp)` | Write 0x8899aabb from x5/t0 to CRYPTO BUF[1] (0x20000014). |
| 021 | `0x0054` | `445562b7` | `lui x5/t0, 0x44556` | Set x5/t0 = 0x44556000. |
| 022 | `0x0058` | `67728293` | `addi x5/t0, x5/t0, 1655` | x5/t0 = x5/t0 + 1655 -> 0x44556677. |
| 023 | `0x005c` | `00522c23` | `sw x5/t0, 24(x4/tp)` | Write 0x44556677 from x5/t0 to CRYPTO BUF[2] (0x20000018). |
| 024 | `0x0060` | `001122b7` | `lui x5/t0, 0x00112` | Set x5/t0 = 0x00112000. |
| 025 | `0x0064` | `23328293` | `addi x5/t0, x5/t0, 563` | x5/t0 = x5/t0 + 563 -> 0x00112233. |
| 026 | `0x0068` | `00522e23` | `sw x5/t0, 28(x4/tp)` | Write 0x00112233 from x5/t0 to CRYPTO BUF[3] (0x2000001c). |
| 027 | `0x006c` | `0c0d12b7` | `lui x5/t0, 0x0c0d1` | Set x5/t0 = 0x0c0d1000. |
| 028 | `0x0070` | `e0f28293` | `addi x5/t0, x5/t0, -497` | x5/t0 = x5/t0 + -497 -> 0x0c0d0e0f. |
| 029 | `0x0074` | `02522023` | `sw x5/t0, 32(x4/tp)` | Write 0x0c0d0e0f from x5/t0 to CRYPTO BUF[4] (0x20000020). |
| 030 | `0x0078` | `080912b7` | `lui x5/t0, 0x08091` | Set x5/t0 = 0x08091000. |
| 031 | `0x007c` | `a0b28293` | `addi x5/t0, x5/t0, -1525` | x5/t0 = x5/t0 + -1525 -> 0x08090a0b. |
| 032 | `0x0080` | `02522223` | `sw x5/t0, 36(x4/tp)` | Write 0x08090a0b from x5/t0 to CRYPTO BUF[5] (0x20000024). |
| 033 | `0x0084` | `040502b7` | `lui x5/t0, 0x04050` | Set x5/t0 = 0x04050000. |
| 034 | `0x0088` | `60728293` | `addi x5/t0, x5/t0, 1543` | x5/t0 = x5/t0 + 1543 -> 0x04050607. |
| 035 | `0x008c` | `02522423` | `sw x5/t0, 40(x4/tp)` | Write 0x04050607 from x5/t0 to CRYPTO BUF[6] (0x20000028). |
| 036 | `0x0090` | `000102b7` | `lui x5/t0, 0x00010` | Set x5/t0 = 0x00010000. |
| 037 | `0x0094` | `20328293` | `addi x5/t0, x5/t0, 515` | x5/t0 = x5/t0 + 515 -> 0x00010203. |
| 038 | `0x0098` | `02522623` | `sw x5/t0, 44(x4/tp)` | Write 0x00010203 from x5/t0 to CRYPTO BUF[7] (0x2000002c). |
| 039 | `0x009c` | `00000293` | `addi x5/t0, x0/zero, 0` | x5/t0 = x0/zero + 0 -> 0x00000000. |
| 040 | `0x00a0` | `00522423` | `sw x5/t0, 8(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO ALGO_SEL (0x20000008). Select algorithm AES128_ENC. |
| 041 | `0x00a4` | `00100293` | `addi x5/t0, x0/zero, 1` | x5/t0 = x0/zero + 1 -> 0x00000001. |
| 042 | `0x00a8` | `00522023` | `sw x5/t0, 0(x4/tp)` | Write 0x00000001 from x5/t0 to CRYPTO CTRL (0x20000000). Write START=1 to run the selected algorithm. |
| 043 | `0x00ac` | `00422303` | `lw x6/t1, 4(x4/tp)` | `L_00ac`. Read 32-bit from CRYPTO STATUS (0x20000004) into x6/t1. Runtime value depends on hardware. |
| 044 | `0x00b0` | `00237313` | `andi x6/t1, x6/t1, 2` | x6/t1 = x6/t1 AND 0x002; used to mask a status bit, usually STATUS.DONE. |
| 045 | `0x00b4` | `fe030ce3` | `beq x6/t1, x0/zero, 0x000000ac` | Polling loop: if x6/t1 is still 0, branch back to L_00ac; DONE is not set yet. |
| 046 | `0x00b8` | `06022303` | `lw x6/t1, 96(x4/tp)` | Read 32-bit from CRYPTO BUF[20] (0x20000060) into x6/t1. Runtime value depends on hardware. |
| 047 | `0x00bc` | `70b4c3b7` | `lui x7/t2, 0x70b4c` | Set x7/t2 = 0x70b4c000. |
| 048 | `0x00c0` | `55a38393` | `addi x7/t2, x7/t2, 1370` | x7/t2 = x7/t2 + 1370 -> 0x70b4c55a. |
| 049 | `0x00c4` | `02731e63` | `bne x6/t1, x7/t2, 0x00000100` | If x6/t1 is different from expected value in x7/t2, branch to L_0100; usually fail path. |
| 050 | `0x00c8` | `06422303` | `lw x6/t1, 100(x4/tp)` | Read 32-bit from CRYPTO BUF[21] (0x20000064) into x6/t1. Runtime value depends on hardware. |
| 051 | `0x00cc` | `d8cdb3b7` | `lui x7/t2, 0xd8cdb` | Set x7/t2 = 0xd8cdb000. |
| 052 | `0x00d0` | `78038393` | `addi x7/t2, x7/t2, 1920` | x7/t2 = x7/t2 + 1920 -> 0xd8cdb780. |
| 053 | `0x00d4` | `02731663` | `bne x6/t1, x7/t2, 0x00000100` | If x6/t1 is different from expected value in x7/t2, branch to L_0100; usually fail path. |
| 054 | `0x00d8` | `06822303` | `lw x6/t1, 104(x4/tp)` | Read 32-bit from CRYPTO BUF[22] (0x20000068) into x6/t1. Runtime value depends on hardware. |
| 055 | `0x00dc` | `6a7b03b7` | `lui x7/t2, 0x6a7b0` | Set x7/t2 = 0x6a7b0000. |
| 056 | `0x00e0` | `43038393` | `addi x7/t2, x7/t2, 1072` | x7/t2 = x7/t2 + 1072 -> 0x6a7b0430. |
| 057 | `0x00e4` | `00731e63` | `bne x6/t1, x7/t2, 0x00000100` | If x6/t1 is different from expected value in x7/t2, branch to L_0100; usually fail path. |
| 058 | `0x00e8` | `06c22303` | `lw x6/t1, 108(x4/tp)` | Read 32-bit from CRYPTO BUF[23] (0x2000006c) into x6/t1. Runtime value depends on hardware. |
| 059 | `0x00ec` | `69c4e3b7` | `lui x7/t2, 0x69c4e` | Set x7/t2 = 0x69c4e000. |
| 060 | `0x00f0` | `0d838393` | `addi x7/t2, x7/t2, 216` | x7/t2 = x7/t2 + 216 -> 0x69c4e0d8. |
| 061 | `0x00f4` | `00731663` | `bne x6/t1, x7/t2, 0x00000100` | If x6/t1 is different from expected value in x7/t2, branch to L_0100; usually fail path. |
| 062 | `0x00f8` | `001a6a13` | `ori x20/s4, x20/s4, 1` | x20/s4 = x20/s4 OR 0x001 -> 0x00000001. |
| 063 | `0x00fc` | `00000463` | `beq x0/zero, x0/zero, 0x00000104` | Unconditional branch to L_0104. |
| 064 | `0x0100` | `0061a623` | `sw x6/t1, 12(x3/gp)` | `L_0100`. Write ? from x6/t1 to RAM fw_detail (0x1000000c). Store fail detail or mismatch value. |
| 065 | `0x0104` | `00200293` | `addi x5/t0, x0/zero, 2` | `L_0104`. x5/t0 = x0/zero + 2 -> 0x00000002. |
| 066 | `0x0108` | `00522223` | `sw x5/t0, 4(x4/tp)` | Write 0x00000002 from x5/t0 to CRYPTO STATUS (0x20000004). |
| 067 | `0x010c` | `0141a223` | `sw x20/s4, 4(x3/gp)` | Write 0x00000001 from x20/s4 to RAM fw_passmask (0x10000004). Update passmask/debug = 0x00000001. |
| 068 | `0x0110` | `00200293` | `addi x5/t0, x0/zero, 2` | x5/t0 = x0/zero + 2 -> 0x00000002. |
| 069 | `0x0114` | `0051a423` | `sw x5/t0, 8(x3/gp)` | Write 0x00000002 from x5/t0 to RAM fw_stage (0x10000008). Update stage = 2. |
| 070 | `0x0118` | `616262b7` | `lui x5/t0, 0x61626` | Set x5/t0 = 0x61626000. |
| 071 | `0x011c` | `38028293` | `addi x5/t0, x5/t0, 896` | x5/t0 = x5/t0 + 896 -> 0x61626380. |
| 072 | `0x0120` | `00522823` | `sw x5/t0, 16(x4/tp)` | Write 0x61626380 from x5/t0 to CRYPTO BUF[0] (0x20000010). |
| 073 | `0x0124` | `00000293` | `addi x5/t0, x0/zero, 0` | x5/t0 = x0/zero + 0 -> 0x00000000. |
| 074 | `0x0128` | `00522a23` | `sw x5/t0, 20(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[1] (0x20000014). |
| 075 | `0x012c` | `00522c23` | `sw x5/t0, 24(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[2] (0x20000018). |
| 076 | `0x0130` | `00522e23` | `sw x5/t0, 28(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[3] (0x2000001c). |
| 077 | `0x0134` | `02522023` | `sw x5/t0, 32(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[4] (0x20000020). |
| 078 | `0x0138` | `02522223` | `sw x5/t0, 36(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[5] (0x20000024). |
| 079 | `0x013c` | `02522423` | `sw x5/t0, 40(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[6] (0x20000028). |
| 080 | `0x0140` | `02522623` | `sw x5/t0, 44(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[7] (0x2000002c). |
| 081 | `0x0144` | `02522823` | `sw x5/t0, 48(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[8] (0x20000030). |
| 082 | `0x0148` | `02522a23` | `sw x5/t0, 52(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[9] (0x20000034). |
| 083 | `0x014c` | `02522c23` | `sw x5/t0, 56(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[10] (0x20000038). |
| 084 | `0x0150` | `02522e23` | `sw x5/t0, 60(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[11] (0x2000003c). |
| 085 | `0x0154` | `04522023` | `sw x5/t0, 64(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[12] (0x20000040). |
| 086 | `0x0158` | `04522223` | `sw x5/t0, 68(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[13] (0x20000044). |
| 087 | `0x015c` | `04522423` | `sw x5/t0, 72(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[14] (0x20000048). |
| 088 | `0x0160` | `01800293` | `addi x5/t0, x0/zero, 24` | x5/t0 = x0/zero + 24 -> 0x00000018. |
| 089 | `0x0164` | `04522623` | `sw x5/t0, 76(x4/tp)` | Write 0x00000018 from x5/t0 to CRYPTO BUF[15] (0x2000004c). |
| 090 | `0x0168` | `00100293` | `addi x5/t0, x0/zero, 1` | x5/t0 = x0/zero + 1 -> 0x00000001. |
| 091 | `0x016c` | `00522423` | `sw x5/t0, 8(x4/tp)` | Write 0x00000001 from x5/t0 to CRYPTO ALGO_SEL (0x20000008). Select algorithm SHA256_1BLOCK. |
| 092 | `0x0170` | `00100293` | `addi x5/t0, x0/zero, 1` | x5/t0 = x0/zero + 1 -> 0x00000001. |
| 093 | `0x0174` | `00522023` | `sw x5/t0, 0(x4/tp)` | Write 0x00000001 from x5/t0 to CRYPTO CTRL (0x20000000). Write START=1 to run the selected algorithm. |
| 094 | `0x0178` | `00422303` | `lw x6/t1, 4(x4/tp)` | `L_0178`. Read 32-bit from CRYPTO STATUS (0x20000004) into x6/t1. Runtime value depends on hardware. |
| 095 | `0x017c` | `00237313` | `andi x6/t1, x6/t1, 2` | x6/t1 = x6/t1 AND 0x002; used to mask a status bit, usually STATUS.DONE. |
| 096 | `0x0180` | `fe030ce3` | `beq x6/t1, x0/zero, 0x00000178` | Polling loop: if x6/t1 is still 0, branch back to L_0178; DONE is not set yet. |
| 097 | `0x0184` | `07022303` | `lw x6/t1, 112(x4/tp)` | Read 32-bit from CRYPTO BUF[24] (0x20000070) into x6/t1. Runtime value depends on hardware. |
| 098 | `0x0188` | `f20013b7` | `lui x7/t2, 0xf2001` | Set x7/t2 = 0xf2001000. |
| 099 | `0x018c` | `5ad38393` | `addi x7/t2, x7/t2, 1453` | x7/t2 = x7/t2 + 1453 -> 0xf20015ad. |
| 100 | `0x0190` | `06731e63` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 101 | `0x0194` | `07422303` | `lw x6/t1, 116(x4/tp)` | Read 32-bit from CRYPTO BUF[25] (0x20000074) into x6/t1. Runtime value depends on hardware. |
| 102 | `0x0198` | `b41103b7` | `lui x7/t2, 0xb4110` | Set x7/t2 = 0xb4110000. |
| 103 | `0x019c` | `f6138393` | `addi x7/t2, x7/t2, -159` | x7/t2 = x7/t2 + -159 -> 0xb410ff61. |
| 104 | `0x01a0` | `06731663` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 105 | `0x01a4` | `07822303` | `lw x6/t1, 120(x4/tp)` | Read 32-bit from CRYPTO BUF[26] (0x20000078) into x6/t1. Runtime value depends on hardware. |
| 106 | `0x01a8` | `961783b7` | `lui x7/t2, 0x96178` | Set x7/t2 = 0x96178000. |
| 107 | `0x01ac` | `a9c38393` | `addi x7/t2, x7/t2, -1380` | x7/t2 = x7/t2 + -1380 -> 0x96177a9c. |
| 108 | `0x01b0` | `04731e63` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 109 | `0x01b4` | `07c22303` | `lw x6/t1, 124(x4/tp)` | Read 32-bit from CRYPTO BUF[27] (0x2000007c) into x6/t1. Runtime value depends on hardware. |
| 110 | `0x01b8` | `b00363b7` | `lui x7/t2, 0xb0036` | Set x7/t2 = 0xb0036000. |
| 111 | `0x01bc` | `1a338393` | `addi x7/t2, x7/t2, 419` | x7/t2 = x7/t2 + 419 -> 0xb00361a3. |
| 112 | `0x01c0` | `04731663` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 113 | `0x01c4` | `08022303` | `lw x6/t1, 128(x4/tp)` | Read 32-bit from CRYPTO BUF[28] (0x20000080) into x6/t1. Runtime value depends on hardware. |
| 114 | `0x01c8` | `5dae23b7` | `lui x7/t2, 0x5dae2` | Set x7/t2 = 0x5dae2000. |
| 115 | `0x01cc` | `22338393` | `addi x7/t2, x7/t2, 547` | x7/t2 = x7/t2 + 547 -> 0x5dae2223. |
| 116 | `0x01d0` | `02731e63` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 117 | `0x01d4` | `08422303` | `lw x6/t1, 132(x4/tp)` | Read 32-bit from CRYPTO BUF[29] (0x20000084) into x6/t1. Runtime value depends on hardware. |
| 118 | `0x01d8` | `414143b7` | `lui x7/t2, 0x41414` | Set x7/t2 = 0x41414000. |
| 119 | `0x01dc` | `0de38393` | `addi x7/t2, x7/t2, 222` | x7/t2 = x7/t2 + 222 -> 0x414140de. |
| 120 | `0x01e0` | `02731663` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 121 | `0x01e4` | `08822303` | `lw x6/t1, 136(x4/tp)` | Read 32-bit from CRYPTO BUF[30] (0x20000088) into x6/t1. Runtime value depends on hardware. |
| 122 | `0x01e8` | `8f01d3b7` | `lui x7/t2, 0x8f01d` | Set x7/t2 = 0x8f01d000. |
| 123 | `0x01ec` | `fea38393` | `addi x7/t2, x7/t2, -22` | x7/t2 = x7/t2 + -22 -> 0x8f01cfea. |
| 124 | `0x01f0` | `00731e63` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 125 | `0x01f4` | `08c22303` | `lw x6/t1, 140(x4/tp)` | Read 32-bit from CRYPTO BUF[31] (0x2000008c) into x6/t1. Runtime value depends on hardware. |
| 126 | `0x01f8` | `ba7813b7` | `lui x7/t2, 0xba781` | Set x7/t2 = 0xba781000. |
| 127 | `0x01fc` | `6bf38393` | `addi x7/t2, x7/t2, 1727` | x7/t2 = x7/t2 + 1727 -> 0xba7816bf. |
| 128 | `0x0200` | `00731663` | `bne x6/t1, x7/t2, 0x0000020c` | If x6/t1 is different from expected value in x7/t2, branch to L_020c; usually fail path. |
| 129 | `0x0204` | `002a6a13` | `ori x20/s4, x20/s4, 2` | x20/s4 = x20/s4 OR 0x002 -> 0x00000003. |
| 130 | `0x0208` | `00000463` | `beq x0/zero, x0/zero, 0x00000210` | Unconditional branch to L_0210. |
| 131 | `0x020c` | `0061a623` | `sw x6/t1, 12(x3/gp)` | `L_020c`. Write ? from x6/t1 to RAM fw_detail (0x1000000c). Store fail detail or mismatch value. |
| 132 | `0x0210` | `00200293` | `addi x5/t0, x0/zero, 2` | `L_0210`. x5/t0 = x0/zero + 2 -> 0x00000002. |
| 133 | `0x0214` | `00522223` | `sw x5/t0, 4(x4/tp)` | Write 0x00000002 from x5/t0 to CRYPTO STATUS (0x20000004). |
| 134 | `0x0218` | `0141a223` | `sw x20/s4, 4(x3/gp)` | Write 0x00000003 from x20/s4 to RAM fw_passmask (0x10000004). Update passmask/debug = 0x00000003. |
| 135 | `0x021c` | `00300293` | `addi x5/t0, x0/zero, 3` | x5/t0 = x0/zero + 3 -> 0x00000003. |
| 136 | `0x0220` | `0051a423` | `sw x5/t0, 8(x3/gp)` | Write 0x00000003 from x5/t0 to RAM fw_stage (0x10000008). Update stage = 3. |
| 137 | `0x0224` | `030202b7` | `lui x5/t0, 0x03020` | Set x5/t0 = 0x03020000. |
| 138 | `0x0228` | `10028293` | `addi x5/t0, x5/t0, 256` | x5/t0 = x5/t0 + 256 -> 0x03020100. |
| 139 | `0x022c` | `02522823` | `sw x5/t0, 48(x4/tp)` | Write 0x03020100 from x5/t0 to CRYPTO BUF[8] (0x20000030). |
| 140 | `0x0230` | `070602b7` | `lui x5/t0, 0x07060` | Set x5/t0 = 0x07060000. |
| 141 | `0x0234` | `50428293` | `addi x5/t0, x5/t0, 1284` | x5/t0 = x5/t0 + 1284 -> 0x07060504. |
| 142 | `0x0238` | `02522a23` | `sw x5/t0, 52(x4/tp)` | Write 0x07060504 from x5/t0 to CRYPTO BUF[9] (0x20000034). |
| 143 | `0x023c` | `0b0a12b7` | `lui x5/t0, 0x0b0a1` | Set x5/t0 = 0x0b0a1000. |
| 144 | `0x0240` | `90828293` | `addi x5/t0, x5/t0, -1784` | x5/t0 = x5/t0 + -1784 -> 0x0b0a0908. |
| 145 | `0x0244` | `02522c23` | `sw x5/t0, 56(x4/tp)` | Write 0x0b0a0908 from x5/t0 to CRYPTO BUF[10] (0x20000038). |
| 146 | `0x0248` | `0f0e12b7` | `lui x5/t0, 0x0f0e1` | Set x5/t0 = 0x0f0e1000. |
| 147 | `0x024c` | `d0c28293` | `addi x5/t0, x5/t0, -756` | x5/t0 = x5/t0 + -756 -> 0x0f0e0d0c. |
| 148 | `0x0250` | `02522e23` | `sw x5/t0, 60(x4/tp)` | Write 0x0f0e0d0c from x5/t0 to CRYPTO BUF[11] (0x2000003c). |
| 149 | `0x0254` | `131212b7` | `lui x5/t0, 0x13121` | Set x5/t0 = 0x13121000. |
| 150 | `0x0258` | `11028293` | `addi x5/t0, x5/t0, 272` | x5/t0 = x5/t0 + 272 -> 0x13121110. |
| 151 | `0x025c` | `04522023` | `sw x5/t0, 64(x4/tp)` | Write 0x13121110 from x5/t0 to CRYPTO BUF[12] (0x20000040). |
| 152 | `0x0260` | `171612b7` | `lui x5/t0, 0x17161` | Set x5/t0 = 0x17161000. |
| 153 | `0x0264` | `51428293` | `addi x5/t0, x5/t0, 1300` | x5/t0 = x5/t0 + 1300 -> 0x17161514. |
| 154 | `0x0268` | `04522223` | `sw x5/t0, 68(x4/tp)` | Write 0x17161514 from x5/t0 to CRYPTO BUF[13] (0x20000044). |
| 155 | `0x026c` | `1b1a22b7` | `lui x5/t0, 0x1b1a2` | Set x5/t0 = 0x1b1a2000. |
| 156 | `0x0270` | `91828293` | `addi x5/t0, x5/t0, -1768` | x5/t0 = x5/t0 + -1768 -> 0x1b1a1918. |
| 157 | `0x0274` | `04522423` | `sw x5/t0, 72(x4/tp)` | Write 0x1b1a1918 from x5/t0 to CRYPTO BUF[14] (0x20000048). |
| 158 | `0x0278` | `1f1e22b7` | `lui x5/t0, 0x1f1e2` | Set x5/t0 = 0x1f1e2000. |
| 159 | `0x027c` | `d1c28293` | `addi x5/t0, x5/t0, -740` | x5/t0 = x5/t0 + -740 -> 0x1f1e1d1c. |
| 160 | `0x0280` | `04522623` | `sw x5/t0, 76(x4/tp)` | Write 0x1f1e1d1c from x5/t0 to CRYPTO BUF[15] (0x2000004c). |
| 161 | `0x0284` | `00100293` | `addi x5/t0, x0/zero, 1` | x5/t0 = x0/zero + 1 -> 0x00000001. |
| 162 | `0x0288` | `04522823` | `sw x5/t0, 80(x4/tp)` | Write 0x00000001 from x5/t0 to CRYPTO BUF[16] (0x20000050). |
| 163 | `0x028c` | `090002b7` | `lui x5/t0, 0x09000` | Set x5/t0 = 0x09000000. |
| 164 | `0x0290` | `00028293` | `addi x5/t0, x5/t0, 0` | x5/t0 = x5/t0 + 0 -> 0x09000000. |
| 165 | `0x0294` | `04522a23` | `sw x5/t0, 84(x4/tp)` | Write 0x09000000 from x5/t0 to CRYPTO BUF[17] (0x20000054). |
| 166 | `0x0298` | `4a0002b7` | `lui x5/t0, 0x4a000` | Set x5/t0 = 0x4a000000. |
| 167 | `0x029c` | `00028293` | `addi x5/t0, x5/t0, 0` | x5/t0 = x5/t0 + 0 -> 0x4a000000. |
| 168 | `0x02a0` | `04522c23` | `sw x5/t0, 88(x4/tp)` | Write 0x4a000000 from x5/t0 to CRYPTO BUF[18] (0x20000058). |
| 169 | `0x02a4` | `00000293` | `addi x5/t0, x0/zero, 0` | x5/t0 = x0/zero + 0 -> 0x00000000. |
| 170 | `0x02a8` | `04522e23` | `sw x5/t0, 92(x4/tp)` | Write 0x00000000 from x5/t0 to CRYPTO BUF[19] (0x2000005c). |
| 171 | `0x02ac` | `00200293` | `addi x5/t0, x0/zero, 2` | x5/t0 = x0/zero + 2 -> 0x00000002. |
| 172 | `0x02b0` | `00522423` | `sw x5/t0, 8(x4/tp)` | Write 0x00000002 from x5/t0 to CRYPTO ALGO_SEL (0x20000008). Select algorithm CHACHA20_BLOCK. |
| 173 | `0x02b4` | `00100293` | `addi x5/t0, x0/zero, 1` | x5/t0 = x0/zero + 1 -> 0x00000001. |
| 174 | `0x02b8` | `00522023` | `sw x5/t0, 0(x4/tp)` | Write 0x00000001 from x5/t0 to CRYPTO CTRL (0x20000000). Write START=1 to run the selected algorithm. |
| 175 | `0x02bc` | `00422303` | `lw x6/t1, 4(x4/tp)` | `L_02bc`. Read 32-bit from CRYPTO STATUS (0x20000004) into x6/t1. Runtime value depends on hardware. |
| 176 | `0x02c0` | `00237313` | `andi x6/t1, x6/t1, 2` | x6/t1 = x6/t1 AND 0x002; used to mask a status bit, usually STATUS.DONE. |
| 177 | `0x02c4` | `fe030ce3` | `beq x6/t1, x0/zero, 0x000002bc` | Polling loop: if x6/t1 is still 0, branch back to L_02bc; DONE is not set yet. |
| 178 | `0x02c8` | `01022303` | `lw x6/t1, 16(x4/tp)` | Read 32-bit from CRYPTO BUF[0] (0x20000010) into x6/t1. Runtime value depends on hardware. |
| 179 | `0x02cc` | `e4e7f3b7` | `lui x7/t2, 0xe4e7f` | Set x7/t2 = 0xe4e7f000. |
| 180 | `0x02d0` | `11038393` | `addi x7/t2, x7/t2, 272` | x7/t2 = x7/t2 + 272 -> 0xe4e7f110. |
| 181 | `0x02d4` | `0e731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 182 | `0x02d8` | `01422303` | `lw x6/t1, 20(x4/tp)` | Read 32-bit from CRYPTO BUF[1] (0x20000014) into x6/t1. Runtime value depends on hardware. |
| 183 | `0x02dc` | `155943b7` | `lui x7/t2, 0x15594` | Set x7/t2 = 0x15594000. |
| 184 | `0x02e0` | `bd138393` | `addi x7/t2, x7/t2, -1071` | x7/t2 = x7/t2 + -1071 -> 0x15593bd1. |
| 185 | `0x02e4` | `0e731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 186 | `0x02e8` | `01822303` | `lw x6/t1, 24(x4/tp)` | Read 32-bit from CRYPTO BUF[2] (0x20000018) into x6/t1. Runtime value depends on hardware. |
| 187 | `0x02ec` | `1fdd13b7` | `lui x7/t2, 0x1fdd1` | Set x7/t2 = 0x1fdd1000. |
| 188 | `0x02f0` | `f5038393` | `addi x7/t2, x7/t2, -176` | x7/t2 = x7/t2 + -176 -> 0x1fdd0f50. |
| 189 | `0x02f4` | `0c731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 190 | `0x02f8` | `01c22303` | `lw x6/t1, 28(x4/tp)` | Read 32-bit from CRYPTO BUF[3] (0x2000001c) into x6/t1. Runtime value depends on hardware. |
| 191 | `0x02fc` | `c47123b7` | `lui x7/t2, 0xc4712` | Set x7/t2 = 0xc4712000. |
| 192 | `0x0300` | `0a338393` | `addi x7/t2, x7/t2, 163` | x7/t2 = x7/t2 + 163 -> 0xc47120a3. |
| 193 | `0x0304` | `0c731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 194 | `0x0308` | `02022303` | `lw x6/t1, 32(x4/tp)` | Read 32-bit from CRYPTO BUF[4] (0x20000020) into x6/t1. Runtime value depends on hardware. |
| 195 | `0x030c` | `c7f4d3b7` | `lui x7/t2, 0xc7f4d` | Set x7/t2 = 0xc7f4d000. |
| 196 | `0x0310` | `1c738393` | `addi x7/t2, x7/t2, 455` | x7/t2 = x7/t2 + 455 -> 0xc7f4d1c7. |
| 197 | `0x0314` | `0a731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 198 | `0x0318` | `02422303` | `lw x6/t1, 36(x4/tp)` | Read 32-bit from CRYPTO BUF[5] (0x20000024) into x6/t1. Runtime value depends on hardware. |
| 199 | `0x031c` | `0368c3b7` | `lui x7/t2, 0x0368c` | Set x7/t2 = 0x0368c000. |
| 200 | `0x0320` | `03338393` | `addi x7/t2, x7/t2, 51` | x7/t2 = x7/t2 + 51 -> 0x0368c033. |
| 201 | `0x0324` | `0a731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 202 | `0x0328` | `02822303` | `lw x6/t1, 40(x4/tp)` | Read 32-bit from CRYPTO BUF[6] (0x20000028) into x6/t1. Runtime value depends on hardware. |
| 203 | `0x032c` | `9aaa23b7` | `lui x7/t2, 0x9aaa2` | Set x7/t2 = 0x9aaa2000. |
| 204 | `0x0330` | `20438393` | `addi x7/t2, x7/t2, 516` | x7/t2 = x7/t2 + 516 -> 0x9aaa2204. |
| 205 | `0x0334` | `08731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 206 | `0x0338` | `02c22303` | `lw x6/t1, 44(x4/tp)` | Read 32-bit from CRYPTO BUF[7] (0x2000002c) into x6/t1. Runtime value depends on hardware. |
| 207 | `0x033c` | `4e6cd3b7` | `lui x7/t2, 0x4e6cd` | Set x7/t2 = 0x4e6cd000. |
| 208 | `0x0340` | `4c338393` | `addi x7/t2, x7/t2, 1219` | x7/t2 = x7/t2 + 1219 -> 0x4e6cd4c3. |
| 209 | `0x0344` | `08731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 210 | `0x0348` | `03022303` | `lw x6/t1, 48(x4/tp)` | Read 32-bit from CRYPTO BUF[8] (0x20000030) into x6/t1. Runtime value depends on hardware. |
| 211 | `0x034c` | `466483b7` | `lui x7/t2, 0x46648` | Set x7/t2 = 0x46648000. |
| 212 | `0x0350` | `2d238393` | `addi x7/t2, x7/t2, 722` | x7/t2 = x7/t2 + 722 -> 0x466482d2. |
| 213 | `0x0354` | `06731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 214 | `0x0358` | `03422303` | `lw x6/t1, 52(x4/tp)` | Read 32-bit from CRYPTO BUF[9] (0x20000034) into x6/t1. Runtime value depends on hardware. |
| 215 | `0x035c` | `09aaa3b7` | `lui x7/t2, 0x09aaa` | Set x7/t2 = 0x09aaa000. |
| 216 | `0x0360` | `f0738393` | `addi x7/t2, x7/t2, -249` | x7/t2 = x7/t2 + -249 -> 0x09aa9f07. |
| 217 | `0x0364` | `06731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 218 | `0x0368` | `03822303` | `lw x6/t1, 56(x4/tp)` | Read 32-bit from CRYPTO BUF[10] (0x20000038) into x6/t1. Runtime value depends on hardware. |
| 219 | `0x036c` | `05d7c3b7` | `lui x7/t2, 0x05d7c` | Set x7/t2 = 0x05d7c000. |
| 220 | `0x0370` | `21438393` | `addi x7/t2, x7/t2, 532` | x7/t2 = x7/t2 + 532 -> 0x05d7c214. |
| 221 | `0x0374` | `04731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 222 | `0x0378` | `03c22303` | `lw x6/t1, 60(x4/tp)` | Read 32-bit from CRYPTO BUF[11] (0x2000003c) into x6/t1. Runtime value depends on hardware. |
| 223 | `0x037c` | `a20293b7` | `lui x7/t2, 0xa2029` | Set x7/t2 = 0xa2029000. |
| 224 | `0x0380` | `bd938393` | `addi x7/t2, x7/t2, -1063` | x7/t2 = x7/t2 + -1063 -> 0xa2028bd9. |
| 225 | `0x0384` | `04731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 226 | `0x0388` | `04022303` | `lw x6/t1, 64(x4/tp)` | Read 32-bit from CRYPTO BUF[12] (0x20000040) into x6/t1. Runtime value depends on hardware. |
| 227 | `0x038c` | `d19c13b7` | `lui x7/t2, 0xd19c1` | Set x7/t2 = 0xd19c1000. |
| 228 | `0x0390` | `2b538393` | `addi x7/t2, x7/t2, 693` | x7/t2 = x7/t2 + 693 -> 0xd19c12b5. |
| 229 | `0x0394` | `02731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 230 | `0x0398` | `04422303` | `lw x6/t1, 68(x4/tp)` | Read 32-bit from CRYPTO BUF[13] (0x20000044) into x6/t1. Runtime value depends on hardware. |
| 231 | `0x039c` | `b94e13b7` | `lui x7/t2, 0xb94e1` | Set x7/t2 = 0xb94e1000. |
| 232 | `0x03a0` | `6de38393` | `addi x7/t2, x7/t2, 1758` | x7/t2 = x7/t2 + 1758 -> 0xb94e16de. |
| 233 | `0x03a4` | `02731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 234 | `0x03a8` | `04822303` | `lw x6/t1, 72(x4/tp)` | Read 32-bit from CRYPTO BUF[14] (0x20000048) into x6/t1. Runtime value depends on hardware. |
| 235 | `0x03ac` | `e883d3b7` | `lui x7/t2, 0xe883d` | Set x7/t2 = 0xe883d000. |
| 236 | `0x03b0` | `0cb38393` | `addi x7/t2, x7/t2, 203` | x7/t2 = x7/t2 + 203 -> 0xe883d0cb. |
| 237 | `0x03b4` | `00731e63` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 238 | `0x03b8` | `04c22303` | `lw x6/t1, 76(x4/tp)` | Read 32-bit from CRYPTO BUF[15] (0x2000004c) into x6/t1. Runtime value depends on hardware. |
| 239 | `0x03bc` | `4e3c53b7` | `lui x7/t2, 0x4e3c5` | Set x7/t2 = 0x4e3c5000. |
| 240 | `0x03c0` | `0a238393` | `addi x7/t2, x7/t2, 162` | x7/t2 = x7/t2 + 162 -> 0x4e3c50a2. |
| 241 | `0x03c4` | `00731663` | `bne x6/t1, x7/t2, 0x000003d0` | If x6/t1 is different from expected value in x7/t2, branch to L_03d0; usually fail path. |
| 242 | `0x03c8` | `004a6a13` | `ori x20/s4, x20/s4, 4` | x20/s4 = x20/s4 OR 0x004 -> 0x00000007. |
| 243 | `0x03cc` | `00000463` | `beq x0/zero, x0/zero, 0x000003d4` | Unconditional branch to L_03d4. |
| 244 | `0x03d0` | `0061a623` | `sw x6/t1, 12(x3/gp)` | `L_03d0`. Write ? from x6/t1 to RAM fw_detail (0x1000000c). Store fail detail or mismatch value. |
| 245 | `0x03d4` | `00200293` | `addi x5/t0, x0/zero, 2` | `L_03d4`. x5/t0 = x0/zero + 2 -> 0x00000002. |
| 246 | `0x03d8` | `00522223` | `sw x5/t0, 4(x4/tp)` | Write 0x00000002 from x5/t0 to CRYPTO STATUS (0x20000004). |
| 247 | `0x03dc` | `0141a223` | `sw x20/s4, 4(x3/gp)` | Write 0x00000007 from x20/s4 to RAM fw_passmask (0x10000004). Update passmask/debug = 0x00000007. |
| 248 | `0x03e0` | `00700293` | `addi x5/t0, x0/zero, 7` | x5/t0 = x0/zero + 7 -> 0x00000007. |
| 249 | `0x03e4` | `005a1a63` | `bne x20/s4, x5/t0, 0x000003f8` | If x20/s4 is different from expected value in x5/t0, branch to L_03f8; usually fail path. |
| 250 | `0x03e8` | `600d02b7` | `lui x5/t0, 0x600d0` | Set x5/t0 = 0x600d0000. |
| 251 | `0x03ec` | `00128293` | `addi x5/t0, x5/t0, 1` | x5/t0 = x5/t0 + 1 -> 0x600d0001. |
| 252 | `0x03f0` | `0051a023` | `sw x5/t0, 0(x3/gp)` | Write 0x600d0001 from x5/t0 to RAM fw_magic (0x10000000). Mark all firmware tests as PASS. |
| 253 | `0x03f4` | `00000a63` | `beq x0/zero, x0/zero, 0x00000408` | Unconditional branch to L_0408. |
| 254 | `0x03f8` | `dead02b7` | `lui x5/t0, 0xdead0` | `L_03f8`. Set x5/t0 = 0xdead0000. |
| 255 | `0x03fc` | `00028293` | `addi x5/t0, x5/t0, 0` | x5/t0 = x5/t0 + 0 -> 0xdead0000. |
| 256 | `0x0400` | `014282b3` | `add x5/t0, x5/t0, x20/s4` | Instruction is not classified by this small decoder; keep raw word for reference. |
| 257 | `0x0404` | `0051a023` | `sw x5/t0, 0(x3/gp)` | Write 0xdead0000 from x5/t0 to RAM fw_magic (0x10000000). |
| 258 | `0x0408` | `0141a223` | `sw x20/s4, 4(x3/gp)` | `L_0408`. Write 0x00000007 from x20/s4 to RAM fw_passmask (0x10000004). Update passmask/debug = 0x00000007. |
| 259 | `0x040c` | `0001a423` | `sw x0/zero, 8(x3/gp)` | Write 0x00000000 from x0/zero to RAM fw_stage (0x10000008). Update stage = 0. |
| 260 | `0x0410` | `fe000ce3` | `beq x0/zero, x0/zero, 0x00000408` | Polling loop: if x0/zero is still 0, branch back to L_0408; DONE is not set yet. |
| 261 | `0x0414` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 262 | `0x0418` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 263 | `0x041c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 264 | `0x0420` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 265 | `0x0424` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 266 | `0x0428` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 267 | `0x042c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 268 | `0x0430` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 269 | `0x0434` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 270 | `0x0438` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 271 | `0x043c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 272 | `0x0440` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 273 | `0x0444` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 274 | `0x0448` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 275 | `0x044c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 276 | `0x0450` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 277 | `0x0454` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 278 | `0x0458` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 279 | `0x045c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 280 | `0x0460` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 281 | `0x0464` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 282 | `0x0468` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 283 | `0x046c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 284 | `0x0470` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 285 | `0x0474` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 286 | `0x0478` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 287 | `0x047c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 288 | `0x0480` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 289 | `0x0484` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 290 | `0x0488` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 291 | `0x048c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 292 | `0x0490` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 293 | `0x0494` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 294 | `0x0498` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 295 | `0x049c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 296 | `0x04a0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 297 | `0x04a4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 298 | `0x04a8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 299 | `0x04ac` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 300 | `0x04b0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 301 | `0x04b4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 302 | `0x04b8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 303 | `0x04bc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 304 | `0x04c0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 305 | `0x04c4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 306 | `0x04c8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 307 | `0x04cc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 308 | `0x04d0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 309 | `0x04d4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 310 | `0x04d8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 311 | `0x04dc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 312 | `0x04e0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 313 | `0x04e4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 314 | `0x04e8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 315 | `0x04ec` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 316 | `0x04f0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 317 | `0x04f4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 318 | `0x04f8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 319 | `0x04fc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 320 | `0x0500` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 321 | `0x0504` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 322 | `0x0508` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 323 | `0x050c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 324 | `0x0510` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 325 | `0x0514` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 326 | `0x0518` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 327 | `0x051c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 328 | `0x0520` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 329 | `0x0524` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 330 | `0x0528` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 331 | `0x052c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 332 | `0x0530` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 333 | `0x0534` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 334 | `0x0538` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 335 | `0x053c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 336 | `0x0540` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 337 | `0x0544` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 338 | `0x0548` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 339 | `0x054c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 340 | `0x0550` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 341 | `0x0554` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 342 | `0x0558` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 343 | `0x055c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 344 | `0x0560` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 345 | `0x0564` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 346 | `0x0568` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 347 | `0x056c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 348 | `0x0570` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 349 | `0x0574` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 350 | `0x0578` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 351 | `0x057c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 352 | `0x0580` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 353 | `0x0584` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 354 | `0x0588` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 355 | `0x058c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 356 | `0x0590` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 357 | `0x0594` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 358 | `0x0598` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 359 | `0x059c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 360 | `0x05a0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 361 | `0x05a4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 362 | `0x05a8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 363 | `0x05ac` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 364 | `0x05b0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 365 | `0x05b4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 366 | `0x05b8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 367 | `0x05bc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 368 | `0x05c0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 369 | `0x05c4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 370 | `0x05c8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 371 | `0x05cc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 372 | `0x05d0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 373 | `0x05d4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 374 | `0x05d8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 375 | `0x05dc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 376 | `0x05e0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 377 | `0x05e4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 378 | `0x05e8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 379 | `0x05ec` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 380 | `0x05f0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 381 | `0x05f4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 382 | `0x05f8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 383 | `0x05fc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 384 | `0x0600` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 385 | `0x0604` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 386 | `0x0608` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 387 | `0x060c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 388 | `0x0610` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 389 | `0x0614` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 390 | `0x0618` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 391 | `0x061c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 392 | `0x0620` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 393 | `0x0624` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 394 | `0x0628` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 395 | `0x062c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 396 | `0x0630` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 397 | `0x0634` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 398 | `0x0638` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 399 | `0x063c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 400 | `0x0640` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 401 | `0x0644` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 402 | `0x0648` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 403 | `0x064c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 404 | `0x0650` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 405 | `0x0654` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 406 | `0x0658` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 407 | `0x065c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 408 | `0x0660` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 409 | `0x0664` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 410 | `0x0668` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 411 | `0x066c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 412 | `0x0670` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 413 | `0x0674` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 414 | `0x0678` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 415 | `0x067c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 416 | `0x0680` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 417 | `0x0684` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 418 | `0x0688` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 419 | `0x068c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 420 | `0x0690` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 421 | `0x0694` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 422 | `0x0698` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 423 | `0x069c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 424 | `0x06a0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 425 | `0x06a4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 426 | `0x06a8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 427 | `0x06ac` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 428 | `0x06b0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 429 | `0x06b4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 430 | `0x06b8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 431 | `0x06bc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 432 | `0x06c0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 433 | `0x06c4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 434 | `0x06c8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 435 | `0x06cc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 436 | `0x06d0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 437 | `0x06d4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 438 | `0x06d8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 439 | `0x06dc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 440 | `0x06e0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 441 | `0x06e4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 442 | `0x06e8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 443 | `0x06ec` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 444 | `0x06f0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 445 | `0x06f4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 446 | `0x06f8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 447 | `0x06fc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 448 | `0x0700` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 449 | `0x0704` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 450 | `0x0708` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 451 | `0x070c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 452 | `0x0710` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 453 | `0x0714` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 454 | `0x0718` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 455 | `0x071c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 456 | `0x0720` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 457 | `0x0724` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 458 | `0x0728` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 459 | `0x072c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 460 | `0x0730` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 461 | `0x0734` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 462 | `0x0738` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 463 | `0x073c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 464 | `0x0740` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 465 | `0x0744` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 466 | `0x0748` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 467 | `0x074c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 468 | `0x0750` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 469 | `0x0754` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 470 | `0x0758` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 471 | `0x075c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 472 | `0x0760` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 473 | `0x0764` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 474 | `0x0768` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 475 | `0x076c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 476 | `0x0770` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 477 | `0x0774` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 478 | `0x0778` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 479 | `0x077c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 480 | `0x0780` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 481 | `0x0784` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 482 | `0x0788` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 483 | `0x078c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 484 | `0x0790` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 485 | `0x0794` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 486 | `0x0798` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 487 | `0x079c` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 488 | `0x07a0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 489 | `0x07a4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 490 | `0x07a8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 491 | `0x07ac` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 492 | `0x07b0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 493 | `0x07b4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 494 | `0x07b8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 495 | `0x07bc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 496 | `0x07c0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 497 | `0x07c4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 498 | `0x07c8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 499 | `0x07cc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 500 | `0x07d0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 501 | `0x07d4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 502 | `0x07d8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 503 | `0x07dc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 504 | `0x07e0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 505 | `0x07e4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 506 | `0x07e8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 507 | `0x07ec` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 508 | `0x07f0` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 509 | `0x07f4` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 510 | `0x07f8` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
| 511 | `0x07fc` | `00000013` | `nop` | Do nothing; unused ROM space is filled with NOP. |
