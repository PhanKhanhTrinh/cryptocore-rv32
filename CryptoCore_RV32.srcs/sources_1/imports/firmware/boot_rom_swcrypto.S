/* Software-only RV32I boot ROM.
 * No crypto MMIO or hardware coprocessor is used.
 * Expected AES-like words: 0xdc0f7113, 0x074e9f06, 0x45cdb1f1, 0xeb181eb3
 * Expected SHA-like words: 0x239f9f6e, 0xb341fe29, 0xbe448ea3, 0xdf2c5898, 0x0fa3002b, 0xf8f9ef87, 0x383db4bd, 0x4ab51cec
 * Expected ChaCha-like words: 0xcca28bf4, 0xaa5d8493, 0x4d515bef, 0x1facd4aa
 */
0000: lui sp, 0x10001
0001: addi sp, sp, 0
0002: lui gp, 0x10000
0003: addi gp, gp, 0
0004: lui t0, 0xc
0005: addi t0, t0, 222
0006: sw t0, 0(gp)
0007: addi t0, zero, 0
0008: sw t0, 4(gp)
0009: addi t0, zero, 0
0010: sw t0, 8(gp)
0011: addi t0, zero, 0
0012: sw t0, 12(gp)
0013: addi t0, zero, 1
0014: sw t0, 8(gp)
0015: lui a0, 0x112
0016: addi a0, a0, 563
0017: lui a1, 0x44556
0018: addi a1, a1, 1655
0019: lui a2, 0x8899b
0020: addi a2, a2, -1349
0021: lui a3, 0xccddf
0022: addi a3, a3, -257
0023: lui a4, 0x10
0024: addi a4, a4, 515
0025: lui a5, 0x4050
0026: addi a5, a5, 1543
0027: lui a6, 0x8091
0028: addi a6, a6, -1525
0029: lui a7, 0xc0d1
0030: addi a7, a7, -497
0031: addi s0, zero, 10
0032: lui s1, 0x11111
0033: addi s1, s1, 273
0034: lui s2, 0x1010
0035: addi s2, s2, 257
aes_loop:
0036: add a0, a0, a4
0037: xor a1, a1, a0
0038: slli t0, a1, 3
0039: srli a1, a1, 29
0040: or a1, a1, t0
0041: add a2, a2, a5
0042: xor a3, a3, a2
0043: slli t0, a3, 7
0044: srli a3, a3, 25
0045: or a3, a3, t0
0046: xor a0, a0, a3
0047: xor a2, a2, a1
0048: add a4, a4, s1
0049: add a5, a5, s2
0050: addi s0, s0, -1
0051: bne s0, zero, aes_loop
0052: lui t6, 0xdc0f7
0053: addi t6, t6, 275
0054: bne a0, t6, fail_aes
0055: lui t6, 0x74ea
0056: addi t6, t6, -250
0057: bne a1, t6, fail_aes
0058: lui t6, 0x45cdb
0059: addi t6, t6, 497
0060: bne a2, t6, fail_aes
0061: lui t6, 0xeb182
0062: addi t6, t6, -333
0063: bne a3, t6, fail_aes
0064: addi s4, zero, 1
0065: sw s4, 4(gp)
0066: jal zero, stage_sha
fail_aes:
0067: sw a0, 12(gp)
0068: lui t0, 0xdead0
0069: addi t0, t0, 0
0070: sw t0, 0(gp)
0071: addi t0, zero, 0
0072: sw t0, 4(gp)
0073: addi t0, zero, 1
0074: sw t0, 8(gp)
0075: lui t0, 0xa5a50
0076: addi t0, t0, 1
0077: sw t0, 12(gp)
0078: jal zero, idle
stage_sha:
0079: addi t0, zero, 2
0080: sw t0, 8(gp)
0081: lui a0, 0x6a09e
0082: addi a0, a0, 1639
0083: lui a1, 0xbb67b
0084: addi a1, a1, -379
0085: lui a2, 0x3c6ef
0086: addi a2, a2, 882
0087: lui a3, 0xa54ff
0088: addi a3, a3, 1338
0089: lui a4, 0x510e5
0090: addi a4, a4, 639
0091: lui a5, 0x9b057
0092: addi a5, a5, -1908
0093: lui a6, 0x1f83e
0094: addi a6, a6, -1621
0095: lui a7, 0x5be0d
0096: addi a7, a7, -743
0097: addi s0, zero, 16
0098: lui s1, 0x61626
0099: addi s1, s1, 896
0100: lui s2, 0x9e378
0101: addi s2, s2, -1607
sha_loop:
0102: add t1, a7, a4
0103: slli t0, t1, 6
0104: srli t1, t1, 26
0105: or t1, t1, t0
0106: xor t2, a4, a5
0107: xor t2, t2, a6
0108: add t1, t1, t2
0109: add t1, t1, s1
0110: add t3, a0, zero
0111: slli t0, t3, 2
0112: srli t3, t3, 30
0113: or t3, t3, t0
0114: and t4, a0, a1
0115: xor t3, t3, t4
0116: xor t3, t3, a2
0117: add a7, a6, zero
0118: add a6, a5, zero
0119: add a5, a4, zero
0120: add a4, a3, t1
0121: add a3, a2, zero
0122: add a2, a1, zero
0123: add a1, a0, zero
0124: add a0, t1, t3
0125: add s1, s1, s2
0126: addi s0, s0, -1
0127: bne s0, zero, sha_loop
0128: lui t6, 0x36f7c
0129: addi t6, t6, 1862
0130: bne a0, t6, fail_sha
0131: lui t6, 0xdbc4c
0132: addi t6, t6, 1879
0133: bne a1, t6, fail_sha
0134: lui t6, 0xcd37c
0135: addi t6, t6, 1704
0136: bne a2, t6, fail_sha
0137: lui t6, 0x77cc7
0138: addi t6, t6, 776
0139: bne a3, t6, fail_sha
0140: ori s4, s4, 2
0141: sw s4, 4(gp)
0142: jal zero, stage_chacha
fail_sha:
0143: sw a0, 12(gp)
0144: lui t0, 0xdead0
0145: addi t0, t0, 1
0146: sw t0, 0(gp)
0147: addi t0, zero, 1
0148: sw t0, 4(gp)
0149: addi t0, zero, 2
0150: sw t0, 8(gp)
0151: lui t0, 0x5a5a0
0152: addi t0, t0, 2
0153: sw t0, 12(gp)
0154: jal zero, idle
stage_chacha:
0155: addi t0, zero, 3
0156: sw t0, 8(gp)
0157: lui a0, 0x61708
0158: addi a0, a0, -1947
0159: lui a1, 0x33206
0160: addi a1, a1, 1134
0161: lui a2, 0x79623
0162: addi a2, a2, -718
0163: lui a3, 0x6b206
0164: addi a3, a3, 1396
0165: addi s0, zero, 8
cha_loop:
0166: add a0, a0, a1
0167: xor a3, a3, a0
0168: slli t0, a3, 16
0169: srli a3, a3, 16
0170: or a3, a3, t0
0171: add a2, a2, a3
0172: xor a1, a1, a2
0173: slli t0, a1, 12
0174: srli a1, a1, 20
0175: or a1, a1, t0
0176: add a0, a0, a1
0177: xor a3, a3, a0
0178: slli t0, a3, 8
0179: srli a3, a3, 24
0180: or a3, a3, t0
0181: add a2, a2, a3
0182: xor a1, a1, a2
0183: slli t0, a1, 7
0184: srli a1, a1, 25
0185: or a1, a1, t0
0186: addi s0, s0, -1
0187: bne s0, zero, cha_loop
0188: lui t6, 0xcca29
0189: addi t6, t6, -1036
0190: bne a0, t6, fail_chacha
0191: lui t6, 0xaa5d8
0192: addi t6, t6, 1171
0193: bne a1, t6, fail_chacha
0194: lui t6, 0x4d516
0195: addi t6, t6, -1041
0196: bne a2, t6, fail_chacha
0197: lui t6, 0x1facd
0198: addi t6, t6, 1194
0199: bne a3, t6, fail_chacha
0200: ori s4, s4, 4
0201: sw s4, 4(gp)
0202: lui t0, 0x600d0
0203: addi t0, t0, 1
0204: sw t0, 0(gp)
0205: addi t0, zero, 7
0206: sw t0, 4(gp)
0207: addi t0, zero, 0
0208: sw t0, 8(gp)
0209: addi t0, zero, 0
0210: sw t0, 12(gp)
0211: jal zero, idle
fail_chacha:
0212: sw a0, 12(gp)
0213: lui t0, 0xdead0
0214: addi t0, t0, 3
0215: sw t0, 0(gp)
0216: addi t0, zero, 3
0217: sw t0, 4(gp)
0218: addi t0, zero, 3
0219: sw t0, 8(gp)
0220: lui t0, 0xcaca0
0221: addi t0, t0, 3
0222: sw t0, 12(gp)
idle:
0223: beq zero, zero, idle
