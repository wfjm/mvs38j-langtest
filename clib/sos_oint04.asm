*
* OINT04 ---------------------------------------------------
*   print integer, like PL/I F(4) or C %4d format 
*   very fast, for non-negative numbers only !
*
OINT04   LA    R15,999
         CLR   R1,R15             too large ?
         BH    OINT04F            if > yes, do OSFILL
         CVD   R1,OCVD            convert
         L     R15,OLPTR          R15 points to edit position
         MVC   0(OEI04L,R15),OEI04   setup pattern
         ED    0(OEI04L,R15),OCVD+6  and edit
         LA    R15,OEI04L(R15)       push pointer
         ST    R15,OLPTR          store pointer
         BR    R14
*
OINT04F  LA    R1,4
         B     OSFILL
*
OEI04    DC    C' ',X'20',X'21',X'20'     ED pattern: bd(d
OEI04L   EQU   *-OEI04
