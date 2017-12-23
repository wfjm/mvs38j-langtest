*        1         2         3         4         5         6         71
*23456789*12345*789012345678901234*678901234567890123456789012345678901
* $Id: soep_asm.asm 972 2017-12-23 20:55:41Z mueller $
*
* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
*
* This program is free software; you may redistribute and/or modify
* it under the terms of the GNU General Public License version 3.
* See Licence.txt in distribition directory for further details.
*
*  Revision History:
* Date         Rev Version  Comment
* 2017-12-23   972   1.0.1  change (n-1)/2 --> n/2
* 2017-11-12   961   1.0    Initial version
* 2017-10-03   954   0.1    First draft
*
         PRINT NOGEN              don't show macro expansions
*
* Prime number search
*   RC =  0  ok
*   RC =  4  NMAX out of range
*   RC =  8  unexpected SYSIN EOF
*   RC = 12  open SYSIN failed
*   RC = 16  open SYSPRINT failed
*
* local macros --------------------------------------------------------
*
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
         BAL   R14,IINT10         get NMAX
         ST    R1,NMAX
         BAL   R14,IINT10         get PRNT
         STC   R1,PRNT
*
         L     R1,NMAX
         C     R1,=F'10'          is NMAX >= 10
         BL    NMAXBAD            if < not
         C     R1,=F'10000000'    is NMAX <= 10000000
         BNH   NMAXOK             if <= yes
NMAXBAD  L     R1,MSGPERR
         BAL   R14,OTEXT          print error
         BAL   R14,OPUTLINE       write line
         MVI   RC+3,X'04'
         B     EXIT               quit with RC=4
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
         ST    R2,IMAX
         LA    R5,1(R2)           IMAX+1  (24 bit enough)
         GETMAIN RU,LV=(5)        allocate storage for PRIME
         ST    R1,PRIME           store sieve base
         LR    R9,R1              R9 := PRIME base
*
*   set each PRIME array byte to X'01' ---------------------
         LR    R4,R1              R4 := PRIME
*                                 R5 := IMAX+1 (still)
         XR    R6,R6              R6 := 0
         L     R7,=X'01000000'    R7 := padding=1 and length=0
         MVCL  R4,R6              set all PRIME bytes to 1
*
* sieve phase ---------------------------------------------------------
*   outer loop:  ind  R6  n
*                inc  R4  2
*                lim  R5  sqrt(NMAX)
*   inner loop:  ind  R3  p
*                inc  R6  n
*                lim  R7  pmax
*                     R0,R1,R2    temporaries
*   register usage:
*     R0    temporary
*     R1    temporary
*     R2    temporary
*     R3    inner loop ind p
*     R4    outer loop inc 2
*     R5    outer loop lim sqrt(NMAX)
*     R6    inner loop inc n   (and outer loop ind !!)
*     R7    inner loop lim pmax
*     R8    -- unused --
*     R9    &prime
*     R10   -- unused --
*     R11   -- unused --
*
*
*   equivalent C code:
*     pmax  = &prime[imax];
*     for (n=3; n<=nmsqrt; n+=2) {
*       if (prime[(n-1)/2] == 0) continue;
*       for (p=&prime[(n*n-1)/2]; p<=pmax; p+=n) *p = 0;
*     }
*
         LA    R6,3               outer ind: R6:=3
         LA    R4,2               outer inc: R4:=2
         L     R5,NMSQRT          outer lim: R5:=NMSQRT
         LR    R7,R9                         R7:=&prime
         A     R7,IMAX            inner lim: R7:=&prime[imax]
SIEVO    LR    R2,R6              R2:=n
         SRA   R2,1               R2:=n/2
         AR    R2,R9              R2:=&prime[n/2]
         CLI   0(R2),X'00'        test prime candidate
         BE    SIEVOC             if = not, continue outer loop
*
         LR    R1,R6              R1:=n
         MR    R0,R6              R1:=n*n (lower half, enough)
         LR    R3,R1              R3:=n*n too
*
         SRA   R3,1               R3:=(n*n)/2
         AR    R3,R9              R3:=&prime[(n*n-1)/2]
*
SIEVI    MVI   0(R3),X'00'        *p=0
         BXLE  R3,R6,SIEVI
*
SIEVOC   BXLE  R6,R4,SIEVO
*
* print primes table --------------------------------------------------
*   loop:  ind  R3  i
*          inc  R4  1
*          lim  R5  imax
*               R2  np
*
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
         L     R5,IMAX            lim: R5:=IMAX
PRTLOOP  LR    R6,R3              R6:=i
         AR    R6,R9              R6:=&primes[i]
         CLI   0(R6),X'00'        test whether prime
         BE    PRTLOOPC           if = not, continue
         LR    R1,R3              R1:=i
         SLA   R1,1               R1:=2*i
         LA    R1,1(R1)           R1:=1+2*i
         BAL   R14,OINT10         and print F(10)
         LA    R2,1(R2)           np+=1
         C     R2,=F'10'          check wheter = 10
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
*   loop:  ind  R3  i
*          inc  R4  1
*          lim  R5  imax
*               R2  np
*               R7  il
*               R8  nl
*
         LA    R2,1               np=1
         LA    R7,4               il=4
         LA    R8,10              nl=10
         LA    R3,1               ind: R3:=1
         LA    R4,1               inc: R4:=1
         L     R5,IMAX            lim: R5:=IMAX
TBLLOOP  LR    R6,R3              R6:=i
         AR    R6,R9              R6:=&primes[i]
         CLI   0(R6),X'00'        test whether prime
         BE    NOPRIME            if = not
         LA    R2,1(R2)           np+= 1
NOPRIME  CR    R3,R7              test i != il
         BNE   TBLLOOPC
         LR    R8,R7              nl=il
         SLA   R8,1               nl=2*il
         LA    R8,2(R8)           nl=2+2*il
*
         L     R1,MSGPI
         BAL   R14,OTEXT          print "pi(...."
         LR    R1,R8
         BAL   R14,OINT10         print nl
         L     R1,MSGPISEP
         BAL   R14,OTEXT          print "):..."
         LR    R1,R2
         BAL   R14,OINT10         print np
         BAL   R14,OPUTLINE       write line
*
         LR    R1,R7              R1:=il
         LA    R1,1(R1)           R1:=il+1
         M     R0,=F'10'          R1:=10*(il+1)
         S     R1,=F'1'           R1:=10*(il+1)-1
         LR    R7,R1              update il
*
TBLLOOPC EQU   *
         BXLE  R3,R4,TBLLOOP
*
         C     R8,NMAX            is nl != nmax ?
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
//** ##rinclude ../clib/sos_base.asm
//** ##rinclude ../clib/sos_oint10.asm
* include simple input system -----------------------------------------
//** ##rinclude ../clib/sis_base.asm
//** ##rinclude ../clib/sis_iint10.asm
*
* Work area definitions -----------------------------------------------
*
SAVE     DS    18F                local save area
RC       DC    F'0'               return code
NMAX     DC    F'10000000'        highest prime to search for
NMSQRT   DS    F                  sqrt(NMAX)
IMAX     DS    F                  highest prime array index
PRIME    DS    F                  prime array pointer
PRNT     DC    X'00'              print enable flag
*
* message strings
*
MSGPERR  OTXTDSC C'NMAX must be >= 10 and <= 10000000, abort'
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
