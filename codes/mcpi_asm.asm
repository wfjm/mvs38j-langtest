*        1         2         3         4         5         6         71
*23456789*12345*789012345678901234*678901234567890123456789012345678901
* $Id: mcpi_asm.asm 996 2018-03-03 13:59:23Z mueller $
*
* Copyright 2017-2018 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
*
* This program is free software; you may redistribute and/or modify
* it under the terms of the GNU General Public License version 3.
* See Licence.txt in distribition directory for further details.
*
*  Revision History:
* Date         Rev Version  Comment
* 2018-03-03   996   1.2.1  use sios as path for sios snippets
* 2017-12-29   979   1.2    some more code optimizations
* 2017-12-28   978   1.1    use inverse to avoid divide by constant
* 2017-11-12   961   1.0    Initial version
* 2017-10-10   955   0.1    First draft
*
         PRINT NOGEN              don't show macro expansions
*
* Prime number search
*   RC =  0  ok
*   RC =  8  unexpected SYSIN EOF
*   RC = 12  open SYSIN failed
*   RC = 16  open SYSPRINT failed
*
* local macros --------------------------------------------------------
*
//** ##rinclude ../sios/otxtdsc.asm
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
OOPENOK  OPEN  (SYSIN,INPUT)      open SYSIN
         LTR   R15,R15            test return code
         BE    IOPENOK
         MVI   RC+3,X'0C'
         B     EXIT               quit with RC=12
IOPENOK  EQU   *
*
         LD    FR0,=D'1.'
         LDR   FR2,FR0
         DD    FR0,RR32
         STD   FR0,RR32I          RR32I = 1./RR32
*
* read debug flags ----------------------------------------------------
*
         BAL   R14,IGETLINE       read input line
         BAL   R14,IINT10         get PRNT
         STC   R1,IDBGRR
         BAL   R14,IINT10         get PRNT
         STC   R1,IDBGRN
         BAL   R14,IINT10         get PRNT
         STC   R1,IDBGMC
         MVI   IEOFOK,X'01'       expect EOF from now on
*
         CLI   IDBGRR,X'00'       if any trace skip header print
         BNE   NOHDPRT
         CLI   IDBGRN,X'00'
         BNE   NOHDPRT
         CLI   IDBGMC,X'00'
         BNE   NOHDPRT
         L     R1,MSGHD1
         BAL   R14,OTEXT
         L     R1,MSGHD2
         BAL   R14,OTEXT
         BAL   R14,OPUTLINE       write header
NOHDPRT  EQU   *
*
* main body -----------------------------------------------------------
*
* outer loop
*
         XR    R3,R3              ntry = 0
         XR    R4,R4              nhit = 0
*
OLOOP    BAL   R14,IGETLINE       read input line
         BAL   R14,IINT10         get PRNT
         LTR   R1,R1              is ngo == 0
         BE    OLOOPE             if = yes, quit outer loop
*
* inner loop
*
         LR    R2,R1              loop counter
*
ILOOP    EQU   *
         BAL   R8,RANNUM
         MD    FR0,=D'2.'
         SD    FR0,=D'1.'
         STD   FR0,X
         BAL   R8,RANNUM
         MD    FR0,=D'2.'
         SD    FR0,=D'1.'
         STD   FR0,Y
         MDR   FR0,FR0
         LD    FR2,X
         MDR   FR2,FR2
         ADR   FR0,FR2
         STD   FR0,R
         A     R3,=F'1'
         CD    FR0,=D'1.'
         BH    CMISS
         A     R4,=F'1'
CMISS    EQU   *
         CLI   IDBGMC,X'00'
         BE    NODBGMC
         L     R1,MSGMC
         BAL   R14,OTEXT          print "MC: "
         LD    FR0,X
         BAL   R14,OFIX1308       print x
         LD    FR0,Y
         BAL   R14,OFIX1308       print y
         LD    FR0,R
         BAL   R14,OFIX1308       print r
         LR    R1,R4
         BAL   R14,OINT10         print nhit
         BAL   R14,OPUTLINE       write line
*
NODBGMC  EQU   *
         BCT   R2,ILOOP
*
         L     R0,ODNZERO
         ST    R0,ODTEMP
         ST    R4,ODTEMP+4        nhit as denorm float
         SDR   FR0,FR0            FR0 := 0.
         AD    FR0,ODTEMP         add to re-normalize, FR0:=nhit
         ST    R3,ODTEMP+4        ntry as denorm float
         SDR   FR2,FR2            FR2 := 0.
         AD    FR2,ODTEMP         add to re-normalize, FR2:=ntry
         DDR   FR0,FR2            nhit/ntry
         MD    FR0,=D'4.'         piest = 4.*nhit/ntry
         STD   FR0,PIEST
         SD    FR0,PI             piest - pi
         LPDR  FR0,FR0            pierr = abs(piest - pi)
         STD   FR0,PIERR
*
         L     R1,MSGPI
         BAL   R14,OTEXT          print "PI: "
         LR    R1,R3
         BAL   R14,OINT10         print ntry
         LR    R1,R4
         BAL   R14,OINT10         print nhit
         LD    FR0,PIEST
         BAL   R14,OFIX1308       print piest
         LD    R0,PIERR
         BAL   R14,OFIX1308       print pierr
         LD    FR0,RLAST
         BAL   R14,OFIX1200       print rlast
         BAL   R14,OPUTLINE       write line
*
         B     OLOOP
OLOOPE   EQU   *
*
* close datasets and return to OS -------------------------------------
*
EXIT     CLOSE SYSPRINT           close SYSPRINT
         CLOSE SYSIN              close SYSIN
         L     R13,SAVE+4         get old save area back
         L     R0,RC              get return code
         ST    R0,16(R13)         store in old save R15
         RETURN (14,12)           return to OS (will setup RC)
*
* RANNUM --------------------------------------------------------------
*   uses   all float regs
*   uses   R0,R1,R6,R7,R8,R9,R14,R15
*   keeps  R2-R5,R10-R11
*
RANNUM   CLI   RANINI,X'00'       init done ?
         BNE   RANNUMGO           if != yes
*
         L     R6,=A(RSHUF)       pointer to rshuf
         LA    R7,128             loop count
RANNUML  BAL   R9,RANRAW          get raw 
         STD   FR0,0(R6)          store
         LA    R6,8(R6)           push pointer
         BCT   R7,RANNUML         and loop
         MVI   RANINI,X'01'       ranini = true
*
RANNUMGO L     R6,=A(RSHUF)       pointer to rshuf
         LD    FR0,RLAST
         AW    FR0,ODNZERO        denormalize
         STD   FR0,RFAC1            
         L     R7,RFAC1+4         int(rlast)
         SRL   R7,25              int(rlast/rdiv)
         SLA   R7,3               convert index to offset
         LD    FR0,0(R7,R6)       rshuf[i]
         STD   FR0,RLAST          rlast = rshuf[i]
         BAL   R9,RANRAW          get new random number
         STD   FR0,0(R7,R6)       rshuf[i] = ranraw()
         LD    FR0,RLAST
         MD    FR0,RR32I          rlast*rr32i
         CLI   IDBGRN,X'00'       RN trace ?
         BE    RANNUMNT
*
         STD   FR0,RNEW           save rnew
         L     R1,MSGRN
         BAL   R14,OTEXT          print "RN: "
         LR    R1,R7
         SRA   R1,3               convert back to index
         BAL   R14,OINT10         print i
         LD    FR0,RLAST
         BAL   R14,OFIX1200       print rlast
         LD    FR0,RNEW
         BAL   R14,OFIX1308       print rnew
         BAL   R14,OPUTLINE       write line
         LD    FR0,RNEW           restore rnew
*
RANNUMNT EQU   *
*
         BR    R8
*
* RANRAW --------------------------------------------------------------
*   uses   all float regs
*   uses   R0,R1,R14,R15
*   keeps  R2-R11

RANRAW   LD    FR0,RSEED           
         MD    FR0,RFACTOR        rnew1 = rseed * 69069.
         LDR   FR6,FR0            save rnew1
         LDR   FR2,FR0            rmsb = rnew1
         AW    FR2,ODNZERO        denormalize
         STD   FR2,RFAC1          save
         XR    R1,R1              R1:=0
         ST    R1,RFAC1+4         clear lower 32 bits of rmsb
         SD    FR0,RFAC1          rnew = rnew1 modulo 2^32 !!
         STD   FR0,RNEW
         CLI   IDBGRR,X'00'       RR trace ?
         BE    RANRAWNT
*
         STD   FR4,RFAC           really save rfac
         STD   FR6,RNEW1          really save rnew1
         L     R1,MSGRR
         BAL   R14,OTEXT          print "RR: "
         LD    FR0,RSEED
         BAL   R14,OFIX1200       print rseed
         LD    FR0,RNEW
         BAL   R14,OFIX1200       print rnew
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         L     R1,RFAC+4
         BAL   R14,OINT10         print ifac
         BAL   R14,OPUTLINE       write line
*
RANRAWNT LD    FR0,RNEW
         STD   FR0,RSEED
         BR    R9
*
* include simple output system ----------------------------------------
//** ##rinclude ../sios/sos_base.asm
//** ##rinclude ../sios/sos_oint10.asm
//** ##rinclude ../sios/sos_ohex10.asm
//** ##rinclude ../sios/sos_ohex210.asm
//** ##rinclude ../sios/sos_ofix1308.asm
//** ##rinclude ../sios/sos_ofix1200.asm
* include simple input system -----------------------------------------
//** ##rinclude ../sios/sis_base.asm
//** ##rinclude ../sios/sis_iint10.asm
*
* Work area definitions -----------------------------------------------
*
SAVE     DS    18F                local save area
RC       DC    F'0'               return code
IDBGRR   DC    X'00'              trace RR enable
IDBGRN   DC    X'00'              trace RN enable
IDBGMC   DC    X'00'              trace MC enable
RANINI   DC    X'00'              init RSHUF done flag
         DS    0D
RFACTOR  DC    D'69069.'
RSEED    DC    D'12345.'
RLAST    DC    D'0.'
RR32     DC    D'4294967296.'     is 4*1024*1024*1024
RR32I    DS    D
RNEW     DS    D
RNEW1    DS    D
RFAC     DS    D
RFAC1    DS    D
*
PI       DC    D'3.141592653589793'
PIEST    DS    D
PIERR    DS    D
*
X        DS    D
Y        DS    D
R        DS    D
*
* message strings
*
MSGHD1   OTXTDSC C'          ntry      nhit       pi-est'
MSGHD2   OTXTDSC C'       pi-err        seed'
MSGMC    OTXTDSC C'MC: '
MSGPI    OTXTDSC C'PI: '
MSGRR    OTXTDSC C'RR: '
MSGRN    OTXTDSC C'RN: '
MSGCSEP  OTXTDSC C' : '
*
* spill literal pool
*
         LTORG
*
* data section
*
DATA     CSECT
RSHUF    DS    128D
*
* other defs and end
*
         YREGS ,
FR0      EQU   0
FR2      EQU   2
FR4      EQU   4
FR6      EQU   6
         END   MAIN               define main entry point
