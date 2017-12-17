*
* IINT10 ---------------------------------------------------
*   read integer, like PL/I F(10) or C %10d format 
*
IINT10   L     R15,ILPTR          get input pointer
         PACK  ICVB(8),0(10,R15)  pack next 10 char
         CVB   R1,ICVB            and convert
         LA    R15,10(R15)        push pointer by 10 char
         ST    R15,ILPTR          and update
         BR    R14
