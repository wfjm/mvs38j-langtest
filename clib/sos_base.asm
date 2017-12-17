*
* simple output system procedures -------------------------------------
* calling and register convention:
*    R1       holds value (or descriptor pointer)
*    R0,R1    may be modified
*    R14,R15  may be modified
*    R2-R11   are not changed
*
* in short
*    R1 holds input or output value (or pointer)
*    call with BAL  R14,<routine>
*
* OSKIP02 --------------------------------------------------
*   add 2 blanks
*
OSKIP02  LA    R1,2
*
* OSKIP ----------------------------------------------------
*   add blanks, count in R1
*
OSKIP    A     R1,OLPTR           new edit position
         ST    R1,OLPTR           store pointer
         BR    R14
*
* OTAB  ----------------------------------------------------
*   set output column, position in R1
*
OTAB     A     R1,=A(OLBUF+1)     new edit position
         ST    R1,OLPTR           store pointer
         BR    R14
*
* OSFILL ---------------------------------------------------
*   add " ***" pattern, total length in R1
*
OSFILL   L     R15,OLPTR          R15 points to edit position
         MVI   0(R15),C' '        initial blank
         B     OSFILLN
OSFILLL  MVI   0(R15),C'*'        further '*'
OSFILLN  LA    R15,1(R15)
         BCT   R1,OSFILLL
         ST    R15,OLPTR          store pointer
         BR    R14
*
* OTEXT ----------------------------------------------------
*   print text, R1 hold descriptor address
*   descriptor format
*        DC  AL1(<length of string>)
*        DC  AL2(<address of string>)
*
OTEXT    ST    R14,OTEXTL         save R14
         LR    R14,R1
         SRL   R14,24             R14 now string length
         L     R15,OLPTR          R15 points to edit position
         LR    R0,R15             R0 too
         AR    R0,R14             push pointer, add length
         ST    R0,OLPTR           store pointer
         BCTR  R14,0              decrement length for EX
         EX    R14,OTEXTMVC       copy string via EX:MVC
         L     R14,OTEXTL         restore R14 linkage
         BR    R14
*
OTEXTMVC MVC   0(1,R15),0(R1)     length via EX, dst R15, src R1
OTEXTL   DS    F                  save area for R14 (return linkage)
*
* OPUTLINE -------------------------------------------------
*   write line to SYSPRINT
*
OPUTLINE ST    R14,OPUTLNEL       save R14
         L     R15,=A(OLBUF)
         CLI   133(R15),X'00'     check fence byte
         BNE   OPUTLNEA           crash if fence blown
         L     R1,=A(SYSPRINT)    R1 point to DCB
         LR    R0,R15             R1 point to buffer
         PUT   (1),(0)            write line
         L     R15,=A(OLBUF)      point to CC of OLBUF
         MVI   0(R15),C' '        blank OLBUF(0)
         MVC   1(L'OLBUF-1,R15),0(R15)    propagate blank
         LA    R15,1(R15)         point to 1st print char in OLBUF
         ST    R15,OLPTR          reset current position pointer
         LA    R15,1              
         AH    R15,OLCNT          increment line counter
         STH   R15,OLCNT
         SH    R15,OLMAX          R15 := OLCNT-OLMAX
         BL    OPUTLNES           if < no new page
         XR    R15,R15            R15 := 0
         SH    R15,OLCNT          clear line counter
         L     R15,=A(OLBUF)      point to CC of OLBUF
*        MVI   0(R15),C'1'        set new page CC in OLBUF
OPUTLNES L     R14,OPUTLNEL       restore R14 linkage
         BR    R14
*
OPUTLNEA ABEND 255                abend in case of errors
*
OPUTLNEL DS    F                  save area for R14 (return linkage)
*
* Work area for simple output system ------------------------
*
OLPTR    DC    A(OLBUF+1)         current output line position
OLCNT    DC    H'0'               line counter
OLMAX    DC    H'60'              lines per page
OCVD     DS    D                  buffer for CVD (8 byte, DW aligned)
*
ODTEMP   DS    D                  double buffer for conversions
ODNZERO  DC    X'4E000000',X'00000000'     denormalized double zero
ODNONE   DC    X'4E000000',X'00000001'     denormalized double one
*
* DCB and OLBUF in separate CSECT
*
SIOSDATA CSECT
         DS    0F
SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FBA,LRECL=133,BLKSIZE=0
OLBUF    DC    CL133' ',X'00'     output line buffer and fence byte
*
MAIN     CSECT
