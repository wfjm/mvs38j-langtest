*        1         2         3         4         5         6         71
*23456789*12345*789012345678901234*678901234567890123456789012345678901
* $Id: test_sos.asm 988 2018-01-13 13:34:57Z mueller $
*
* Copyright 2017-2018 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
*
* This program is free software; you may redistribute and/or modify
* it under the terms of the GNU General Public License version 3.
* See Licence.txt in distribition directory for further details.
*
*  Revision History:
* Date         Rev Version  Comment
* 2017-12-09   968   1.1.2  add OINT02 test
* 2017-12-01   967   1.1.1  add OFIX1200,OREGDMP tests
* 2017-11-26   966   1.1    add OINT04,OINT12,OFIX1306 tests
* 2017-11-12   961   1.0    Initial version
* 2017-10-15   956   0.1    First draft
*
         PRINT NOGEN              don't show macro expansions
*
* Test STCK instruction
*   RC =  0  ok
*   RC = 16  open SYSPRINT failed
*
* local macros --------------------------------------------------------
//** ##rinclude ../clib/otxtdsc.asm
*
* main preamble -------------------------------------------------------
*
MAIN     START 0                  start main code csect at base 0
         SAVE  (14,12)            Save input registers
         LR    R12,R15            base register := entry address
         USING MAIN,R12           declare base register
         ST    R13,SAVE+4         set back pointer in current save area
         LR    R2,R13             remember callers save area
         LA    R13,SAVE           setup current save area
         ST    R13,8(R2)          set forw pointer in callers save area
*
* open datasets -------------------------------------------------------
*
         OPEN  (SYSPRINT,OUTPUT)  open SYSPRINT
         LTR   R15,R15            test return code
         BE    OOPENOK
         MVI   RC+3,X'10'
         B     EXIT               quit with RC=16
OOPENOK  EQU   *
*
* main body -----------------------------------------------------------
*
* test OINT02,OINT04,OINT10,OINT12 -------------------------
*
         L     R1,MINT10
         BAL   R14,OTEXT          print heading
         BAL   R14,OPUTLINE       write line
*
         L     R2,=A(TINT10)      pointer to OINT10 data
LINT10   L     R1,0(R2)           get text pointer
         LTR   R1,R1              check for end of list
         BE    EINT10             if = end, quit
*
         BAL   R14,OTEXT          print message
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get number
         BAL   R14,OINT02         print in INT02
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get number
         BAL   R14,OINT04         print in INT04
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get number
         BAL   R14,OINT10         print in INT10
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get number
         BAL   R14,OINT12         print in INT12
         BAL   R14,OPUTLINE       write line
         LA    R2,8(R2)           push pointer
         B     LINT10
EINT10   EQU   *
*
* test OHEX10 ----------------------------------------------
*
         BAL   R14,OPUTLINE       write empty line
         L     R1,MHEX10
         BAL   R14,OTEXT          print heading
         BAL   R14,OPUTLINE       write line
*
         L     R2,=A(THEX10)      pointer to OHEX10 data
LHEX10   L     R1,0(R2)           get text pointer
         LTR   R1,R1              check for end of list
         BE    EHEX10             if = end, quit
*
         BAL   R14,OTEXT          print message
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get number
         BAL   R14,OHEX10         print in HEX10
         BAL   R14,OPUTLINE       write line
         LA    R2,8(R2)           push pointer
         B     LHEX10
EHEX10   EQU   *
*
* test OREGDMP ---------------------------------------------
*
         BAL   R14,OPUTLINE       write empty line
         L     R1,MREGDMP
         BAL   R14,OTEXT          print heading
         BAL   R14,OPUTLINE       write line
*
         LM    R0,R11,TREGPAT1    load print pattern
         BAL   R14,OREGDMP        and dump
*
         LM    R0,R11,TREGPAT2    load print pattern
         L     R15,MREGDMPM       load message (R15!)
         BAL   R14,OREGDMPM       and dump
         L     R15,MREGDMPN       load message
         BAL   R14,OREGDMPM       and dump (should give same regs)
*
* test OFIX1308, OFIX1306-----------------------------------
*
         BAL   R14,OPUTLINE       write empty line
         L     R1,MFIX1308
         BAL   R14,OTEXT          print heading
         BAL   R14,OPUTLINE       write line
*
         L     R2,=A(TFIX1308)    pointer to OFIX1308 data
LFIX1308 L     R1,0(R2)           get text pointer
         LTR   R1,R1              check for end of list
         BE    EFIX1308           if = end, quit
*
         BAL   R14,OTEXT          print message
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get pointer to number
         BAL   R14,OHEX210        print in HEX210
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get pointer to number
         LD    FR0,0(R1)
         BAL   R14,OFIX1308       print in FIX1308
*
***         L     R1,MSGCSEP
***         BAL   R14,OTEXT          print ": "
***         LA    R1,ODTEMP
***         BAL   R14,OHEX210        print ODTEMP in HEX210
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get pointer to number
         LD    FR0,0(R1)
         BAL   R14,OFIX1306       print in FIX1306
*
         BAL   R14,OPUTLINE       write line
         LA    R2,8(R2)           push pointer
         B     LFIX1308
EFIX1308 EQU   *
*
* test OFIX1200 --------------------------------------------
*
         BAL   R14,OPUTLINE       write empty line
         L     R1,MFIX1200
         BAL   R14,OTEXT          print heading
         BAL   R14,OPUTLINE       write line
*
         L     R2,=A(TFIX1200)    pointer to OFIX1200 data
LFIX1200 L     R1,0(R2)           get text pointer
         LTR   R1,R1              check for end of list
         BE    EFIX1200           if = end, quit
*
         BAL   R14,OTEXT          print message
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get pointer to number
         BAL   R14,OHEX210        print in HEX210
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ": "
         L     R1,4(R2)           get pointer to number
         LD    FR0,0(R1)
         BAL   R14,OFIX1200       print in FIX1200
*
         BAL   R14,OPUTLINE       write line
         LA    R2,8(R2)           push pointer
         B     LFIX1200
EFIX1200 EQU   *
*
* close datasets and return to OS -------------------------------------
*
EXIT     CLOSE SYSPRINT           close SYSPRINT
         L     R13,SAVE+4         get old save area back
         L     R0,RC              get return code
         ST    R0,16(R13)         store in old save R15
         RETURN (14,12)           return to OS (will setup RC)
*
* Work area definitions -----------------------------------------------
*
* local data -------------------------------------
*
SAVE     DS    18F                local save area
RC       DC    F'0'               return code
*
* message strings --------------------------------
*
MSGCSEP  OTXTDSC C' : '
MINT10   OTXTDSC C'Testing OINT02,OINT04,OINT10,OINT12:'
MHEX10   OTXTDSC C'Testing OHEX10:'
MREGDMP  OTXTDSC C'Testing OREGDMP:'
MREGDMPM OTXTDSC C'Testing OREGDMPM:'
MREGDMPN OTXTDSC C'Testing OREGDMPM (2nd call):'
MFIX1308 OTXTDSC C'Testing OFIX1308,OFIX1306:'
MFIX1200 OTXTDSC C'Testing OFIX1200:'
*
TREGPAT1 DC    X'00010000',X'00010001',X'00010002',X'00010003'
         DC    X'00010004',X'00010005',X'00010006',X'00010007'
         DC    X'00010008',X'00010009',X'0001000A',X'0001000B'
TREGPAT2 DC    X'00220000',X'00220001',X'00220002',X'00220003'
         DC    X'00220004',X'00220005',X'00220006',X'00220007'
         DC    X'00220008',X'00220009',X'0022000A',X'0022000B'
*
* data tables ------------------------------------
*
DATA     CSECT
         DS    0F
*
* for OINT10 tests ---------------------
*
TINT10   OTXTDSC CL12'0'
         DC    F'0'
         OTXTDSC CL12'1'
         DC    F'1'
         OTXTDSC CL12'9'
         DC    F'9'
         OTXTDSC CL12'10'
         DC    F'10'
         OTXTDSC CL12'100'
         DC    F'100'
         OTXTDSC CL12'999'
         DC    F'999'
         OTXTDSC CL12'1000'
         DC    F'1000'
         OTXTDSC CL12'100000000'
         DC    F'100000000'
         OTXTDSC CL12'999999999'
         DC    F'999999999'
         OTXTDSC CL12'1000000000'
         DC    F'1000000000'
         OTXTDSC CL12'2147483647'
         DC    F'2147483647'
         OTXTDSC CL12'-1'
         DC    F'-1'
         OTXTDSC CL12'-10'
         DC    F'-10'
         OTXTDSC CL12'-100'
         DC    F'-100'
         OTXTDSC CL12'-10000'
         DC    F'-10000'
         OTXTDSC CL12'-1000000'
         DC    F'-1000000'
         OTXTDSC CL12'-100000000'
         DC    F'-100000000'
         OTXTDSC CL12'-1000000000'
         DC    F'-1000000000'
         OTXTDSC CL12'-2147483647'
         DC    F'-2147483647'
         DC    F'0'                     end marker
*
* for OHEX10 tests ---------------------
*
THEX10   OTXTDSC CL10'0X01234567'
         DC    X'01234567'
         OTXTDSC CL10'0X89ABCDEF'
         DC    X'89ABCDEF'
         DC    F'0'                     end marker
*
* for OFIX1308 tests -------------------
*
TFIX1308 OTXTDSC CL20'1.0'
         DC    A(CF001)
         OTXTDSC CL20'10.0'
         DC    A(CF002)
         OTXTDSC CL20'19.9999'
         DC    A(CF003)
         OTXTDSC CL20'19.9999999'
         DC    A(CF003A)
         OTXTDSC CL20'20.0'
         DC    A(CF003B)
         OTXTDSC CL20'999.0'
         DC    A(CF004)
         OTXTDSC CL20'1999.0'
         DC    A(CF005)
         OTXTDSC CL20'2000.0'
         DC    A(CF006)
         OTXTDSC CL20'0.1'
         DC    A(CF010)
         OTXTDSC CL20'0.5'
         DC    A(CF010A)
         OTXTDSC CL20'0.01'
         DC    A(CF011)
         OTXTDSC CL20'0.001'
         DC    A(CF012)
         OTXTDSC CL20'0.0001'
         DC    A(CF013)
         OTXTDSC CL20'0.00001'
         DC    A(CF014)
         OTXTDSC CL20'0.000001'
         DC    A(CF015)
         OTXTDSC CL20'0.0000001'
         DC    A(CF016)
         OTXTDSC CL20'0.00000001'
         DC    A(CF017)
         OTXTDSC CL20'-1.0'
         DC    A(CF001N)
         OTXTDSC CL20'-10.0'
         DC    A(CF002N)
         OTXTDSC CL20'-19.9999'
         DC    A(CF003N)
         OTXTDSC CL20'-999.0'
         DC    A(CF004N)
         OTXTDSC CL20'-1999.0'
         DC    A(CF005N)
         OTXTDSC CL20'-2000.0'
         DC    A(CF006N)
         OTXTDSC CL20'-0.001'
         DC    A(CF012N)
         OTXTDSC CL20'-0.000001'
         DC    A(CF015N)
         DC    F'0'                     end marker
*
         DS    0D
CF001    DC    D'1.0'
CF002    DC    D'10.0'
CF003    DC    D'19.9999'
CF003A   DC    D'19.9999999'
CF003B   DC    D'20.0'
CF004    DC    D'999.0'
CF005    DC    D'1999.0'
CF006    DC    D'2000.0'
CF010    DC    D'0.1'
CF010A   DC    D'0.5'
CF011    DC    D'0.01'
CF012    DC    D'0.001'
CF013    DC    D'0.0001'
CF014    DC    D'0.00001'
CF015    DC    D'0.000001'
CF016    DC    D'0.0000001'
CF017    DC    D'0.00000001'
CF001N   DC    D'-1.0'
CF002N   DC    D'-10.0'
CF003N   DC    D'-19.9999'
CF004N   DC    D'-999.0'
CF005N   DC    D'-1999.0'
CF006N   DC    D'-2000.0'
CF012N   DC    D'-0.001'
CF015N   DC    D'-0.000001'
*
* for OFIX1200 tests -------------------
*
TFIX1200 OTXTDSC CL20'0'
         DC    A(CFF001)
         OTXTDSC CL20'1'
         DC    A(CFF002)
         OTXTDSC CL20'1001'
         DC    A(CFF003)
         OTXTDSC CL20'1004321'
         DC    A(CFF004)
         OTXTDSC CL20'1007654321'
         DC    A(CFF005)
         OTXTDSC CL20'10087654321'
         DC    A(CFF006)
         OTXTDSC CL20'99999999999'
         DC    A(CFF007)
         OTXTDSC CL20'100000000000'
         DC    A(CFF008)
         OTXTDSC CL20'-1'
         DC    A(CFF002N)
         DC    F'0'                     end marker
*
CFF001   DC    D'0.'
CFF002   DC    D'1.'
CFF003   DC    D'1001.'
CFF004   DC    D'1004321.'
CFF005   DC    D'1007654321.'
CFF006   DC    D'10087654321.'
CFF007   DC    D'99999999999.'
CFF008   DC    D'100000000000.'
CFF002N  DC    D'-1.'
*
MAIN     CSECT
*
* include simple output system ----------------------------------------
//** ##rinclude ../clib/sos_base.asm
//** ##rinclude ../clib/sos_oint02.asm
//** ##rinclude ../clib/sos_oint04.asm
//** ##rinclude ../clib/sos_oint10.asm
//** ##rinclude ../clib/sos_oint12.asm
//** ##rinclude ../clib/sos_ohex10.asm
//** ##rinclude ../clib/sos_ohex210.asm
//** ##rinclude ../clib/sos_ofix1308.asm
//** ##rinclude ../clib/sos_ofix1200.asm
//** ##rinclude ../clib/sos_oregdmp.asm
*
* spill literal pool for MAIN
*
         LTORG
*
* other defs and end -------------------------------------------------
*
         YREGS ,
FR0      EQU   0
FR2      EQU   2
FR4      EQU   4
FR6      EQU   6
         END   MAIN               define main entry point
