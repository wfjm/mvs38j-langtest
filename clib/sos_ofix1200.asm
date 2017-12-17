*
* OFIX1200 -------------------------------------------------
*   print double, like PL/I F(12,0) or C %12.0f format 
*     input value in floating reg FR0 
*     only for non-negatve numbers
*
OFIX1200 LTDR  FR0,FR0            check whether negative 
         BL    OFX1200F           if < yes, do OSFILL
         CD    FR0,=D'99999999999.'  too large ?
         BH    OFX1200F           if > yes, do OSFILL
         AW    FR0,ODNZERO        de-normalize
         STD   FR0,ODTEMP         roll-out to memory
         L     R1,ODTEMP+4
         L     R0,ODTEMP
         N     R0,=X'00FFFFFF'
         D     R0,=F'100000000'   now R0 lower 9, R1 upper digits
         CVD   R0,OCVD            BCD convert lower part
         L     R15,OLPTR          R15 points to edit position
         LA    R15,2(R15)         add two blanks
         LTR   R1,R1              upper != 0
         BNZ   OFX1200B           if != yes, handle large number
*
         MVC   0(OEI10L,R15),OEI10   setup pattern (from OINT10)
         ED    0(OEI10L,R15),OCVD+3  and edit
         LA    R15,OEI10L(R15)       push pointer
         ST    R15,OLPTR          store pointer
         BR    R14
*
OFX1200B EQU   *
         MVC   0(OEF10LL,R15),OEF10L   setup pattern
         ED    0(OEF10LL,R15),OCVD+3  and edit
         CVD   R1,OCVD            BCD convert upper part
         L     R15,OLPTR          R15 points to edit position
         MVC   0(OEF10UL,R15),OEF10U  setup pattern
         ED    0(OEF10UL,R15),OCVD+6  and edit
         LA    R15,12(R15)        push pointer
         ST    R15,OLPTR          store pointer
         BR    R14
*
OFX1200F LA    R1,12
         B     OSFILL
*
OEF10L   DC    C' ',X'21',8X'20'                   pat: b(dddddddd
OEF10LL  EQU   *-OEF10L
OEF10U   DC    C' ',X'20',X'21',X'20'              pat: bd(d
OEF10UL  EQU   *-OEF10U
