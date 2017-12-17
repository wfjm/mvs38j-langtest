*        1         2         3         4         5         6         71
*23456789*12345*789012345678901234*678901234567890123456789012345678901
         PRINT NOGEN              don't show macro expansions
HEWO     START 0                  start main code csect at base 0
         SAVE  (14,12)            Save input registers
         LR    R12,R15            base register := entry address
         USING HEWO,R12           declare base register
         ST    R13,SAVE+4         set back pointer in current save area
         LR    R2,R13             remember callers save area
         LA    R13,SAVE           setup current save area
         ST    R13,8(R2)          set forw pointer in callers save area
*
         OPEN  (SYSPRINT,OUTPUT)  open SYSPRINT
         LTR   R15,R15            test return code
         BNE   ABND8              abort if open failed
         PUT   SYSPRINT,MSG       write the message
         CLOSE SYSPRINT           close SYSPRINT
*
         L     R13,SAVE+4         get old save area back
         RETURN (14,12),RC=0      return to OS
*
ABND8    ABEND 8                  bail out with abend U008
*
* File and work area definitions
*
SAVE     DS    18F                local save area
MSG      DC    CL133' Hello World !'
SYSPRINT DCB   DSORG=PS,MACRF=PM,DDNAME=SYSPRINT,                      X
               RECFM=FBA,LRECL=133,BLKSIZE=1330
         YREGS ,
         END   HEWO               define main entry point
