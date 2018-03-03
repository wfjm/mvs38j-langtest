*
* OHEX10 ---------------------------------------------------
*   print integer, like C "  %8.8x" format 
*
OHEX10   ST    R14,OHEX10L        save R14
         L     R15,OLPTR          R15 points to edit position
         LA    R15,2(R15)         add two blanks
         LA    R14,8(R15)         end of buffer
*
OHEX10NL XR    R0,R0              R0 := 0
         SLDA  R0,4               get next 4 bits into R0
         AH    R0,=X'00F0'        add '0'
         CH    R0,=X'00F9'        above 9 ?
         BNH   OHEX10OK           if <= no, skip A-F correction
         SH    R0,=X'0039'        sub (0xF0('0')+10)-0xC1('A')=0x39
OHEX10OK STC   R0,0(R15)          store hex digit
         LA    R15,1(R15)         push pointer
         CR    R15,R14            beyond end ?
         BL    OHEX10NL           if < not, do next nibble
*
         ST    R15,OLPTR          store pointer
         L     R14,OHEX10L        restore R14 linkage
         BR    R14
*
OHEX10L  DS    F                  save area for R14 (return linkage)
