*
* simple input system procedures --------------------------------------
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
* IGETLINE -------------------------------------------------
*   read line from SYSIN
*   EOF handling:
*   - IEOFOK holds the 'EOF OK' flag
*   - if EOF seen and IEOFOK  = X'00', program ends with RC=8
*   - if EOF seen and IEOFOK != X'00', program ends with RC=0
*
IGETLINE ST    R14,IGETLNEL       save R14
         L     R1,=A(SYSIN)
         L     R0,=A(ILBUF)
         GET   (1),(0)            read line
         L     R0,=A(ILBUF)
         ST    R0,ILPTR           set input ptr to begin of line
         L     R14,IGETLNEL       restore R14 linkage
         BR    R14
*
IGETLNEL DS    F                  save area for R14 (return linkage)
*
* IEOFHDL --------------------------------------------------
*
IEOFHDL  BALR  R12,R0             where are we ?
         LA    R15,*-MAIN         offset from MAIN to here
         SR    R12,R15            base reg now points to MAIN
         L     R15,IEOFEXIT       load user exit address
         LTR   R15,R15            test address
         BNER  R15                if !=, use user exit
         LA    R14,EXIT
         CLI   IEOFOK,X'00'       is EOF ok ?
         BNER  R14                if != yes, jump to EXIT
         MVI   RC+3,X'08'         otherwise set RC=8
         BR    R14                and jump to EXIT
*
* Work area for simple output system ------------------------
*
ILPTR    DC    A(ILBUF)           current input line position
IEOFOK   DS    X'00'              EOF ok flag
IEOFEXIT DS    F'0'               user exit address (if != 0)
ICVB     DS    D                  buffer for CVB (8 byte, DW aligned)
*
* DCB and OLBUF in separate CSECT
*
SIOSDATA CSECT
         DS    0F
SYSIN    DCB   DSORG=PS,MACRF=GM,DDNAME=SYSIN,EODAD=IEOFHDL            X
               RECFM=FB,LRECL=80,BLKSIZE=0
ILBUF    DC    CL80' '            input line buffer
MAIN     CSECT
