C        1         2         3         4         5         6         712--------
C2345*78901234567890123456789012345678901234567890123456789012345678901234567890
C $Id: sine_for.f 1171 2019-06-28 19:02:57Z mueller $
C SPDX-License-Identifier: GPL-3.0-or-later
C Copyright 2017-2019 by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
C
C  Revision History:
C Date         Rev Version  Comment
C 2017-08-09   934   1.0    Initial version
C 2017-07-30   931   0.1    First draft
C
C --- main program ---------------------------------------------------
C     PROGRAM SINE
      INTEGER PLOT(81)
      INTEGER I,J,ISIN,ICOS
      REAL*4 X,XRAD,FSIN,FCOS
      INTEGER CBL,CPL,CDO,CCO,CST,CHA
      DATA CBL/1H /,CPL/1H+/,CDO/1H./,CCO/1H:/,CST/1H*/,CHA/1H#/
C     
      WRITE(6,9000)
      WRITE(6,9010)
C
C Fortran IV(1966): DO limits must all to be > 0 -- FORTRAN-G enforces this
      DO 100 I=1,61
        X    = 6. * (I-1)
        XRAD = X/57.2957795131
        FSIN = SIN(XRAD)
        FCOS = COS(XRAD)
        DO 200 J=1,81
          PLOT(J) = CBL
 200    CONTINUE
        PLOT( 1) = CPL
        PLOT(21) = CDO
        PLOT(41) = CCO
        PLOT(61) = CDO
        PLOT(81) = CPL
        ISIN = 41.5 + 40. * FSIN
        ICOS = 41.5 + 40. * FCOS
        PLOT(ISIN) = CST
        PLOT(ICOS) = CHA
        WRITE(6,9020) X,FSIN,FCOS,PLOT
 100  CONTINUE
      WRITE(6,9010)
      STOP
C
 9000 FORMAT(1X,'     x   sin(x)   cos(x)   ',
     *         '-1                -0.5                  0',
     *         '                 +0.5                 +1')
 9010 FORMAT(1X,'                           ',
     *         '+-------------------.-------------------:',
     *         '-------------------.-------------------:')
 9020 FORMAT(1X,F6.0,1X,F8.5,1X,F8.5,3X,81A1)
C
      END
