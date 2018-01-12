This directory contains assembler macros or small code sections for
text handling and a very simple I/O system. The modules are

| File | Function |
| -----| -------- |
| [otxtdsc.asm](otxtdsc.asm)           | macro to define a text string descriptor |
| [sis_base.asm](sis_base.asm)         | base module for input handling from `SYSIN` |
| [sis_iint05.asm](sis_iint05.asm)     | `IINT05`: input integer in  format `%5d` |
| [sis_iint10.asm](sis_iint10.asm)     | `IINT10`: input integer in  format `%10d` |
| [sos_base.asm](sos_base.asm)         | base module for output handling to `SYSPRINT` |
| [sos_ofix1200.asm](sos_ofix1200.asm) | `OFIX1200`: output double in `%12.0f` format |
| [sos_ofix1308.asm](sos_ofix1308.asm) | `OFIX1308`,`OFIX1306`: output double in `%13.8f` or `%13.6f` format  |
| [sos_ohex10.asm](sos_ohex10.asm)     | `OHEX10`: output word in `%8.8x` format |
| [sos_ohex210.asm](sos_ohex210.asm)   | `OHEX210`: output a double word in `%8.8x %8.8x` format |
| [sos_oint02.asm](sos_oint02.asm)     | `OINT02`: output integer in `%2d` format |
| [sos_oint04.asm](sos_oint04.asm)     | `OINT04`: output integer in `%4d` format  |
| [sos_oint10.asm](sos_oint10.asm)     | `OINT10`: output integer in `%10d` format  |
| [sos_oint12.asm](sos_oint12.asm)     | `OINT12`: output integer in `%12d` format  |
| [sos_oregdmp.asm](sos_oregdmp.asm)   | `OREGDMP`: output register dump |

See also the test code [test_sos.asm](../tests/test_sos.asm) in the
[tests](../tests) directory which serves as simple test bench for
output modules.
