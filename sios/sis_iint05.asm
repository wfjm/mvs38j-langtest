*
* IINT05 ---------------------------------------------------
*   read integer, like PL/I F(5) or C %5d format 
*
IINT05   L     R15,ILPTR          get input pointer
         PACK  ICVB(8),0(5,R15)   pack next 5 char
         CVB   R1,ICVB            and convert
         LA    R15,5(R15)         push pointer by 5 char
         ST    R15,ILPTR          and update
         BR    R14
