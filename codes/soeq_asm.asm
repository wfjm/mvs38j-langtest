*        1         2         3         4         5         6         71
*23456789*12345*789012345678901234*678901234567890123456789012345678901
* $Id: soeq_asm.asm 1171 2019-06-28 19:02:57Z mueller $
* SPDX-License-Identifier: GPL-3.0-or-later
* Copyright 2017-2019 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
*
*  Revision History:
* Date         Rev Version  Comment
* 2018-07-13  1034   1.0.3  at CHOPAT quit points
* 2018-03-03   996   1.0.2  use sios as path for sios snippets
* 2017-12-23   972   1.0.1  change (n-1)/2 --> n/2
* 2017-11-19   965   1.1    no XR in inner loop, bit reversed prime[]
* 2017-11-18   963   1.0    Initial version
*
        PRINT NOGEN              don't show macro expansions
*
* Prime number search
*
* Code configuration options via hercjis variable substitutions
*   SET_CHOPAT   0   normal code execution (default)
*                1   quit after init, before sieve
*                2   quit after sieve, before print
*
* Return codes:
*   RC =  0  ok
*   RC =  4  open SYSPRINT failed
*   RC =  8  open SYSIN failed
*   RC = 12  unexpected SYSIN EOF
*   RC = 16  NMAX out of range
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
         MVI   RC+3,X'04'
         B     EXIT               quit with RC=4
OOPENOK  OPEN  (SYSIN,INPUT)      open SYSIN
         LTR   R15,R15            test return code
         BE    IOPENOK
         MVI   RC+3,X'08'
         B     EXIT               quit with RC=8
IOPENOK  EQU   *
*
* read input parameters, and check range ------------------------------
*
         BAL   R14,IGETLINE       read input line
         BAL   R14,IINT10         get NMAX
         ST    R1,NMAX
         BAL   R14,IINT10         get PRNT
         STC   R1,PRNT
*
         L     R1,NMAX
         C     R1,=F'10'          is NMAX >= 10
         BL    NMAXBAD            if < not
         C     R1,=F'100000000'   is NMAX <= 100000000
         BNH   NMAXOK             if <= yes
NMAXBAD  L     R1,MSGPERR
         BAL   R14,OTEXT          print error
         BAL   R14,OPUTLINE       write line
         MVI   RC+3,X'10'
         B     EXIT               quit with RC=16
NMAXOK   EQU   *         
*
* setup phase ---------------------------------------------------------
*
*   calculate sqrt(nmax) -----------------------------------
*     use simple bi-section method
*       R4   low  bound
*       R5   high bound
*       R7   middle (low+high)/2
*
         LA    R4,1               set  low bound
         L     R5,NMAX            set high bound
         LA    R6,32              set iteration limit
NMSQRTLP LR    R7,R4              R7:= low
         AR    R7,R5              R7:= (low+high)
         SRA   R7,1               R7:= (low+high)/2
         LR    R3,R7
         MR    R2,R7              (R2,R3) := R7*R7
         LTR   R2,R2              more than 32 bit ?
         BNE   NMSQRTHI           if != yes, mid too high
         CL    R3,NMAX            mid*mid > NMAX
         BH    NMSQRTHI           if > yes, mid too high
         LR    R4,R7              here mid to  low:  low := mid
         B     NMSQRTGO
NMSQRTHI LR    R5,R7              here mid to high: high := mid
NMSQRTGO LR    R8,R5              R8 := high
         SR    R8,R4              R8 := high-low
         LR    R1,R6
         C     R8,=F'1'           spread <= 1 ?
         BNH   NMSQRTOK           if <= yes, quit
         BCT   R6,NMSQRTLP
         ABEND 99                 abort if doesn't converge
NMSQRTOK EQU   *
         ST    R4,NMSQRT
        
*   allocate PRIME array -----------------------------------
         L     R2,NMAX
         BCTR  R2,0               NMAX-1
         SRA   R2,1               (NMAX-1)/2
         ST    R2,BIMAX
         A     R2,=F'7'           BIMAX+7
         SRA   R2,3               (BIMAX+7)/8
         ST    R2,WIMAX
         LR    R5,R2
         A     R5,=F'1'           WIMAX+1
         GETMAIN RU,LV=(5)        allocate storage for PRIME
         ST    R1,PRIME           store sieve base
         LR    R9,R1              R9 := PRIME base
*
*   set each PRIME array byte to X'01' ---------------------
         LR    R4,R1              R4 := PRIME
*                                 R5 := sizeof(PRIME) (still)
         XR    R6,R6              R6 := 0
         L     R7,=X'FF000000'    R7 := padding=0xFF and length=0
         MVCL  R4,R6              set all PRIME words to 0xFFFF
*
         CLI   CHOPAT,X'01'       quit after init, before sieve ?
         BE    EXIT               if = quit
*
* sieve phase ---------------------------------------------------------
*   outer loop:  ind  R6   n
*                inc  R4   2
*                lim  R5   sqrt(NMAX)
*   inner loop:  ind  R3   i
*                inc  R6   n
*                lim  R7   bimax
*                     R9   &prime
*                     R8   0x80     
*                     R10  0x07
*                     R11  0xFF7F
*                     R0,R1,R2,R15     temporaries
*
*
*   equivalent C code:
*     for (n=3; n<=nmsqrt; n+=2) {
*       i = n/2;
*       if ((prime[i>>3] & (0x80>>(i&0x7))) == 0) continue;
*       for (i=(n*n)/2; i<=bimax ; i+=n) {
*         prime[i>>3] &= (0xff7f>>(i&0x7);     '!!pseudo code !!'
*       }
*     }
*
         LA    R6,3               outer ind: R6:=3
         LA    R4,2               outer inc: R4:=2
         L     R5,NMSQRT          outer lim: R5:=NMSQRT
         L     R7,BIMAX           inner lim: R7:=BIMAX
         LA    R8,X'80'           R8:=0x80
         LA    R10,X'07'          R10:=0x07
         L     R11,=X'FFFFFF7F'   R11:=0xffffff7f
*
SIEVO    LR    R2,R6              R2:=n
         SRA   R2,1               R2:=n/2
         LR    R15,R2             i
         NR    R15,R10            i&0x07
         LR    R1,R8              0x80
         SRL   R1,0(R15)          0x80>>(i&0x7)
         SRL   R2,3               i>>3
         IC    R2,0(R2,R9)        prime[i>>3]
         NR    R2,R1              prime[i>>3] & (0x80>>(i&0x7))
         BZ    SIEVOC             if =0 not, continue outer loop
*
         LR    R1,R6              R1:=n
         MR    R0,R6              R1:=n*n (lower half, enough)
         LR    R3,R1              R3:=n*n too
         SRA   R3,1               R3:=(n*n)/2
*
SIEVI    LR    R2,R3              i
         NR    R2,R10             i&0x7
         LR    R1,R11             0xff7f
         SRL   R1,0(R2)           0xff7f>>(i&0x7)
         LR    R2,R3              i
         SRL   R2,3               i>>3
         IC    R0,0(R2,R9)        prime[i>>3]
         NR    R0,R1              & 0xff7f>>(i&0x7)
         STC   R0,0(R2,R9)        prime[i>>3] &= 0xff7f>>(i&0x7)
         BXLE  R3,R6,SIEVI
*
SIEVOC   BXLE  R6,R4,SIEVO
*
         CLI   CHOPAT,X'02'       quit after sieve, before print ?
         BE    EXIT               if = quit
*
* print primes table --------------------------------------------------
*   loop:  ind  R3   i
*          inc  R4   1
*          lim  R5   imax
*               R2   np
*               R9   &prime
*               R8   0x80   
*               R10  0x07
*               R11  1
PRT      EQU   *
         CLI   PRNT,X'00'         primes to be printed ?
         BE    NOPRNT             if = skip
         L     R1,MSGLIST
         BAL   R14,OTEXT          print heading
         L     R1,NMAX
         BAL   R14,OINT10         print nmax
         BAL   R14,OPUTLINE       write line
*
         LA    R1,2
         BAL   R14,OINT10         print "2"  (1st prime...)
         LA    R2,1               np=1
         LA    R3,1               ind: R3:=1
         LA    R4,1               inc: R4:=1
         L     R5,BIMAX           lim: R5:=BIMAX
         LA    R8,X'80'           R8:=0x80
         LA    R10,X'07'          R10:=0x07
         LA    R11,1              R11:=1
PRTLOOP  LR    R6,R3              i
         NR    R6,R10             i&0x7
         LR    R1,R8              0x80
         SRL   R1,0(R6)           0x80>>(i&0x7)
         LR    R6,R3              i
         SRL   R6,3               i>>3
         IC    R0,0(R6,R9)        prime[i>>3]
         NR    R0,R1              prime[i>>3] & (0x80>>(i&0x7))
         BE    PRTLOOPC           if = not, continue
         LR    R1,R3              R1:=i
         SLA   R1,1               R1:=2*i
         AR    R1,R11             R1:=1+2*i
         BAL   R14,OINT10         and print F(10)
         AR    R2,R11             np+=1
         C     R2,=F'10'          check whether = 10
         BNZ   PRTLOOPC           if != not, continue
         BAL   R14,OPUTLINE       write line
         XR    R2,R2              np=0
PRTLOOPC EQU   *
         BXLE  R3,R4,PRTLOOP
*
         LTR   R2,R2              check prime count np
         BZ    NOPRNT
         BAL   R14,OPUTLINE       write line
NOPRNT   EQU   *
*
* print primes count --------------------------------------------------
*   loop:  ind  R3   i
*          inc  R4   1
*          lim  R5   imax
*               R2   np
*               R7   il
*               R6   nl
*               R9   &prime
*               R8   0x80   
*               R10  0x07
*               R11  1
*
TBL      EQU   *
         LA    R2,1               np=1
         LA    R7,4               il=4
         LA    R6,10              nl=10
         LA    R3,1               ind: R3:=1
         LA    R4,1               inc: R4:=1
         L     R5,BIMAX           lim: R5:=BIMAX
         LA    R8,X'80'           R8:=0x80
         LA    R10,X'07'          R10:=0x07
         LA    R11,1              R11:=1
TBLLOOP  LR    R15,R3             i
         NR    R15,R10            i&0x7
         LR    R1,R8              0x80
         SRL   R1,0(R15)          0x80>>(i&0x7)
         LR    R15,R3             i
         SRL   R15,3              i>>3
         IC    R0,0(R15,R9)       prime[i>>3]
         NR    R0,R1              prime[i>>3] & (1<<(i&0x7))
         BE    NOPRIME            if = not
         AR    R2,R11             np+= 1
NOPRIME  CR    R3,R7              test i != il
         BNE   TBLLOOPC
         LR    R6,R7              nl=il
         SLA   R6,1               nl=2*il
         A     R6,=F'2'           nl=2+2*il
*
         L     R1,MSGPI
         BAL   R14,OTEXT          print "pi(...."
         LR    R1,R6
         BAL   R14,OINT10         print nl
         L     R1,MSGPISEP
         BAL   R14,OTEXT          print "):..."
         LR    R1,R2
         BAL   R14,OINT10         print np
         BAL   R14,OPUTLINE       write line
*
         LR    R1,R7              R1:=il
         AR    R1,R11             R1:=il+1
         M     R0,=F'10'          R1:=10*(il+1)
         SR    R1,R11             R1:=10*(il+1)-1
         LR    R7,R1              update il
*
TBLLOOPC EQU   *
         BXLE  R3,R4,TBLLOOP
*
         C     R6,NMAX            is nl != nmax ?
         BE    TBLNOTR            if = not, skip extra summary
*
         L     R1,MSGPI
         BAL   R14,OTEXT          print "pi(...."
         L     R1,NMAX
         BAL   R14,OINT10         print nmax
         L     R1,MSGPISEP
         BAL   R14,OTEXT          print "):..."
         LR    R1,R2
         BAL   R14,OINT10         print np
         BAL   R14,OPUTLINE       write line
*
TBLNOTR  EQU   *
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
* include simple output system ----------------------------------------
//** ##rinclude ../sios/sos_base.asm
//** ##rinclude ../sios/sos_oint10.asm
* include simple input system -----------------------------------------
//** ##rinclude ../sios/sis_base.asm
//** ##rinclude ../sios/sis_iint10.asm
*
* Work area definitions -----------------------------------------------
*
SAVE     DS    18F                local save area
RC       DC    F'0'               return code
NMAX     DC    F'10000000'        highest prime to search for
NMSQRT   DS    F                  sqrt(NMAX)
BIMAX    DS    F                  highest prime array bit index
WIMAX    DS    F                  highest prime array word index
PRIME    DS    F                  prime array pointer
PRNT     DC    X'00'              print enable flag
CHOPAT   DC    FL1'${SET_CHOPAT:-0}' chop flag
*
* message strings
*
MSGPERR  OTXTDSC C'NMAX must be >= 10 and <= 100000000, abort'
MSGLIST  OTXTDSC C'List of Primes up to '
MSGPI    OTXTDSC C'pi('
MSGPISEP OTXTDSC C'): '
*
* spill literal pool
*
         LTORG
*
* other defs and end
*
         YREGS ,
         END   MAIN               define main entry point
