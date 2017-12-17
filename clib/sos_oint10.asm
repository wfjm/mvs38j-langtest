*
* OINT10 ---------------------------------------------------
*   print integer, like PL/I F(10) or C %10d format
*   very fast, for non-negative numbers only !
*
OINT10   CL    R1,=F'999999999'   too large ?
         BH    OINT10F            if > yes, do OSFILL
         CVD   R1,OCVD            convert
         L     R15,OLPTR          R15 points to edit position
         MVC   0(OEI10L,R15),OEI10   setup pattern
         ED    0(OEI10L,R15),OCVD+3  and edit
         LA    R15,OEI10L(R15)       push pointer
         ST    R15,OLPTR          store pointer
         BR    R14
*
OINT10F  LA    R1,10
         B     OSFILL
*
OEI10    DC    C' ',7X'20',X'21',X'20'             pat: bddddddd(d
OEI10L   EQU   *-OEI10
