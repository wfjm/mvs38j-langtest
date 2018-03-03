*
* OINT04 ---------------------------------------------------
*   print integer, like PL/I F(2) or C %2d format 
*   very fast, for non-negative numbers only !
*
OINT02   LA    R15,9
         CLR   R1,R15             too large ?
         BH    OINT02F            if > yes, do OSFILL
         LA    R15,X'F0'          get C'0'
         AR    R1,R15             single digit 'convert'
         L     R15,OLPTR          R15 points to edit position
         STC   R1,1(R15)
         LA    R15,2(R15)         push pointer
         ST    R15,OLPTR          store pointer
         BR    R14
*
OINT02F  LA    R1,2
         B     OSFILL
