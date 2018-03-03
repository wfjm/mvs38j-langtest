*        1         2         3         4         5         6         71
*23456789*12345*789012345678901234*678901234567890123456789012345678901
* $Id: towh_asm.asm 996 2018-03-03 13:59:23Z mueller $
*
* Copyright 2017-2018 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
*
* This program is free software; you may redistribute and/or modify
* it under the terms of the GNU General Public License version 3.
* See Licence.txt in distribition directory for further details.
*
*  Revision History:
* Date         Rev Version  Comment
* 2018-03-03   996   1.0.1  use sios as path for sios snippets
* 2017-11-12   961   1.0    Initial version
* 2017-10-10   955   0.1    First draft
*
         PRINT NOGEN              don't show macro expansions
*
* Tower of Hanoi
*   RC =  0  ok
*   RC =  4  MAXDSK out of range
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
         L     R15,=A(STACK)      R15 := current save area
         ST    R13,4(R15)         set back pointer in current save area
         LR    R2,R13             remember callers save area
         LR    R13,R15            setup current save area
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
* read input parameters, and check range ------------------------------
*
         BAL   R14,IGETLINE       read input line
         BAL   R14,IINT05         get NMAX
         ST    R1,MAXDSK
         BAL   R14,IINT05         get PRNT
         STC   R1,TRACE
*
         L     R1,MAXDSK
         C     R1,=F'2'           is MAXDSK >= 2
         BL    MAXDBAD            if < not
         C     R1,=F'30'          is MAXDSK <= 30
         BNH   MAXDOK             if <= yes
MAXDBAD  L     R1,MSGPERR
         BAL   R14,OTEXT          print error
         BAL   R14,OPUTLINE       write line
         MVI   RC+3,X'04'
         B     EXIT               quit with RC=4
MAXDOK   EQU   *         
*
* outer loop over ndsk cases ------------------------------------------
*
DLOOP    XR    R2,R2              R2 := 0
         ST    R2,NCALL           ncall = 0
         ST    R2,NMOVE           nmove = 0
         ST    R2,MAXSTK          maxstk = 0
         ST    R2,CURSTK          curstk = 0
         L     R3,NDSK
         ST    R3,TOW+4           tow[1] = ndsk
         ST    R2,TOW+8           tow[2] = 0
         ST    R2,TOW+12          tow[3] = 0
*
         CLI   TRACE,X'00'        trace enabled ?
         BE    NOTRCLP
         L     R1,MSGSTRT
         BAL   R14,OTEXT          print "STRT..."
         LR    R1,R3
         BAL   R14,OINT04         print ndsk
         BAL   R14,OPUTLINE       write line
NOTRCLP  EQU   *
*
         LR    R0,R3
         LA    R1,1
         LA    R2,3
         LA    R15,MOV
         BALR  R14,R15            mov(ndsk,1,3)
*
         L     R1,MSGDONE
         BAL   R14,OTEXT          print "DONE..."
         L     R1,NDSK
         BAL   R14,OINT04         print ndsk
         L     R1,MSGDOSTK
         BAL   R14,OTEXT          print "  maxstk..."
         L     R1,MAXSTK
         BAL   R14,OINT04         print maxstk
         L     R1,MSGDONCA
         BAL   R14,OTEXT          print "  ncall..."
         L     R1,NCALL
         BAL   R14,OINT10         print ncall
         L     R1,MSGDONMO
         BAL   R14,OTEXT          print "  nmove..."
         L     R1,NMOVE
         BAL   R14,OINT10         print nmove
         BAL   R14,OPUTLINE       write line
*
         L     R1,NDSK            R1 := ndsk
         LA    R1,1(R1)           R1 := ndsk + 1
         C     R1,MAXDSK          is ndsk+1 <= maxdsk
         ST    R1,NDSK            ndsk++
         BNH   DLOOP              if <= yes, go for next size
*
* close datasets and return to OS -------------------------------------
*
EXIT     CLOSE SYSPRINT           close SYSPRINT
         CLOSE SYSIN              close SYSIN
         L     R15,=A(STACK)
         L     R13,4(R15)         get old save area back
         L     R0,RC              get return code
         ST    R0,16(R13)         store in old save R15
         RETURN (14,12)           return to OS (will setup RC)
*
* mov function (called recursively) -----------------------------------
*
*   mov(n,f,t)
*   Register usage
*     R0    n    (input)
*     R1    f    (input)
*     R2    t    (input)
*     R3    copy of n
*     R4    copy of f
*     R5    copy of t
*     R6    work register
*     R7    work register
*     R8    constant 1  (used often)
*     R9    used as linkage for MOVTRC
*     R10   not used
*     R11   not used
*     R12   base (kept from caller !)
*
*
*
MOV      SAVE  (14,10)            Save input registers (not R11,R12) 
         LA    R15,(4*18)(R13)    R15 := current save area
         ST    R13,4(R15)         set back pointer in current save area
         LR    R3,R13             remember callers save area
         LR    R13,R15            setup current save area
         ST    R13,8(R3)          set forw pointer in callers save area
*
         LR    R3,R0              keep n
         LR    R4,R1              keep f
         LR    R5,R2              keep t
         LA    R8,1               constant 1 (often used below)
*
         L     R6,CURSTK
         AR    R6,R8
         ST    R6,CURSTK          curstk++
         C     R6,MAXSTK          is curstk > maxstk ?
         BNH   MAXSTKOK           if <= not, skip maxstk
         ST    R6,MAXSTK          maxstk = curstk
MAXSTKOK EQU   *
*
         L     R6,NCALL
         AR    R6,R8
         ST    R6,NCALL           ncall++
*
         CR    R3,R8              is n == 1 ?
         BNE   MOVGO              if != not, mov-go case
*
* mov-do case
*        
         L     R6,NMOVE
         AR    R6,R8
         ST    R6,NMOVE           nmove++
         LR    R7,R4              R7 := f
         SLA   R7,2
         L     R6,TOW(R7)         R6 := tow[f]
         SR    R6,R8
         ST    R6,TOW(R7)         tow[f]--
         LR    R7,R5              R7 := t
         SLA   R7,2
         L     R6,TOW(R7)         R6 := tow[t]
         AR    R6,R8
         ST    R6,TOW(R7)         tow[t]++
*
         CLI   TRACE,X'00'        trace enabled ?
         BE    NOTRCDO
         L     R1,MSGTRCDO
         BAL   R9,MOVTRC
NOTRCDO  EQU   *
*
         B     MOVEND
*
* mov-go case
*
MOVGO    EQU   *
         CLI   TRACE,X'00'        trace enabled ?
         BE    NOTRCGO
         L     R1,MSGTRCGO
         BAL   R9,MOVTRC
NOTRCGO  EQU   *
*
         LR    R6,R3
         SR    R6,R8              R6 := n-1
         LA    R7,6
         SR    R7,R4
         SR    R7,R5              R7 := 6-(f+t)
*
         LA    R15,MOV
         LR    R0,R6              R0 := n-1
         LR    R1,R4              R1 := f
         LR    R2,R7              R2 := o
         BALR  R14,R15            mov(n-1,f,o)
*
         LA    R0,1               R0 := 1
         LR    R1,R4              R1 := f
         LR    R2,R5              R2 := t
         BALR  R14,R15            mov(1,f,t)
*
         LR    R0,R6              R0 := n-1
         LR    R1,R7              R0 := o
         LR    R2,R5              R0 := t
         BALR  R14,R15            mov(n-1,o,t)
*
MOVEND   EQU   *
         L     R5,CURSTK
         SR    R5,R8
         ST    R5,CURSTK          curstk--
         L     R13,4(R13)         get old save area back
         RETURN (14,10),T         return to caller
*
* local print handler
* used with BAL 9, no local frame !!
*
MOVTRC   BAL   R14,OTEXT          print prefix
         L     R1,CURSTK
         BAL   R14,OINT04         print curstk
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         LR    R1,R3
         BAL   R14,OINT04         print n
         LR    R1,R4
         BAL   R14,OINT04         print f
         LR    R1,R5
         BAL   R14,OINT04         print t
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         L     R1,TOW+4
         BAL   R14,OINT04         print tow[1]
         L     R1,TOW+8
         BAL   R14,OINT04         print tow[2]
         L     R1,TOW+12
         BAL   R14,OINT04         print tow[3]
         BAL   R14,OPUTLINE       write line
         BR    R9
*
* include simple output system ----------------------------------------
//** ##rinclude ../sios/sos_base.asm
//** ##rinclude ../sios/sos_oint10.asm
//** ##rinclude ../sios/sos_oint04.asm
* include simple input system -----------------------------------------
//** ##rinclude ../sios/sis_base.asm
//** ##rinclude ../sios/sis_iint05.asm
*
* Work area definitions -----------------------------------------------
*
RC       DC    F'0'               return code
MAXDSK   DC    F'10'              maximal number of disks
TRACE    DC    X'00'              trace enable flag
*
NDSK     DC    F'2'
NCALL    DC    F'0'
NMOVE    DC    F'0'
MAXSTK   DC    F'0'
CURSTK   DC    F'0'
TOW      DC    4F'0'
*
* message strings
*
MSGPERR  OTXTDSC C'maxdsk out of range (2...30), abort'
MSGSTRT  OTXTDSC C'STRT ndsk='
MSGDONE  OTXTDSC C'DONE ndsk='
MSGDOSTK OTXTDSC C':  maxstk='
MSGDONCA OTXTDSC C'  ncall='
MSGDONMO OTXTDSC C'  nmove='
MSGTRCDO OTXTDSC C'mov-do: '
MSGTRCGO OTXTDSC C'mov-go: '
MSGCSEP  OTXTDSC C' : '
*
* spill literal pool
*
         LTORG
*
* Place the STACK in separate CSECT. Is quite large (~2 kByte)
*
DATA     CSECT
STACK    DS    (32*18)F           save area STACK
*
* other defs and end
*
         YREGS ,
         END   MAIN               define main entry point
