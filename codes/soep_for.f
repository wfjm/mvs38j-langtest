C        1         2         3         4         5         6         712--------
C2345*78901234567890123456789012345678901234567890123456789012345678901234567890
C $Id: soep_for.f 1171 2019-06-28 19:02:57Z mueller $
C SPDX-License-Identifier: GPL-3.0-or-later
C Copyright 2017-2019 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
C
C  Revision History:
C Date         Rev Version  Comment
C 2017-12-25   975   1.1    use sqrt(nmax) as outer loop end
C 2017-12-23   972   1.0.1  change (n-1)/2 --> n/2
C 2017-09-17   951   1.0    Initial version
C 2017-08-26   942   0.1    First draft
C
C --- main program ---------------------------------------------------
C     PROGRAM SOEP
      INTEGER NMAX,PRNT,IMAX,NMSQRT
      INTEGER I,N,IMIN
      INTEGER NP,IL,NL
      INTEGER PLIST(10)
      LOGICAL*1 PRIME(5000000)
C
      READ(5,9000,ERR=910,END=900) NMAX,PRNT
      IF (NMAX .LT. 10 .OR. NMAX .GT. 10000000) GOTO 920
C
      NMSQRT = IFIX(SQRT(FLOAT(NMAX)))
      IMAX = (NMAX-1)/2
      DO 100 I=1,IMAX
        PRIME(I) = .TRUE.
 100  CONTINUE
C
      DO 300 N=3,NMSQRT,2
        IF (.NOT. PRIME(N/2)) GOTO 300
        IMIN = (N*N)/2
        DO 200 I=IMIN,IMAX,N
          PRIME(I) = .FALSE.
 200    CONTINUE
 300  CONTINUE
C
      IF (PRNT .EQ. 0) GOTO 500
      WRITE(6,9010) NMAX
      PLIST(1) = 2
      NP = 1
      DO 400 I=1,IMAX
        IF (.NOT. PRIME(I)) GOTO 400
        NP = NP + 1
        PLIST(NP) = 1+2*I
        IF (NP .LT. 10) GOTO 400
        WRITE(6,9020) PLIST
        NP = 0
 400  CONTINUE
      IF (NP .NE. 0) WRITE(6,9020) (PLIST(I),I=1,NP)
 500  CONTINUE
C
      IL = 4
      NL = 10
      NP = 1
      DO 600 I=1,IMAX
        IF (PRIME(I)) NP = NP + 1
        IF (I .NE. IL) GOTO 650
        NL = 2*IL+2
        WRITE(6,9030) NL,NP
        IL = 10*(IL+1)-1
 650    CONTINUE
 600  CONTINUE
      IF (NL .NE. NMAX) WRITE(6,9030) NMAX,NP
C
 900  CONTINUE
      STOP
 910  WRITE(6,9040)
      STOP
 920  WRITE(6,9050)
      STOP
C
 9000 FORMAT(2I10)
 9010 FORMAT(1X,'List of Primes up to',I8)
 9020 FORMAT(10(1X,I7))
 9030 FORMAT(1X,'pi(',I8,'): ',I8)
 9040 FORMAT(1X,'conversion error, abort')
 9050 FORMAT(1X,'nmax out of range (10...10000000), abort')
C
      END
