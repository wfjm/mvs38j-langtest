*
* OREGDMP --------------------------------------------------
*   dump registers R0-R13 in HEX format on two lines
*     all registers, except R14, are preserved
*     internal usage:
*       R2    ptr to descriptor table
*       R3    ptr to R0 in save area
*       R4    line counter
*       R5    register counter
*
*   Note: requires that OTXTDSC and OHEX10 are loaded
*
OREGDMP  STM   R14,R13,OREGDMPS   save R14,R15,R0-R13
OREGDMPR LA    R2,OREGDMPT        load ptr to dsc table
         LA    R3,OREGDMPS+8      load ptr to R0
         LA    R4,4               load line counter
OREGDMPO L     R1,0(R2)           get next dsc address
         LR    R5,R1
         SRL   R5,24              R5 now register count
         L     R1,0(R1)           load message dsc
         BAL   R14,OTEXT          print prefix
*
OREGDMPI L     R1,0(R3)           get next register value
         BAL   R14,OHEX10         and print in hex
         LA    R3,4(R3)           push reg store ptr
         BCT   R5,OREGDMPI        and loop over regs
         BAL   R14,OPUTLINE       and print line
*
         LA    R2,4(R2)           push dsc ptr
         BCT   R4,OREGDMPO        and loop over lines
*
         LM    R14,R5,OREGDMPS   restore R14,R15,R0-R5 (changed only)
         BR    R14
*
OREGDMPS DS    16F                save area for R14,R15,R0-R13
OREGDMP0 OTXTDSC C'  REGS  0- 3'
OREGDMP4 OTXTDSC C'  REGS  4- 7'
OREGDMP8 OTXTDSC C'  REGS  8-11'
OREGDMPC OTXTDSC C'  REGS 12-13'
OREGDMPT DC    AL1(4),AL3(OREGDMP0)
         DC    AL1(4),AL3(OREGDMP4)
         DC    AL1(4),AL3(OREGDMP8)
         DC    AL1(2),AL3(OREGDMPC)
*
* OREGDMPM -------------------------------------------------
*   print message and dump registers R0-R13 in HEX format on two lines
*   message descriptor is passed in R15 !
*
OREGDMPM STM   R14,R13,OREGDMPS   save R14,R15,R0-R13
         LR    R1,R15
         BAL   R14,OTEXT
         BAL   R14,OPUTLINE       and print line
         B     OREGDMPR
