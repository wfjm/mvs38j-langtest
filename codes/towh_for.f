C        1         2         3         4         5         6         712--------
C2345*78901234567890123456789012345678901234567890123456789012345678901234567890
C $Id: towh_for.f 964 2017-11-19 08:47:46Z mueller $
C
C Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
C
C This program is free software; you may redistribute and/or modify
C it under the terms of the GNU General Public License version 3.
C See Licence.txt in distribition directory for further details.
C
C  Revision History:
C Date         Rev Version  Comment
C 2017-08-09   934   1.0    Initial version
C 2017-07-30   931   0.1    First draft
C
C --- main program ---------------------------------------------------
C     PROGRAM TOWH
C     
      IMPLICIT LOGICAL (A-Z)
      COMMON /DAT1/NCALL,NMOVE,MAXSTK,MAXDSK,TRACE,TOW(3)
      INTEGER      NCALL,NMOVE,MAXDSK,MAXSTK,TRACE,TOW
      COMMON /DAT2/L,LN(32),LF(32),LT(32),LS(32)
      INTEGER      L,LN,LF,LT,LS
C
      INTEGER NDSK
C
      READ(5,9000,ERR=910,END=900) MAXDSK,TRACE
C
      DO 100 NDSK=2,MAXDSK
        NCALL  = 0
        NMOVE  = 0
        MAXSTK = 0
        TOW(1) = NDSK
        TOW(2) = 0
        TOW(3) = 0
        IF (TRACE .NE. 0) WRITE(6,9010) NDSK
        CALL MOV(NDSK,1,3)
        WRITE(6,9020) NDSK,MAXSTK,NCALL,NMOVE
  100  CONTINUE
C
 900  CONTINUE
      STOP
 910  WRITE(6,9030)
      STOP
C
 9000 FORMAT(2I5)
 9010 FORMAT(1X,'STRT ndsk=',I2)
 9020 FORMAT(1X,'DONE ndsk=',I2,':  maxstk=',I2,'  ncall=',I10,
     *       '  nmove=',I10)
 9030 FORMAT(1X,'conversion error, abort')
      END
C
C --- subroutine mov -------------------------------------------------
C
      SUBROUTINE MOV(N,F,T)
      IMPLICIT LOGICAL (A-Z)
      INTEGER N,F,T
      INTEGER O,L1,S
C
      COMMON /DAT1/NCALL,NMOVE,MAXSTK,MAXDSK,TRACE,TOW(3)
      INTEGER      NCALL,NMOVE,MAXDSK,MAXSTK,TRACE,TOW
      COMMON /DAT2/L,LN(32),LF(32),LT(32),LS(32)
      INTEGER      L,LN,LF,LT,LS
C
      L     = 1
      LN(1) = N
      LF(1) = F
      LT(1) = T
C
 1000 CONTINUE
      NCALL  = NCALL  + 1
      IF (L .GT. MAXSTK) MAXSTK = L
      LS(L) = 1
C
      IF (LN(L) .NE. 1) GOTO 1900
      NMOVE  = NMOVE  + 1
      TOW(LF(L)) = TOW(LF(L)) - 1
      TOW(LT(L)) = TOW(LT(L)) + 1
      IF (TRACE .NE. 0) WRITE(6,9000) L,LN(L),LF(L),LT(L),TOW
      L = L - 1
      IF (L .EQ. 0) RETURN
      GOTO 2000
C
 1900 IF (TRACE .NE. 0) WRITE(6,9010) L,LN(L),LF(L),LT(L),TOW
C
 2000 CONTINUE
      IF (TRACE .GT. 1) WRITE(6,9020) L,LN(L),LF(L),LT(L),TOW,L,LS(L)
      O = 6-(LF(L)+LT(L))
      L1 = L + 1
C Fortran IV(1966): computed GOTO selectors must be un-subscripted integers
      S = LS(L)
      GOTO (2100,2200,2300,2400), S
C
 2100 LN(L1) = LN(L)-1
      LF(L1) = LF(L)
      LT(L1) = O
      LS(L)  = 2
      L = L1
      GOTO 1000
C
 2200 LN(L1) = 1
      LF(L1) = LF(L)
      LT(L1) = LT(L)
      LS(L)  = 3
      L = L1
      GOTO 1000
C
 2300 LN(L1) = LN(L)-1
      LF(L1) = O
      LT(L1) = LT(L)
      LS(L)  = 4
      L = L1
      GOTO 1000
C
 2400 L = L - 1
      IF (L .EQ. 0) RETURN
      GOTO 2000
C
 9000 FORMAT(1X,'mov-do: ',I2,' :',3(1X,I2),' :',3(1X,I2))
 9010 FORMAT(1X,'mov-go: ',I2,' :',3(1X,I2),' :',3(1X,I2))
 9020 FORMAT(1X,'step:   ',I2,' :',3(1X,I2),' :',3(1X,I2),
     *       ' :',I2,'-',I2)
C
      END
