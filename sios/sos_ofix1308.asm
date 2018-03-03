*
* OFIX1308, OFIX1306 - -------------------------------------
*   print double, like
*     OFIX1308: PL/I F(13,8) or C %13.8f format 
*     OFIX1306: PL/I F(13,6) or C %13.6f format 
*     input value in floating reg FR0 
*     handles signed numbers
*
OFIX1308 MD    FR0,=D'1.E8'       'shift' 8 digits left
         LA    R1,OEF1308         pointer to edit pattern
         LA    R0,3               offset to one behind X'21' position
         B     OFIX13XX
*
OFIX1306 MD    FR0,=D'1.E6'       'shift' 6 digits left
         LA    R1,OEF1306         pointer to edit pattern
         LA    R0,5               offset to one behind X'21' position
*
OFIX13XX LPDR  FR2,FR0            get abbs() value
         CD    FR2,=D'2.E9'       too large ?
         BNL   OFX13XXF           if >= yes, do OSFILL
*
         LDR   FR4,FR2
         AW    FR4,ODNZERO        FR4 := de-normalized FR2
         SDR   FR6,FR6            FR6 := 0.
         ADR   FR6,FR4            get integer part 
         SDR   FR2,FR4            get fractional part
         CD    FR2,=D'0.5'        check if >= 0.5
         BL    OFX13XXR           if < no need to round up
         AW    FR4,ODNONE         otherwise add LSB DENORM
OFX13XXR STD   FR4,ODTEMP         roll-out to memory
         L     R15,ODTEMP+4       get integer part
         CVD   R15,OCVD           convert
         L     R15,OLPTR          R15 points to edit position
         MVC   0(OEF13XXL,R15),0(R1)   setup pattern
         LR    R1,R15             setup R1 in case of miss
         AR    R1,R0              to one behind X'21' position
         EDMK  0(OEF13XXL,R15),OCVD+2    and edit (and set R1)
         LTDR  FR0,FR0            negative number ?
         BNM   OFX13XXP           if >= not
         BCTR  R1,0               decrement pointer
         MVI   0(R1),C'-'         write '-' sign
OFX13XXP LA    R15,OEF13XXL(R15)  push pointer
         ST    R15,OLPTR          store pointer
         BR    R14
*
OFX13XXF LA    R1,OEF13XXL
         B     OSFILL
*
OEF1306  DC    C' ',3X'20',X'21',X'20',C'.',6X'20' pat: bddd(d.dddddd
OEF1308  DC    C' ',1X'20',X'21',X'20',C'.',8X'20' pat: bd(d.dddddddd
OEF13XXL EQU   *-OEF1308
        
