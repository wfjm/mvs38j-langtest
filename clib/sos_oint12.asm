*
* OINT12 ---------------------------------------------------
*   print integer, like PL/I F(12) or C %12d format
*   handles negative numbers too (which OINT04/OINT10 don't)
*
OINT12   CVD   R1,OCVD
         L     R15,OLPTR          R15 points to edit position
         MVC   0(OEI12L,R15),OEI12   setup pattern
         LA    R1,11(R15)            point one behind X'21' position
         EDMK  0(OEI12L,R15),OCVD+2  and edit
         BNM   OINT12P               negative number ? if >= not
         BCTR  R1,0                  decrement pointer
         MVI   0(R1),C'-'            write '-' sign
OINT12P  LA    R15,OEI12L(R15)       push pointer
         ST    R15,OLPTR          store pointer
         BR    R14
*
OEI12    DC    C' ',9X'20',X'21',X'20'             pat: bddddddddd(d
OEI12L   EQU   *-OEI12
