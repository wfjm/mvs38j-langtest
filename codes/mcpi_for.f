C        1         2         3         4         5         6         712--------
C2345*78901234567890123456789012345678901234567890123456789012345678901234567890
C $Id: mcpi_for.f 964 2017-11-19 08:47:46Z mueller $
C
C Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
C
C This program is free software; you may redistribute and/or modify
C it under the terms of the GNU General Public License version 3.
C See Licence.txt in distribition directory for further details.
C
C  Revision History:
C Date         Rev Version  Comment
C 2017-08-12   938   1.0    Initial version
C 2017-07-30   931   0.1    First draft
C
C --- function ranraw ------------------------------------------------
C
C Fortran IV(1966): function syntax is: 'type FUNCTION name*precision (args)
C however gfortran -std=legacy wants:   'type*precision FUNCTION name (args)
      REAL FUNCTION RANRAW*8 (DUMMY)
C
      COMMON /DBG/IDBGRR,IDBGRN,IDBGMC
      COMMON /RAN/RLAST,RSEED,RSHUF(128),RANINI
      REAL*8 RLAST,RSEED,RSHUF
      LOGICAL RANINI
C
      REAL*8 DUMMY
      REAL*8 RR32
      REAL*8 RFAC,RNEW
      INTEGER IFAC
      DATA RR32  /4294967296.D0/
C
      RNEW = RSEED * 69069.D0
      RFAC = RNEW / RR32
      IFAC = RFAC
      RFAC = IFAC
      RNEW = RNEW - RFAC * RR32
      IF (IDBGRR .NE. 0) WRITE(6,9000) RSEED,RNEW
      RSEED = RNEW
      RANRAW = RNEW
      RETURN
C
 9000 FORMAT(1X,'RR: ',F12.0,1X,F12.0)
      END
C
C --- function rannum ------------------------------------------------
C
      REAL FUNCTION RANNUM*8 (DUMMY)
C
      COMMON /DBG/IDBGRR,IDBGRN,IDBGMC
      COMMON /RAN/RLAST,RSEED,RSHUF(128),RANINI
      REAL*8 RLAST,RSEED,RSHUF
      LOGICAL RANINI
C
      REAL*8 DUMMY
      REAL*8 RR32,RDIV
      REAL*8 RANRAW
      INTEGER I
      DATA RR32  /4294967296.D0/
      DATA RDIV  /33554432.D0/
C
      IF (RANINI) GOTO 1000
      DO 100 I=1,128
        RSHUF(I) = RANRAW(DUMMY)
 100  CONTINUE
      RANINI = .TRUE.
 1000 CONTINUE
C     
      I = RLAST/RDIV
      RLAST = RSHUF(I+1)
      RSHUF(I+1) = RANRAW(DUMMY)
      RANNUM = RLAST/RR32
      IF (IDBGRN .NE. 0) WRITE(6,9000) I,RLAST,RANNUM
      RETURN
C
 9000 FORMAT(1X,'RN: ',I12,1X,F12.0,1X,F12.8)
      END
C
C --- main program ---------------------------------------------------
C     PROGRAM MCPI
      COMMON /DBG/IDBGRR,IDBGRN,IDBGMC
      COMMON /RAN/RLAST,RSEED,RSHUF(128),RANINI
      REAL*8 RLAST,RSEED,RSHUF
      LOGICAL RANINI
C
      INTEGER I
      INTEGER NTRY,NHIT,NGO
      REAL*8 PI,PIEST,PIERR
      REAL*8 X,Y,R
      REAL*8 DUMMY
      REAL*8 RANNUM
      REAL*8 RTRY,RHIT
      DATA PI /3.141592653589793D0/
      DATA NTRY /0/
      DATA NHIT /0/
C
      RSEED  = 12345.D0
      RLAST  = 0.D0
      RANINI = .FALSE.
C
      READ(5,9000,ERR=910,END=900) IDBGRR,IDBGRN,IDBGMC
C
 100  READ(5,9010,ERR=910,END=900) NGO
      IF (NGO .LE. 0) GOTO 900
C
      DO 200 I=1,NGO
        X = 2.*RANNUM(DUMMY) - 1.
        Y = 2.*RANNUM(DUMMY) - 1.
        R = X*X + Y*Y
        NTRY = NTRY + 1
        IF (R .LE. 1.) NHIT = NHIT + 1
        IF (IDBGMC .NE. 0) WRITE(6,9030) X,Y,R,NHIT
 200  CONTINUE
C
      RTRY = NTRY
      RHIT = NHIT
      PIEST = 4.* RHIT / RTRY
      PIERR = PIEST - PI
      IF (PIERR .LT. 0.) PIERR = -PIERR
      WRITE(6,9020) NTRY, NHIT,PIEST,PIERR,RLAST
      GOTO 100
C
 900  CONTINUE
C
      STOP
C
 910  WRITE(6,9040)
      STOP
C
 9000 FORMAT(3I10)
 9010 FORMAT(I10)
 9020 FORMAT(1X,'PI: ',I12,1X,I12,1X,F12.8,1X,F12.8,1X,F12.0)
 9030 FORMAT(1X,'MC: ',F12.8,1X,F12.8,1X,F12.8,1X,I12)
 9040 FORMAT(1X,'conversion error, abort')
C
      END
