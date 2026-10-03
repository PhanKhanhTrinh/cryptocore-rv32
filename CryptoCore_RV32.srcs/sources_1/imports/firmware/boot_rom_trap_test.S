/*
 * Deliberate PicoRV32 trap firmware.
 *
 * Before raising the trap, the firmware writes:
 *   fw_magic (0x1000_0000) = 0x5452_4150 ("TRAP")
 *   fw_stage (0x1000_0008) = 1
 *
 * The EBREAK instruction then raises trap because CATCH_ILLINSN is enabled.
 * fw_passmask remains zero, so firmware-result LEDs stay off in SW[0] = 1
 * mode. In SW[0] = 0 mode, LED[2] indicates the asserted CPU trap.
 */

    .section .text
    .option norvc
    .globl _start

_start:
    lui     gp, 0x10000          /* gp = Data RAM base 0x1000_0000 */

    lui     t0, 0x54524
    addi    t0, t0, 0x150       /* t0 = 0x5452_4150 ("TRAP") */
    sw      t0, 0(gp)           /* fw_magic = trap-test marker */

    addi    t1, zero, 1
    sw      t1, 8(gp)           /* fw_stage = 1 */

    ebreak                      /* Deliberately assert PicoRV32 trap */

unreachable:
    j       unreachable
