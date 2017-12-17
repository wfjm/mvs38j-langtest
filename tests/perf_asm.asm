*        1         2         3         4         5         6         71
*23456789*12345*789012345678901234*678901234567890123456789012345678901
* $Id: perf_asm.asm 970 2017-12-16 22:19:05Z mueller $
*
* Copyright 2017- by Walter F.J. Mueller <W.F.J.Mueller@gsi.de>
*
* This program is free software; you may redistribute and/or modify
* it under the terms of the GNU General Public License version 3.
* See Licence.txt in distribition directory for further details.
*
*  Revision History:
* Date         Rev Version  Comment
* 2017-12-16   970   0.9    add /Dxxx and /Exxx params; 8k code support
*                           use 4k buffer for MVCL,CLCL; test renames
*                           add T284-T285,T303,T701,T702,T211,T212,T216
*                           add T116-T117,T191-T192,T156-T158,T161-T162
*                           add T165-T166,T450-T451,T507,T527
* 2017-12-10   969   0.8    add ltype flag in TDSC; new output format
*                           BCTR loop closure; code test D aligned
*                           add REPINS2,REPINS5,REPINSPI,REPINSAL
*                           add T252-T254,T255-T259,T274-T277,T280-T283
*                           add T290-292,T324-T325,T415,T440-T443
*                           add T445-T446,T504-506,T524-526,T295-297
*                           add T620-T621
* 2017-12-03   968   0.71   renames, add T310,321,323,238,239,700
* 2017-12-02   967   0.7    use relocation by default, add /ORIP
*                           add /OPTT, page aligned 16k bufs
* 2017-11-26   966   0.6    add /OTGA /GAUT and T114,T601
* 2017-11-12   961   0.5    Initial version
* 2017-10-15   956   0.1    First draft
*
* Description:
*   Code to determine instruction timing non-priviledged instructions
*
* Usage:
*   perf_asm uses the PARM interface to determine job behaviour. The
*   PARM string is a list of 4 letter options, each starting with a /.
*   Valid options are:
*     /OWTO   enable step by step MVS console messages
*     /ODBG   enable debug trace output for test steps
*     /OTGA   enable debug trace output for /GAUT processing
*     /OPTT   print test table
*     /ORIP   run tests in place (default is relocate)
*     /GAUT   automatic determination of GMUL, aim is 1 sec per test
*     /Gnnn   set GMUL to nnn
*     /GnnK   set GMUL to nn * 1000
*     /Dnnn   enable  test Tnnn
*     /Ennn   disable test Tnnn
*     /Tnnn   select  test Tnnn
*
*   Notes on option usage:
*   1. GMUL default and start value is 1
*   2. if multiple /Gnnn or /GnnK are given the last one is taken
*   3. /GAUT will overwrite any previous /Gnnn, but use prior /Gnnn as
*        start value in the search for GMUL leading to 1 sec test time
*   4. if no /Tnnn option is seen all pre-enabled tests are executed
*   5. several /Tnnn options can be specified, in this case only these
*        tests are run
*   6. /Dnnn allows to disable a pre-enabled test
*   7. /Ennn allows to enable  a pre-disabled test
*
*
* Return codes:
*   RC =  0  ok
*   RC =  4  bad PARMs
*   RC = 16  open SYSPRINT failed
*
* User Abend codes:
*    10   test too large (> CBUFSIZE)
*    50   unexpected branch taken in test
*    60   internal consistency check in test
*   255   SOS buffer overflow
*
* Used CSECTS:
*   MAIN        main program code and local data
*   TEXT        text from otxtdsc
*   SIOSDATA    SOS data
*   TDSCDAT     task descriptor list
*   TDSCTBL     task table
*   TCODE       task code
*   T330CS      code for T330
*   DATA        other data
*
         PRINT NOGEN              don't show macro expansions
*
* local macros --------------------------------------------------------
//** ##rinclude ../clib/otxtdsc.asm
*
* used global symbols
*   type  name      set by    used by   comment
*   GBLA  TDIGCNT   TDSCGEN   REPINS
*   GBLC  TTAG      TSIMBEG   TSIMEND
*
* TDSCGEN - setup test descriptor --------------------------
*
         MACRO
&LABEL   TDSCGEN  &TAG,&LRCNT,&IGCNT,&LTYPE,&TEXT
         GBLA  &TDIGCNT
&TDIGCNT SETA  &IGCNT
*
&LABEL   DC    A(&TAG)                      // TENTRY
         DC    A(&TAG.TEND-&TAG)            // TLENGTH
         DC    F'&LRCNT'                    // TLRCNT
         DC    F'&IGCNT'                    // TIGCNT
         DC    F'&LTYPE'                    // TLTYPE
         OTXTDSC C'&TAG'                    // TTAGDSC
         OTXTDSC &TEXT                      // TTXTDSC
         MEND
*
* TSIMPRE - preamble code for simple test ------------------
*   Note: The preamble code starts at a double word boundary. This
*         ensures that even after relocation the test code has the
*         same alignments, especially that 'D' type allocations
*         will stay on double word boundaries.
*
         MACRO
&LABEL   TSIMPRE &NBASE=1
         DS    0D                 ensure double word alignment for test
&LABEL   SAVE  (14,12)
         AIF   (&NBASE GT 1).NBASE2
         LR    R12,R15            base register := entry address
         USING &LABEL,R12         declare code base register
         LA    R11,&LABEL.L       load loop target to R11
         AGO   .NBASEOK
.NBASE2  ANOP
         LR    R11,R15            base register 1 := entry address
         LA    R12,2048(R11)
         LA    R12,2048(R12)      base register 1 := entry address+4k
         USING &LABEL,R11,R12     declare code base registers
         LA    R10,&LABEL.L       load loop target to R10
.NBASEOK ANOP
         L     R15,=A(SAVETST)    R15 := current save area
         ST    R13,4(R15)         set back pointer in current save area
         LR    R2,R13             remember callers save area
         LR    R13,R15            setup current save area
         ST    R13,8(R2)          set forw pointer in callers save area
         USING TDSC,R1            declare TDSC base register
         L     R15,TLRCNT         load local repeat count to R15
         MEND
*
* TSIMRET - return code for simple test --------------------
*
         MACRO
&LABEL   TSIMRET  
         L     R15,=A(SAVETST)    R15 := current save area
         L     R13,4(R15)         get old save area back
         RETURN (14,12)
         MEND
*
* TSIMBEG - complete startup for simple test ---------------
*
         MACRO
         TSIMBEG &TAG,&LRCNT,&IGCNT,&LTYPE,&TEXT,&NBASE=1,&DIS=0
         GBLC  &TTAG
&TTAG    SETC  '&TAG'
*
TDSCDAT  CSECT
         DS    0D
&TAG.TDSC TDSCGEN  &TAG,&LRCNT,&IGCNT,&LTYPE,&TEXT
*
TDSCTBL  CSECT
         AIF   (&DIS GT 0).TDSCDIS
         DC    A(&TAG.TDSC)             enabled test
         AGO   .TDSCOK
.TDSCDIS ANOP
         DC    X'01',AL3(&TAG.TDSC)     disabled test
.TDSCOK  ANOP
*
TCODE    CSECT
&TAG     TSIMPRE NBASE=&NBASE
*
         MEND
*
* TSIMEND - end for simple test ----------------------------
*
         MACRO
         TSIMEND
         GBLC  &TTAG
         LTORG
&TTAG.TEND EQU  *
         MEND
*
* REPINS - repeat instruction -----------------------------
*
         MACRO
&LABEL   REPINS &CODE,&ALIST,&IGCNT=0
         GBLA  &TDIGCNT
         GBLC  &MACRETC
         LCLA  &ICNT
         LCLC  &ARGS
*
* build from sublist &ALIST a comma separated string &ARGS
*
         REPINSAL &ALIST
&ARGS    SETC  '&MACRETC'
*
* determine repeat count, &IGCNT if given, otherwise &TDIGCNT
* this allows to transfer the repeat count from last TDSCGEN call
*
&ICNT    SETA  &IGCNT
         AIF   (&ICNT GT 0).ICNTOK
&ICNT    SETA  &TDIGCNT
         AIF   (&ICNT GT 0).ICNTOK
         MNOTE 8,'//REPINS: IGCNT and TDIGCNT equal 0; abort'
         MEXIT
.ICNTOK  ANOP
*
         AIF   ('&LABEL' EQ '').NOLBL
&LABEL   EQU   *
.NOLBL   ANOP
*
* write a comment indicating what REPINS does (in case NOGEN in effect)
*
         MNOTE *,'// REPINS: do &ICNT times:'
         REPINSPI  &CODE,&ARGS
*
* finally generate code: &ICNT copies of &CODE &ARGS
*
.ILOOP   &CODE &ARGS
&ICNT    SETA  &ICNT-1
         AIF   (&ICNT GT 0).ILOOP
*
         MEND
*
* REPINS2 - repeat 2 instructions --------------------------
*
         MACRO
&LABEL   REPINS2 &CO1,&AL1,&CO2,&AL2
         GBLA  &TDIGCNT
         GBLC  &MACRETC
         LCLA  &ICNT
         LCLC  &ARGS1,&ARGS2
*
* build from sublist &ALIST* a comma separated string &ARGS*
*
         REPINSAL &AL1
&ARGS1   SETC  '&MACRETC'
         REPINSAL &AL2
&ARGS2   SETC  '&MACRETC'
*
         AIF   ('&LABEL' EQ '').NOLBL
&LABEL   EQU   *
.NOLBL   ANOP
*
&ICNT    SETA  &TDIGCNT
*
* write a comment indicating what REPINS2 does (if NOGEN in effect)
*
         MNOTE *,'// REPINS2: do &ICNT times:'
         REPINSPI  &CO1,&ARGS1
         REPINSPI  &CO2,&ARGS2
*
* finally generate code: &ICNT copies of &CO1 ...
*
.ILOOP   &CO1 &ARGS1
         &CO2 &ARGS2
&ICNT    SETA  &ICNT-1
         AIF   (&ICNT GT 0).ILOOP
*
         MEND
*
* REPINS5 - repeat 5 instructions --------------------------
*
         MACRO
&LABEL   REPINS5 &CO1,&AL1,&CO2,&AL2,&CO3,&AL3,&CO4,&AL4,&CO5,&AL5
         GBLA  &TDIGCNT
         GBLC  &MACRETC
         LCLA  &ICNT
         LCLC  &ARGS1,&ARGS2,&ARGS3,&ARGS4,&ARGS5
*
* build from sublist &ALIST* a comma separated string &ARGS*
*
         REPINSAL &AL1
&ARGS1   SETC  '&MACRETC'
         REPINSAL &AL2
&ARGS2   SETC  '&MACRETC'
         REPINSAL &AL3
&ARGS3   SETC  '&MACRETC'
         REPINSAL &AL4
&ARGS4   SETC  '&MACRETC'
         REPINSAL &AL5
&ARGS5   SETC  '&MACRETC'
*
         AIF   ('&LABEL' EQ '').NOLBL
&LABEL   EQU   *
.NOLBL   ANOP
*
&ICNT    SETA  &TDIGCNT
*
* write a comment indicating what REPINS5 does (if NOGEN in effect)
*
         MNOTE *,'// REPINS5: do &ICNT times:'
         REPINSPI  &CO1,&ARGS1
         REPINSPI  &CO2,&ARGS2
         REPINSPI  &CO3,&ARGS3
         REPINSPI  &CO4,&ARGS4
         REPINSPI  &CO5,&ARGS5
*
* finally generate code: &ICNT copies of &CO1 ...
*
.ILOOP   &CO1 &ARGS1
         &CO2 &ARGS2
         &CO3 &ARGS3
         &CO4 &ARGS4
         &CO5 &ARGS5
&ICNT    SETA  &ICNT-1
         AIF   (&ICNT GT 0).ILOOP
*
         MEND
*
* REPINSAL - build from sublist a comma separated string ---
*
         MACRO
         REPINSAL  &ALIST
         GBLC  &MACRETC
         LCLA  &AIND
*
&AIND    SETA  2
&MACRETC SETC  '&ALIST(1)'
*
.ALOOP   AIF   (&AIND GT N'&ALIST).AEND
&MACRETC   SETC  '&MACRETC'.','.'&ALIST(&AIND)'
&AIND    SETA  &AIND+1
         AGO   .ALOOP
.AEND    ANOP
         MEND
*
* REPINSPI - issue MNOTE with one instruction --------------
*
         MACRO
         REPINSPI  &CODE,&ARGS
         LCLA  &MAIND
         LCLC  &MASTR
*
* MNOTE requires that ' is doubled for expanded variables
* thus build &MASTR as a copy of '&ARGS with ' doubled
*
&MAIND   SETA  1
&MASTR   SETC  ''
*
.MALOOP  ANOP
&MASTR   SETC  '&MASTR'.'&ARGS'(&MAIND,1)
         AIF   ('&ARGS'(&MAIND,1) NE '''').MANEXT
&MASTR   SETC  '&MASTR'.''''
.MANEXT  ANOP
&MAIND   SETA  &MAIND+1
         AIF   (&MAIND LE K'&ARGS).MALOOP
         MNOTE *,'//       &CODE  &MASTR'
         MEND
*
* main preamble -------------------------------------------------------
*
MAIN     START 0                  start main code csect at base 0
         SAVE  (14,12)            Save input registers
         LR    R12,R15            base register := entry address
         USING MAIN,R12           declare base register
         ST    R13,SAVE+4         set back pointer in current save area
         LR    R2,R13             remember callers save area
         LA    R13,SAVE           setup current save area
         ST    R13,8(R2)          set forw pointer in callers save area
*
* general constant definitions-----------------------------------------
*
CBUFSIZE EQU  8192
*
* some preparations --------------------------------------------------
*
         LR    R2,R1              save argument list pointer for later   
         L     R3,=A(TDSCTBLE-4)  pointer to last entry of TDSCTBL
         MVI   0(R3),X'80'        mark last entry of TDSCTBL
*
* open datasets --------------------------------------------
*
         OPEN  (SYSPRINT,OUTPUT)  open SYSPRINT
         LTR   R15,R15            test return code
         BE    OOPENOK
         MVI   RC+3,X'10'
         B     EXIT               quit with RC=16
OOPENOK  EQU   *
*
* allocate buffers -----------------------------------------
*
         GETMAIN RU,LV=CBUFSIZE,BNDRY=PAGE
         ST    R1,PCBUF           code area pointer
         GETMAIN RU,LV=4096,BNDRY=PAGE
         ST    R1,PBUF4K1         1st 4k data buffer pointer
         GETMAIN RU,LV=4096,BNDRY=PAGE
         ST    R1,PBUF4K2         2nd 4k data buffer pointer
*
* main body -----------------------------------------------------------
*
TDSC     DSECT
TENTRY   DS    F                  entry address
TLENGTH  DS    F                  code/data length of test
TLRCNT   DS    F                  local repeat count
TIGCNT   DS    F                  local instruction group count
TLTYPE   DS    F                  loop type
TTAGDSC  DS    F                  tag text descriptor
TTXTDSC  DS    F                  description text descriptor
*
MAIN     CSECT
*
* handle PARMs -------------------------------------------------------
*   R2   PARM address
*   R3   PARM length
*
*
         L     R2,0(R2)           load PARM base address
         LH    R3,0(R2)           load PARM length
         LTR   R3,R3              test length
         BZ    PARMDONE           if =0 no PARM specified
*
         LA    R2,2(R2)           R2 points to 1st PARM char
         N     R2,=X'00FFFFFF'    force upper bit to zero
*
         L     R1,MSGPARM
         BAL   R14,OTEXT          print PARM message prefix
         LR    R1,R3              get length
         SLL   R1,24              put length into bits 0-7
         OR    R1,R2              and address into bits 8-31
         BAL   R14,OTEXT          print PARM as passed
         BAL   R14,OPUTLINE       write line
*
* loop over options ----------------------------------------
*
OLOOP    CLI   0(R2),C'/'         does option start with / ?   
         BNE   PARMABO            if != not
         C     R3,=F'5'           at least 5 chars left ?
         BL    PARMABO            if < not
         BE    OPTLOK             if = exactly 5 char left
         CLI   5(R2),C'/'         does option end with / ?   
         BNE   PARMABO            if != not
*
* handle /Oxxx -------------------------
*
OPTLOK   CLI   1(R2),C'O'         is it /O ?
         BNE   OPTODONE           if != try next
         L     R4,1(R2)           load all 4 option bytes
OPTODBG  C     R4,=C'ODBG'        is it /ODBG ?
         BNE   OPTOWTO
         MVI   FLGODBG,X'01'
         B     OPTDONE
OPTOWTO  C     R4,=C'OWTO'        is it /OWTO ?
         BNE   OPTOTGA
         MVI   FLGOWTO,X'01'
         B     OPTDONE
OPTOTGA  C     R4,=C'OTGA'        is it /OTGA ?
         BNE   OPTOPTT
         MVI   FLGOTGA,X'01'
         B     OPTDONE
OPTOPTT  C     R4,=C'OPTT'        is it /OPTT ?
         BNE   OPTORIP
         MVI   FLGOPTT,X'01'
         B     OPTDONE
OPTORIP  C     R4,=C'ORIP'        is it /ORIP ?
         BNE   PARMABO
         MVI   FLGORIP,X'01'
         B     OPTDONE
*
* handle /Tnnn, /Dnnn, /Ennn -----------
*
OPTODONE LA    R8,1               set disable flag
         CLI   1(R2),C'D'         is it /D ?
         BE    OPTTDISE           if = yes, proceed
         XR    R8,R8              clear disable flag
         CLI   1(R2),C'E'         is it /E ?
         BE    OPTTDISE           if = yes, proceed
*
         CLI   1(R2),C'T'         is it /T ?
         BNE   OPTTDONE           if != try next
         CLI   TDSCDIS,X'00'      TDSC disable already done ?
         BNE   OPTTDISE           if != yes, skip over disable loop
*
         MVI   TDSCDIS,X'01'      set disable done flag
         L     R4,=A(TDSCTBL)     get head of TDSCTBL
OPTTDISL L     R5,0(R4)           get next TDSC
         OI    0(R4),X'01'        set disable flag bit
         LA    R4,4(R4)           push pointer to next TDSC
         LTR   R5,R5              end tag X'80000000' seen ?
         BNL   OPTTDISL           if >= not, keep going
*
OPTTDISE L     R7,1(R2)           load all 4 option bytes
         ICM   R7,B'1000',CHART   force leading byte to 'T'
*
         L     R4,=A(TDSCTBL)     get head of TDSCTBL
OPTTENAL L     R5,0(R4)           get next TDSC
         USING TDSC,R5            declare TDSC base register
         L     R6,TTAGDSC         get tag text descriptor
         C     R7,0(R6)           does Tnnn option match tag ?
         BNE   OPTTENAN           if != not, try next
*
         LTR   R8,R8              test disable flag
         BNE   OPTTDIS            if != yes, do disable
         NI    0(R4),X'FE'        clear disable flag bit
         B     OPTDONE            and consider option handled
OPTTDIS  OI    0(R4),X'01'        set disable flag bit
         B     OPTDONE            and consider option handled
*
         DROP  R5
*
OPTTENAN LA    R4,4(R4)           push pointer to next TDSC
         LTR   R5,R5              end tag X'80000000' seen ?
         BNL   OPTTENAL           if >= not, keep going
         B     PARMABOT           if here no test found, complain
*
* handle /Gxxx -------------------------
*
OPTTDONE CLI   1(R2),C'G'         is it /G ?
         BNE   PARMABO            if != is unknown option
*
         L     R4,1(R2)           load all 4 option bytes
         C     R4,=C'GAUT'        is it /GAUT ?
         BNE   OPTGNNN
         MVI   FLGGAUT,X'01'
         B     OPTDONE
*
OPTGNNN  CLI   4(R2),C'K'         is it /GnnK form ?
         BE    OPTGNNK
         MVC   GMULZONE+3(3),2(R2)   get 3 digit, place 000nnn
         B     OPTGCNV
OPTGNNK  MVC   GMULZONE+1(2),2(R2)   get 2 digit, place 0nn000
*
OPTGCNV  LA    R5,GMULZONE+1      setup digit check, data pointer
         LA    R6,1               increment
         LA    R7,GMULZONE+5      end pointer
OPTGLOOP CLI   0(R5),C'0'         is char >= '0'
         BL    PARMABOD           if < not
         CLI   0(R5),C'9'         is char <= '9'
         BH    PARMABOD           if > not
         BXLE  R5,R6,OPTGLOOP     and loop till end
*
         PACK  GMULPACK(8),GMULZONE   zoned to packed
         CVB   R0,GMULPACK            and packed to binary
         LTR   R0,R0              test result
         BNE   OPTGOK             if =0 complain
         L     R1,MSGPGM0
         B     PARMABO1
OPTGOK   ST    R0,GMUL            store GMUL
         B     OPTDONE
*
* now handle next option ---------------
*
OPTDONE  LA    R2,5(R2)           push to next option
         S     R3,=F'5'           decrement rest length
         BH    OLOOP              if >0 check next option
         B     PARMDONE
*
PARMABOD L     R1,MSGPDIG
         B     PARMABO1
PARMABOT L     R1,MSGPTST
         B     PARMABO1
*
PARMABO  L     R1,MSGPBAD
PARMABO1 BAL   R14,OTEXT          print error message   
         LR    R1,R3              get rest length
         SLL   R1,24              put length into bits 0-7
         OR    R1,R2              and rest address into bits 8-31
         BAL   R14,OTEXT          print rest of PARM
         BAL   R14,OPUTLINE       write line
         MVI   RC+3,X'04'
         B     EXIT               quit with RC=4
PARMDONE EQU   *
*
* print test table if requested with /OPTT
*
         CLI   FLGOPTT,X'00'      /OPTT seen ?
         BE    OPTPTTE            if = not
         L     R1,MSGOPTT
         BAL   R14,OTEXT          print GMUL message prefix
         BAL   R14,OPUTLINE       write line
         L     R2,=A(TDSCTBL)     get head of TDSCTBL
*
OPTPTTL  L     R3,0(R2)           get next TDSC
         USING TDSC,R3            declare TDSC base register
         LR    R1,R2
         S     R1,=A(TDSCTBL)
         SRL   R1,2               R1 now index into TDSCTBL
         BAL   R14,OINT04         print index
         L     R1,MSGTDIS
         TM    0(R2),X'01'        test disable flag
         BO    OPTPTTD            if seen, prefix with " -"
         L     R1,MSGTENA         otherwise with "  "
OPTPTTD  BAL   R14,OTEXT          print enable/disable prefix
         L     R1,TTAGDSC
         BAL   R14,OTEXT          print tag
         L     R1,TLRCNT
         BAL   R14,OINT10         print LRCNT
         L     R1,TIGCNT
         BAL   R14,OINT04         print IGCNT
         L     R1,TLTYPE
         BAL   R14,OINT04         print LTYPE
         L     R1,TENTRY
         BAL   R14,OHEX10         print code address
         L     R1,TLENGTH
         BAL   R14,OINT10         print code length
         BAL   R14,OPUTLINE       write line
*
         DROP  R3
         LA    R2,4(R2)           push pointer to next TDSC
         LTR   R3,R3              end tag X'80000000' seen ?
         BNL   OPTPTTL            if >= not, keep going
*
OPTPTTE  EQU   *
*
* some final preparations --------------------------------------------
*
*   handle /GAUT -----------------------
*
         CLI   FLGGAUT,X'00'      /GAUT active ?
         BE    OPTGAUTE           if = not, skip handling
*
         L     R3,=A(T102TDSC)    get T102 descriptor
OPTGAUTL BAL   R10,DOTEST         run T102 with current GMUL
         LM    R4,R5,TCKBEG       get start time
         SRDL  R4,12              get it in usec
         LM    R6,R7,TCKEND       get end time
         SRDL  R6,12              get it in usec
         SLR   R7,R5              R7 := end-start in usec (LSB)
*        
         CLI   FLGOTGA,X'00'      /OTGA active ?
         BE    NOTRCTGA           if = not, skip printing
         L     R1,MSGTGA
         BAL   R14,OTEXT          print /OTGA message prefix
         L     R1,GMUL
         BAL   R14,OINT10         print GMUL
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ' : '
         LA    R1,TCKBEG
         BAL   R14,OHEX210        print TCKBEG (as hex)
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ' : '
         LA    R1,TCKEND
         BAL   R14,OHEX210        print TCKEND (as hex)
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print ' : '
         LR    R1,R7
         BAL   R14,OINT10         print dt (as int)
         BAL   R14,OPUTLINE       write line
NOTRCTGA EQU   *
*        
         C     R7,=F'200000'      compare with 0.2 sec
         BH    OPTGAUTC
         L     R4,GMUL            load GMUL
         C     R4,=F'30000'       already at limit ?
         BH    OPTGAUTE           if > yes, quit increasing it
         SLL   R4,1               2*GMUL
         A     R4,GMUL            3*GMUL
         ST    R4,GMUL            now GMUL tripled
         B     OPTGAUTL           and re-try with new GMUL
*        
OPTGAUTC EQU   *                  calculate final GMUL
         XR    R4,R4              clear R4
         L     R5,=F'1024000000'  (R4,R5) := 1024 * 1000000
         DR    R4,R7              R5 := (1024*1000000)/dt
         L     R7,GMUL
         MR    R6,R5              R7 := GMUL * (1024*1000000)/dt
         SRL   R7,10              R7 := GMUL * 1000000/dt
         LA    R6,1
         CR    R7,R6              GMUL < 1
         BH    OPTGAUTB           if > not
         LR    R7,R6              limit to 1
OPTGAUTB L     R6,=F'99999'
         CR    R7,R6              GMUL > 99999
         BL    OPTGAUTT
         LR    R7,R6              limit to 99999
OPTGAUTT ST    R7,GMUL
*        
OPTGAUTE EQU   *
*
* print headings -----------------------
*
         L     R1,MSGGMUL
         BAL   R14,OTEXT          print GMUL message prefix
         L     R1,GMUL
         BAL   R14,OINT10         print GMUL
         BAL   R14,OPUTLINE       write line
*
         L     R1,MSGSTRT
         BAL   R14,OTEXT          print 'start tests' message
         BAL   R14,OPUTLINE       write line
*
         L     R1,MSGTHD1
         BAL   R14,OTEXT          print heading part 1
         LA    R1,30
         BAL   R14,OTAB           goto tab stop
         L     R1,MSGTHD2
         BAL   R14,OTEXT          print heading part 1
         BAL   R14,OPUTLINE       write line
*
* finally execute tests ----------------------------------------------
*
* outer loop over tests
*
         L     R2,=A(TDSCTBL)     get head of TDSCTBL
TLOOP    L     R3,0(R2)           get next TDSC
         TM    0(R2),X'01'        test disable flag
         BO    TLOOPN             if seen, skip test
         USING TDSC,R3            declare TDSC base register
*
         CLI   FLGODBG,X'00'      /ODGB active ?
         BE    NOTRCSTP           if = not, skip tracing
         BAL   R14,TRCSTP
NOTRCSTP EQU   *
*
         BAL   R10,DOTEST         execute test with inner GMUL loop
*
* calculate result
*
         LA    R1,TCKBEG
         BAL   R14,CNVCK2D
         STD   FR0,TBEG           TBEG now in 1/16 of usec
*
         LA    R1,TCKEND
         BAL   R14,CNVCK2D
         STD   FR0,TEND           TEND now in 1/16 of usec
*
         LD    FR0,TEND
         SD    FR0,TBEG
         DD    FR0,=D'16.E6'      from 1/16 of usec to sec
         STD   FR0,TDIF           TDIF in sec
*
         L     R1,TLRCNT
         BAL   R14,CNVF2D
         LDR   FR2,FR0            FR2 := float(TLRCNT)
         L     R1,TIGCNT
         BAL   R14,CNVF2D         FR0 := float(TIGCNT)
         MDR   FR2,FR0            FR2 := TLRCNT*TIGCNT
         L     R1,GMUL
         BAL   R14,CNVF2D         FR0 := float(GMUL)
         MDR   FR2,FR0            FR2 := TLRCNT*TIGCNT*GMUL
         LD    FR0,TDIF           FR0 := dt
         DDR   FR0,FR2            FR0 := dt /(TLRCNT*TIGCNT*GMUL)
         MD    FR0,=D'1.E6'       FR0 := 1.e6 *dt/(TLRCNT*TIGCNT*GMUL)
         STD   FR0,TINS           TINS now in usec
*
* print /ODBG trace output
*
         CLI   FLGODBG,X'00'      /ODBG active ?
         BE    NOTRCRES           if = not, skip tracing
         BAL   R14,TRCRES
NOTRCRES EQU   *
*
* print result
*
         L     R1,TTAGDSC
         BAL   R14,OTEXT          print tag
         BAL   R14,OSKIP02        add space
         L     R1,TTXTDSC
         BAL   R14,OTEXT          print description
         LA    R1,30
         BAL   R14,OTAB           goto tab stop
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         LD    FR0,TDIF
         BAL   R14,OFIX1306       print run time
*
         L     R1,TLRCNT
         BAL   R14,OINT10         print LRCNT
         L     R1,TIGCNT
         BAL   R14,OINT04         print IGCNT
         L     R1,TLTYPE
         BAL   R14,OINT04         print LTYPE
*
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         LD    FR0,TINS
         BAL   R14,OFIX1306       print time per test
         BAL   R14,OPUTLINE       write line
*
         CLI   FLGOWTO,X'00'      /OWTO active ?
         BE    NOWTO              if = not, skip oper messages
         L     R1,TTAGDSC         
         MVC   WTOMSG2,0(R1)      insert current tag 
         WTO   MF=(E,WTOPLIST)    and issue operator message
NOWTO    EQU   *
*
         DROP  R3
TLOOPN   LA    R2,4(R2)           push pointer to next TDSC
         LTR   R3,R3              end tag X'80000000' seen ?
         BNL   TLOOP              if >= not, keep going
*
         L     R1,MSGDONE
         BAL   R14,OTEXT          print 'start tests' message
         BAL   R14,OPUTLINE       write line
*
* close datasets and return to OS -------------------------------------
*
EXIT     CLOSE SYSPRINT           close SYSPRINT
         L     R13,SAVE+4         get old save area back
         L     R0,RC              get return code
         ST    R0,16(R13)         store in old save R15
         RETURN (14,12)           return to OS (will setup RC)
*
* data for MAIN program ----------------------------------------------
*
SAVE     DS    18F                save area (for main)
SAVETST  DS    18F                save area (shared by Txxx)
RC       DC    F'0'               return code
*
GMUL     DC    F'1'               general multiplier
*
PCBUF    DS    F                  ptr to code area buffer
PBUF4K1  DS    F                  ptr 1st 4k data buffer
PBUF4K2  DS    F                  ptr 2nd 4k data buffer
*
TCKBEG   DS    D                  STCK value at test begin
TCKEND   DS    D                  STCK value at test end
TBEG     DS    D                  TCKBEG as double in 1/16 usec
TEND     DS    D                  TCKEND as double in 1/16 usec
TDIF     DS    D                  test time in sec
TINS     DS    D                  instruction time in usec
*
GMULPACK DS    D        
GMULZONE DC    C'000000'        
*
FLGODBG  DC    X'00'              /ODBG active     
FLGOWTO  DC    X'00'              /OWTO active  
FLGOTGA  DC    X'00'              /OTGA active  
FLGOPTT  DC    X'00'              /OPTT active  
FLGORIP  DC    X'00'              /ORIP active  
FLGGAUT  DC    X'00'              /GAUT active  
TDSCDIS  DC    X'00'              TDSC disable done after 1st /Tnnn
CHART    DC    C'T'               just letter 'T'
*
         DS    0F
WTOPLIST DC    AL2(4+L'WTOMSG1+L'WTOMSG2)  text length + 4
         DC    B'1000000000000000'         msg flags     
WTOMSG1  DC    C'perf_asm: done '
WTOMSG2  DC    C'Txxx'
         DC    B'0000010000000000'    descriptor codes (6=job status)
         DC    B'0100000000000000'    routing codes (2=console info)
*
         DS    0F
MSGPARM  OTXTDSC  C'PERF001I PARM: '
MSGGMUL  OTXTDSC  C'PERF002I run with GMUL= '
MSGSTRT  OTXTDSC  C'PERF003I start with tests'
MSGDONE  OTXTDSC  C'PERF004I done with tests'
MSGPBAD  OTXTDSC  C'PERF005E bad option: '
MSGPDIG  OTXTDSC  C'PERF006E bad digit: '
MSGPTST  OTXTDSC  C'PERF006E bad test: '
MSGPGM0  OTXTDSC  C'PERF007E GMUL is zero: '
MSGOPTT  OTXTDSC  C' ind   tag        lr  ig  lt      addr    length'
MSGTHD1  OTXTDSC  C' tag  description'
MSGTHD2  OTXTDSC  C' :      test(s)         lr  ig  lt :    inst(usec)'
MSGTENA  OTXTDSC  C'  '
MSGTDIS  OTXTDSC  C' -'
MSGCSEP  OTXTDSC  C' : '
MSGDBG   OTXTDSC  C'--  '
MSGBEG   OTXTDSC  C'--  TCKBEG:'
MSGEND   OTXTDSC  C'--  TCKEND:'
MSGDIF   OTXTDSC  C'--    DIFF:'
MSGINS   OTXTDSC  C'--     INS:'
MSGTGA   OTXTDSC  C'--  GAUT:'
         DS    0H
*
* helper used in 'far call' BAL/BALR tests ---------------------------
*
BR14FAR  BR   R14
*
* helper to execute test inner loop with timing ----------------------
*    R3  holds pointer to TDSC
*    called with BAL  R10,DOTEST        
*
DOTEST   EQU   *
         USING TDSC,R3            declare TDSC base register
         L     R6,PCBUF           copy destination is code buffer
         L     R7,TLENGTH         copy length
         L     R8,TENTRY          copy source is code
         LR    R9,R7              copy length
*
         CL    R7,=A(CBUFSIZE)    does code fit in buffer ?
         BNH   DOTESTOK           if <= ok, doit
         ABEND 10                 otherwise abend
DOTESTOK EQU   *
*
         LR    R5,R6              entry point (default is relocated)
         CLI   FLGORIP,X'00'      /ORIP seen ?
         BE    NOOPTRIP           if = not
         LR    R5,R8              use non-relocated code
NOOPTRIP EQU   *
*
         MVCL  R6,R8              relocate code
         STCK  TCKBEG             get start time
*
         L     R4,GMUL            inner GMUL loop
ILOOP    EQU   *
         LR    R1,R3              load R1 := current TDSC
         LR    R15,R5             load entry point
         BALR  R14,R15            and execute
         BCT   R4,ILOOP
*
         STCK  TCKEND             get end time
         DROP  R3
*
         BR    R10        
*
* convert clock to double --------------------------------------------
*    input: R1 is pointer to STCK value
*   output: FR0 is STCK value as double in 1/16 of usec
*
CNVCK2D  L     R0,0(R1)
         L     R1,4(R1)
         SRDL  R0,8               get space for exponent
         N     R0,=X'00FFFFFF'
         O     R0,=X'4E000000'    now proper double
         STM   R0,R1,CNVTMP
         SDR   FR0,FR0            clear FR0
         AD    FR0,CNVTMP         get a normalized number
         BR    R14
*
CNVTMP   DS    D
*
* convert fullword to double -----------------------------------------
*
CNVF2D   ST    R1,CNVTMP+4
         L     R0,ODNZERO
         ST    R0,CNVTMP
         SDR   FR0,FR0
         AD    FR0,CNVTMP
         BR    R14
*
* trace test startup -------------------------------------------------
*
*
TRCSTP   ST    R14,TRCSTPL
         USING TDSC,R3            declare TDSC base register
*
         L     R1,MSGDBG
         BAL   R14,OTEXT          print debug prefix
         L     R1,TTAGDSC
         BAL   R14,OTEXT          print tag
         BAL   R14,OSKIP02        add space
         L     R1,TTXTDSC
         BAL   R14,OTEXT          print description
         LA    R1,34
         BAL   R14,OTAB           goto tab stop
         L     R1,TENTRY
         BAL   R14,OHEX10         print entry address
         L     R1,TLRCNT
         BAL   R14,OINT10         print LRCNT
         L     R1,TIGCNT
         BAL   R14,OINT04         print IGCNT
         L     R1,TLTYPE
         BAL   R14,OINT04         print LTYPE
         BAL   R14,OPUTLINE       write line
*
         DROP  R3
         L     R14,TRCSTPL
         BR    R14
*
TRCSTPL  DS    1F                 save area for R14 (return linkage)
*
* trace test step results --------------------------------------------
*
TRCRES   ST    R14,TRCRESL
*
         L     R1,MSGBEG
         BAL   R14,OTEXT          print debug prefix
         LA    R1,TCKBEG
         BAL   R14,OHEX210        print start time raw in hex
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         LA    R1,TBEG
         BAL   R14,OHEX210        print start time double in hex
         BAL   R14,OPUTLINE       write line
*
         L     R1,MSGEND
         BAL   R14,OTEXT          print debug prefix
         LA    R1,TCKEND
         BAL   R14,OHEX210        print end time raw in hex
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         LA    R1,TEND
         BAL   R14,OHEX210        print end time double in hex
         BAL   R14,OPUTLINE       write line
*
         L     R1,MSGDIF
         BAL   R14,OTEXT          print debug prefix
         LA    R1,TDIF
         BAL   R14,OHEX210        print test time double in hex
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         LD    FR0,TDIF
         BAL   R14,OFIX1306       print test time
         BAL   R14,OPUTLINE       write line
*
         L     R1,MSGINS
         BAL   R14,OTEXT          print debug prefix
         LA    R1,TINS
         BAL   R14,OHEX210        print instruction time double in hex
         L     R1,MSGCSEP
         BAL   R14,OTEXT          print " : "
         LD    FR0,TINS
         BAL   R14,OFIX1306       print instruction time
         BAL   R14,OPUTLINE       write line
*
         L     R14,TRCRESL
         BR    R14
*
TRCRESL  DS    1F                 save area for R14 (return linkage)
*
* include simple output system ----------------------------------------
//** ##rinclude ../clib/sos_base.asm
//** ##rinclude ../clib/sos_oint10.asm
//** ##rinclude ../clib/sos_oint04.asm
//** ##rinclude ../clib/sos_ohex10.asm
//** ##rinclude ../clib/sos_ohex210.asm
//** ##rinclude ../clib/sos_ofix1308.asm
*
* spill literal pool for MAIN
*
         LTORG
*
* data in DATA CSECT -------------------------------------------------
*
DATA     CSECT
         DS    0D
TRTBLINV EQU   *
         DC    X'FFFEFDFCFBFAF9F8F7F6F5F4F3F2F1F0'
         DC    X'EFEEEDECEBEAE9E8E7E6E5E4E3E2E1E0'
         DC    X'DFDEDDDCDBDAD9D8D7D6D5D4D3D2D1D0'
         DC    X'CFCECDCCCBCAC9C8C7C6C5C4C3C2C1C0'
         DC    X'BFBEBDBCBBBAB9B8B7B6B5B4B3B2B1B0'
         DC    X'AFAEADACABAAA9A8A7A6A5A4A3A2A1A0'
         DC    X'9F9E9D9C9B9A99989796959493929190'
         DC    X'8F8E8D8C8B8A89888786858483828180'
         DC    X'7F7E7D7C7B7A79787776757473727170'
         DC    X'6F6E6D6C6B6A69686766656463626160'
         DC    X'5F5E5D5C5B5A59585756555453525150'
         DC    X'4F4E4D4C4B4A49484746454443424140'
         DC    X'3F3E3D3C3B3A39383736353433323130'
         DC    X'2F2E2D2C2B2A29282726252423222120'
         DC    X'1F1E1D1C1B1A19181716151413121110'
         DC    X'0F0E0D0C0B0A09080706050403020100'
*
* Tests ==============================================================
*   sections   1xx   load/store/move
*              2xx   binary/logical
*              3xx   flow control
*              4xx   packed/decimal
*              5xx   floating point
*              6xx   miscellaneous 
*              7xx   mix sequence 
*
* Test 1xx -- load/store/move ===================================
*
* Test 10x -- load =========================================
*
* Test 100 -- LR R,R ---------------------------------------
*
         TSIMBEG T100,22000,100,1,C'LR R,R'
*
T100L    REPINS LR,(R2,R1)              repeat: LR R2,R1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 101 -- LA R,n ---------------------------------------
*
         TSIMBEG T101,17000,100,1,C'LA R,n'
*
T101L    REPINS LA,(R2,X'123')          repeat: LA R2,X'123
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 102 -- L R,m ----------------------------------------
*
         TSIMBEG T102,13000,50,1,C'L R,m'
*
T102L    REPINS L,(R2,=F'123')          repeat: L R2,=F'123'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 103 -- L R,m (unal) ---------------------------------
*
         TSIMBEG T103,12000,50,1,C'L R,m (unal)'
*
         LA    R3,T103V
T103L    REPINS L,(R2,1(R3))            repeat: L R2,1(R3)
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T103V    DC    X'01234567',X'01234567'   target for unaligned load
         TSIMEND
*
* Test 104 -- LH R,m ---------------------------------------
*
         TSIMBEG T104,10000,50,1,C'LH R,m'
*
T104L    REPINS LH,(R2,=H'123')         repeat: LH R2,=H'123'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 105 -- LH R,m (unal3) -------------------------------
*
         TSIMBEG T105,10000,50,1,C'LH R,m (unal3)'
*
         LA    R3,T105V
T105L    REPINS LH,(R2,3(R3))           repeat: LH R2,3(R3)
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T105V    DC    X'0123',X'0123',X'0123'  across word border
         TSIMEND
*
* Test 106 -- LTR R,R --------------------------------------
*
         TSIMBEG T106,15000,100,1,C'LTR R,R'
*
T106L    REPINS LTR,(R2,R1)             repeat: LTR R2,R1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 107 -- LCR R,R --------------------------------------
*
         TSIMBEG T107,13000,100,1,C'LCR R,R'
*
         LA    R2,=F'1234'
T107L    REPINS LCR,(R2,R2)             repeat: LCR R2,R2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 108 -- LNR R,R --------------------------------------
*
         TSIMBEG T108,13000,100,1,C'LNR R,R'
*
         LA    R1,=F'1234'
T108L    REPINS LNR,(R2,R1)             repeat: LNR R2,R1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 109 -- LPR R,R --------------------------------------
*
         TSIMBEG T109,13000,100,1,C'LPR R,R'
*
         LA    R1,=F'-1234'
T109L    REPINS LPR,(R2,R1)             repeat: LPR R2,R1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 11x -- store ========================================
*
* Test 110 -- ST R,m ---------------------------------------
*
         TSIMBEG T110,13000,50,1,C'ST R,m'
*
T110L    REPINS ST,(R2,T110V)           repeat: ST R2,T110V
         BCTR  R15,R11
         TSIMRET
*
T110V    DS    1F
         TSIMEND
*
* Test 111 -- ST R,m (unal) --------------------------------
*
         TSIMBEG T111,12000,50,1,C'ST R,m (unal)'
*
         LA    R3,T111V
T111L    REPINS ST,(R2,1(R3))           repeat: ST R2,1(R3)
         BCTR  R15,R11
         TSIMRET
*
T111V    DS    2F
         TSIMEND
*
* Test 112 -- STH R,m --------------------------------------
*
         TSIMBEG T112,10000,50,1,C'STH R,m'
*
T112L    REPINS STH,(R2,T112V)          repeat: STH R2,T112V
         BCTR  R15,R11
         TSIMRET
*
T112V    DS    1H
         TSIMEND
*
* Test 113 -- STH R,m (unal1) ------------------------------
*
         TSIMBEG T113,10000,50,1,C'STH R,m (unal1)'
*
         LA    R3,T113V
T113L    REPINS STH,(R2,1(R3))          repeat: STH R2,1(R3)
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T113V    DS    2H                       across halfword border
         TSIMEND
*
* Test 114 -- STH R,m (unal3) ------------------------------
*
         TSIMBEG T114,10000,50,1,C'STH R,m (unal3)'
*
         LA    R3,T114V
T114L    REPINS STH,(R2,3(R3))          repeat: STH R2,3(R3)
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T114V    DS    3H                       across word border
         TSIMEND
*
* Test 115 -- STC R,m --------------------------------------
*
         TSIMBEG T115,11000,50,1,C'STC R,m'
*
T115L    REPINS STC,(R2,T115V)          repeat: STC R2,T115V
         BCTR  R15,R11
         TSIMRET
*
T115V    DS    1H
         TSIMEND
*
* Test 116 -- STCM R,i,m (1c) -------------------------------
*
         TSIMBEG T116,8000,50,1,C'STCM R,i,m (0010)'
*
T116L    REPINS STCM,(R2,B'0010',T116V) repeat: STCM R2,B'0010',T116V
         BCTR  R15,R11
         TSIMRET
*
T116V    DS    1F
         TSIMEND
*
* Test 117 -- STCM R,i,m (2c) -------------------------------
*
         TSIMBEG T117,7000,50,1,C'STCM R,i,m (1100)'
*
T117L    REPINS STCM,(R2,B'1100',T117V) repeat: STCM R2,B'1100',T117V
         BCTR  R15,R11
         TSIMRET
*
T117V    DS    1F
         TSIMEND
*
* Test 118 -- STCM R,i,m (3c) -------------------------------
*
         TSIMBEG T118,10000,50,1,C'STCM R,i,m (0111)'
*
T118L    REPINS STCM,(R2,B'0111',T118V) repeat: STCM R2,B'0111',T118V
         BCTR  R15,R11
         TSIMRET
*
T118V    DS    1F
         TSIMEND
*
* Test 12x -- load/store multiple ==========================
*
* Test 120 -- STM 2,3,m ------------------------------------
*
         TSIMBEG T120,9000,50,1,C'STM 2,3,m (2r)'
*
T120L    REPINS STM,(2,3,T120V)         repeat: STM 2,3,T120V
         BCTR  R15,R11
         TSIMRET
*
T120V    DS    2F
         TSIMEND
*
* Test 121 -- STM 2,7,m ------------------------------------
*
         TSIMBEG T121,6500,50,1,C'STM 2,7,m (6r)'
*
T121L    REPINS STM,(2,7,T121V)         repeat: STM 2,7,T121V
         BCTR  R15,R11
         TSIMRET
*
T121V    DS    6F
         TSIMEND
*
* Test 122 -- STM (14,12),m --------------------------------
*
         TSIMBEG T122,5000,50,1,C'STM 14,12,m (15r)'
*
T122L    REPINS STM,(14,12,T122V)       repeat: STM 14,12,T122V
         BCTR  R15,R11
         TSIMRET
*
T122V    DS    15F
         TSIMEND
*
* Test 123 -- LM 2,3,m -------------------------------------
*
         TSIMBEG T123,9000,50,1,C'LM 2,3,m (2r)'
*
T123L    REPINS LM,(2,3,T123V)          repeat: LM 2,3,T123V
         BCTR  R15,R11
         TSIMRET
*
T123V    DC    F'1',F'2'
         TSIMEND
*
* Test 124 -- LM 2,7,m -------------------------------------
*
         TSIMBEG T124,6000,50,1,C'LM 2,7,m (6r)'
*
T124L    REPINS LM,(2,7,T124V)          repeat: LM 2,7,T124V
         BCTR  R15,R11
         TSIMRET
*
T124V    DC    F'1',F'2',F'3',F'4',F'5',F'6'
         TSIMEND
*
* Test 125 -- LM 0,11,m ------------------------------------
*
         TSIMBEG T125,5000,50,2,C'LM 0,11,m (12r)'
*
T125L    REPINS LM,(0,11,T125V)         repeat: LM 0,11,T125V
         BCT   R15,T125L
         TSIMRET
*
T125V    DC    F'1',F'2',F'3',F'4',F'5',F'6'
         DC    F'7',F'8',F'9',F'10',F'11',F'12'
         TSIMEND
*
* Test 15x -- MVC, MVCIN ===================================
*
* Test 150 -- MVC m,m (10c) --------------------------------
*
         TSIMBEG T150,5000,50,1,C'MVC m,m (10c)'
*
T150L    REPINS MVC,(T150V1,T150V2)     repeat: MVC T150V1,T150V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T150V1   DC    CL10' '
T150V2   DC    CL10'0123456789'
         DS    0H
         TSIMEND
*
* Test 151 -- MVC m,m (100c) -------------------------------
*
         TSIMBEG T151,4000,50,1,C'MVC m,m (100c)'
*
T151L    REPINS MVC,(T151V1,T151V2)     repeat: MVC T151V1,T151V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T151V1   DC    CL100' '
T151V2   DC    CL100'0123456789'
         TSIMEND
*
* Test 152 -- MVC m,m (250c) -------------------------------
*
         TSIMBEG T152,7500,20,1,C'MVC m,m (250c)'
*
T152L    REPINS MVC,(T152V1,T152V2)     repeat: MVC T152V1,T152V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T152V1   DC    CL250' '
T152V2   DC    CL250'0133456789'
         TSIMEND
*
* Test 153 -- MVC m,m (250c,over1) -------------------------
*
         TSIMBEG T153,700,20,1,C'MVC m,m (250c,over1)'
*
T153L    REPINS MVC,(T153V2,T153V1)     repeat: MVC T152V2,T152V1
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T153V1   DC    C' '                     byte to propagate
T153V2   DC    CL250'0133456789'        into this target buffer
         TSIMEND
*
* Test 154 -- MVC m,m (250c,over2) -------------------------
*
         TSIMBEG T154,7500,20,1,C'MVC m,m (250c,over2)'
*
T154L    REPINS MVC,(T154V1(250),T154V2) 
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T154V1   DS    24C                      target
T154V2   DC    CL250'0133456789'        source (1/10th overlap)
         TSIMEND
*
* Test 156 -- MVCIN m,m (10c) ------------------------------
*
         TSIMBEG T156,3500,20,1,C'MVCIN m,m (10c)'
*
T156L    REPINS MVCIN,(T156V1,T156V2)   repeat: MVCIN T156V1,T156V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T156V1   DC    CL10' '
T156V2   DC    CL10'0123456789'
         DS    0H
         TSIMEND
*
* Test 157 -- MVCIN m,m (30c) ------------------------------
*
         TSIMBEG T157,1200,20,1,C'MVCIN m,m (30c)'
*
T157L    REPINS MVCIN,(T157V1,T157V2)   repeat: MVCIN T157V1,T157V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T157V1   DC    CL30' '
T157V2   DC    CL30'01234567899876543210ABCDEFGHIJ'
         TSIMEND
*
* Test 158 -- MVCIN m,m (100c) -----------------------------
*
         TSIMBEG T158,350,20,1,C'MVCIN m,m (100c)'
*
T158L    REPINS MVCIN,(T158V1,T158V2)   repeat: MVCIN T158V1,T158V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T158V1   DC    CL100' '
T158V2   DC    CL100'0123456789'
         TSIMEND
*
* Test 16x -- MVI,MVN,MVZ ==================================
*
* Test 160 -- MVI m,i --------------------------------------
*
         TSIMBEG T160,6000,100,1,C'MVI m,i'
*
T160L    REPINS MVI,(T160V1,C'x')       repeat: MVI T160V1,C'x'
         BCTR  R15,R11
         TSIMRET
*
T160V1   DC    C' '
         TSIMEND
*
* Test 161 -- MVN m,m (10c) --------------------------------
*
         TSIMBEG T161,5000,50,1,C'MVN m,m (10c)'
*
T161L    REPINS MVN,(T161V1,T161V2)   repeat: MVN T161V1,T161V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T161V1   DC    CL10' '
T161V2   DC    CL10'0123456789'
         DS    0H
         TSIMEND
*
* Test 162 -- MVN m,m (30c) --------------------------------
*
         TSIMBEG T162,7000,20,1,C'MVN m,m (30c)'
*
T162L    REPINS MVN,(T162V1,T162V2)   repeat: MVN T162V1,T162V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T162V1   DC    CL30' '
T162V2   DC    CL30'012345678901234567890123456789'
         DS    0H
         TSIMEND
*
* Test 165 -- MVZ m,m (10c) --------------------------------
*
         TSIMBEG T165,5000,50,1,C'MVZ m,m (10c)'
*
T165L    REPINS MVZ,(T165V1,T165V2)   repeat: MVZ T165V1,T165V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T165V1   DC    CL10' '
T165V2   DC    CL10'0123456789'
         DS    0H
         TSIMEND
*
* Test 166 -- MVZ m,m (30c) --------------------------------
*
         TSIMBEG T166,7000,20,1,C'MVZ m,m (30c)'
*
T166L    REPINS MVZ,(T166V1,T166V2)   repeat: MVZ T166V1,T166V2
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T166V1   DC    CL30' '
T166V2   DC    CL30'012345678901234567890123456789'
         DS    0H
         TSIMEND
*
* Test 17x -- MVCL =========================================
*
* Test 170 -- MVCL m,m (10b,copy) --------------------------
*
         TSIMBEG T170,13000,10,1,C'4*LA;MVCL (10b)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LA    R3,10          dest   length
*            LR    R4,R8          source addr
*            LA    R5,10          source length
*            MVCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
T170L    REPINS5 LR,(R2,R6),LA,(R3,10),                                X
               LR,(R4,R8),LA,(R5,10),                                  X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 171 -- MVCL m,m (100b,copy) -------------------------
*
         TSIMBEG T171,11000,10,1,C'4*LA;MVCL (100b)'
*
*          use sequence
*            LR    R2,R6          dest   addr 
*            LA    R3,100         dest   length
*            LR    R4,R8          source addr
*            LA    R5,100         source length
*            MVCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
T171L    REPINS5 LR,(R2,R6),LA,(R3,100),                               X
               LR,(R4,R8),LA,(R5,100),                                 X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 172 -- MVCL m,m (250b,copy) -------------------------
*
         TSIMBEG T172,9000,10,1,C'4*LA;MVCL (250b)'
*
*          use sequence
*            LR    R2,R6          dest   addr 
*            LA    R3,250         dest   length
*            LR    R4,R8          source addr
*            LA    R5,250         source length
*            MVCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
T172L    REPINS5 LR,(R2,R6),LA,(R3,250),                               X
               LR,(R4,R8),LA,(R5,250),                                 X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 173 -- MVCL m,m (1kb,copy) --------------------------
*
         TSIMBEG T173,4500,10,1,C'4*LA;MVCL (1kb)'
*
*          use sequence
*            LR    R2,R6          dest   addr 
*            LA    R3,1024        dest   length
*            LR    R4,R8          source addr
*            LA    R5,1024        source length
*            MVCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
T173L    REPINS5 LR,(R2,R6),LA,(R3,1024),                              X
               LR,(R4,R8),LA,(R5,1024),                                X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 174 -- MVCL m,m (4kb,copy) --------------------------
*
         TSIMBEG T174,1400,10,1,C'4*LR;MVCL (4kb)'
*
*          use sequence
*            LR    R2,R6           dest   addr
*            LR    R3,R7           dest   length
*            LR    R4,R8           source addr
*            LR    R5,R7           source length
*            MVCL  R2,R4           doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
         L     R7,=F'4096'              transfer length
T174L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LR,(R4,R8),LR,(R5,R7),                                  X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 175 -- MVCL m,m (100b,pad) --------------------------
*
         TSIMBEG T175,15000,10,1,C'4*LA;MVCL (100b,pad)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LA    R3,100         dest   length
*            LA    R4,0           source addr == 0 !
*            LR    R5,R9          setup pad byte
*            MVCL  R2,R4    
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R9,=X'FF000000'
T175L    REPINS5 LR,(R2,R6),LA,(R3,100),                               X
               LA,(R4,0),LR,(R5,R9),                                   X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 176 -- MVCL m,m (1kb,pad) ---------------------------
*
         TSIMBEG T176,10000,10,1,C'4*LA;MVCL (1kb,pad)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LA    R3,1024        dest   length
*            LA    R4,0           source addr == 0 !
*            LR    R5,R9          setup pad byte
*            MVCL  R2,R4    
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R9,=X'FF000000'
T176L    REPINS5 LR,(R2,R6),LA,(R3,1024),                              X
               LA,(R4,0),LR,(R5,R9),                                   X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 177 -- MVCL m,m (4kb,pad) ---------------------------
*
         TSIMBEG T177,4500,10,1,C'4*LA;MVCL (4kb,pad)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LR    R3,R7          dest   length
*            LA    R4,0           source addr == 0 !
*            LR    R5,R9          setup pad byte
*            MVCL  R2,R4    
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R7,=F'4096'
         L     R9,=X'FF000000'
T177L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LA,(R4,0),LR,(R5,R9),                                   X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 178 -- MVCL m,m (1kb,over1) -------------------------
*
         TSIMBEG T178,21000,10,1,C'4*LA;MVCL (1kb,over1)'
*
*          use sequence
*            LA    R2,T178V2      dest   addr
*            LA    R3,1024        dest   length
*            LA    R4,T178V1      source addr
*            LA    R5,1024        source length
*            MVCL  R2,R4    
*
T178L    REPINS5 LA,(R2,T178V2),LA,(R3,1024),                          X
               LA,(R4,T178V1),LA,(R5,1024),                            X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
*
T178V1   DC    C'X'                     byte to propagate
T178V2   DS    1024C                    into this target buffer
         TSIMEND
*
* Test 179 -- MVCL m,m (1kb,over2) -------------------------
*
         TSIMBEG T179,4000,10,1,C'4*LA;MVCL (1kb,over2)'
*
*          use sequence
*            LA    R2,T179V1      dest   addr
*            LA    R3,1024        dest   length
*            LA    R4,T179V2      source addr
*            LA    R5,1024        source length
*            MVCL  R2,R4    
*
T179L    REPINS5 LA,(R2,T179V1),LA,(R3,1024),                          X
               LA,(R4,T179V2),LA,(R5,1024),                            X
               MVCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
*
T179V1   DS    100C                     target
T179V2   DS    1024C                    source (1/10th overlap)
         TSIMEND
*
* Test 19x -- IC ===========================================
*
* Test 190 -- IC R,m ---------------------------------------
*
         TSIMBEG T190,6000,100,1,C'IC R,m'
*
         XR    R2,R2
T190L    REPINS IC,(R2,T190V1)          repeat: IC R2,T190V1
         BCTR  R15,R11
         TSIMRET
*
T190V1   DC    C' '
         TSIMEND
*
* Test 191 -- IC R,m (1c) ----------------------------------
*
         TSIMBEG T191,3000,100,1,C'ICM R,i,m (0010)'
*
         XR    R2,R2
T191L    REPINS ICM,(R2,B'0010',T191V1) repeat: ICM R2,B'0010',T191V1
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T191V1   DC    C'2'
         TSIMEND
*
* Test 192 -- IC R,m (2c) ----------------------------------
*
         TSIMBEG T192,3000,100,1,C'ICM R,i,m (1100)'
*
         XR    R2,R2
T192L    REPINS ICM,(R2,B'1100',T192V1) repeat: ICM R2,B'1100',T192V1
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T192V1   DC    C'01'
         TSIMEND
*
* Test 193 -- IC R,m (3c) ----------------------------------
*
         TSIMBEG T193,4000,100,1,C'ICM R,i,m (0111)'
*
         XR    R2,R2
T193L    REPINS ICM,(R2,B'0111',T193V1) repeat: ICM R2,B'0111',T193V1
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T193V1   DC    C'123'
         TSIMEND
*
* Test 2xx -- binary/logical ====================================
*
* Test 20x -- arithmetic/logical add/sub ========================
*
* Test 200 -- AR R,R ---------------------------------------
*
         TSIMBEG T200,14000,100,1,C'AR R,R'
*
         XR    R2,R2
         LA    R3,1
T200L    REPINS AR,(R2,R3)              repeat: AR R2,R3
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 201 -- A R,m ----------------------------------------
*
         TSIMBEG T201,10000,50,1,C'A R,m'
*
         XR    R2,R2
T201L    REPINS A,(R2,=F'1')            repeat: A R2,=F'1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 202 -- AH R,m ---------------------------------------
         TSIMBEG T202,10000,50,1,C'AH R,m'
*
         XR    R2,R2
T202L    REPINS AH,(R2,=H'1')            repeat: AH R2,=H'1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 203 -- ALR R,R --------------------------------------
*
         TSIMBEG T203,17000,100,1,C'ALR R,R'
*
         XR    R2,R2
         LA    R3,1
T203L    REPINS ALR,(R2,R3)             repeat: ALR R2,R3
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 204 -- AL R,m ---------------------------------------
*
         TSIMBEG T204,10000,50,1,C'AL R,m'
*
         XR    R2,R2
T204L    REPINS AL,(R2,=F'1')           repeat: AL R2,=F'1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 21x -- arithmetic mul/div ===========================
*
* Test 210 -- MR R,R ---------------------------------------
*
         TSIMBEG T210,30000,30,1,C'MR R,R'
*
         LA    R4,2
T210L    LA    R3,1
         REPINS MR,(R2,R4)              repeat: MR R2,R4
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 211 -- M R,m ----------------------------------------
*
         TSIMBEG T211,15000,30,1,C'M R,m'
*
T211L    LA    R3,1
         REPINS M,(R2,=F'2')            repeat: M R2,=F'2'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 212 -- MH R,m ---------------------------------------
*
         TSIMBEG T212,15000,30,1,C'MH R,m'
*
T212L    LA    R3,1
         REPINS MH,(R3,=H'2')           repeat: MH R3,=H'2'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 215 -- DR R,R ---------------------------------------
*
         TSIMBEG T215,14000,20,1,C'XR R,R; DR R,R'
*
*          use sequence
*            XR    R2,R2     drop high order part
*            DR    R2,R4     and divide
*
         LA    R4,2
         L     R6,=F'123456789'
T215L    LR    R3,R6                    setup initial divident
         REPINS2 XR,(R2,R2),DR,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 216 -- D R,m ----------------------------------------
*
         TSIMBEG T216,11000,20,1,C'XR R,R; D R,m'
*
*          use sequence
*            XR    R2,R2     drop high order part
*            D     R2,=F'2'  and divide
*
         LA    R4,2
         L     R6,=F'123456789'
T216L    LR    R3,R6                    setup initial divident
         REPINS2 XR,(R2,R2),D,(R2,=F'2')
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 22x -- arithmetic shifts ============================
*
* Test 220 -- SLA R,1 --------------------------------------
*
         TSIMBEG T220,24000,30,1,C'SLA R,1'
*
T220L    LA    R2,1
         REPINS SLA,(R2,1)              repeat: SLA R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 221 -- SLDA R,1 -------------------------------------
*
         TSIMBEG T221,12000,60,1,C'SLDA R,1'
*
T221L    XR    R2,R2
         LA    R3,1
         REPINS SLDA,(R2,1)             repeat: SLDA R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 222 -- SRA R,1 --------------------------------------
*
         TSIMBEG T222,30000,30,1,C'SRA R,1'
*
T222L    LA    R2,1
         REPINS SRA,(R2,1)              repeat: SRA R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 223 -- SRDA R,1 -------------------------------------
*
         TSIMBEG T223,12000,60,1,C'SRDA R,1'
*
T223L    XR    R2,R2
         LA    R3,1
         REPINS SRDA,(R2,1)             repeat: SRDA R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 224 -- SRA R,30 -------------------------------------
*
         TSIMBEG T224,30000,30,1,C'SRA R,30'
*
T224L    LA    R2,1
         REPINS SRA,(R2,30)             repeat: SRA R2,30
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 225 -- SRDA R,60 ------------------------------------
*
         TSIMBEG T225,12000,60,1,C'SRDA R,60'
*
T225L    XR    R2,R2
         LA    R3,1
         REPINS SRDA,(R2,60)            repeat: SRDA R2,60
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 23x -- logical and/or/xor ===========================
*
* Test 230 -- XR R,R ---------------------------------------
*
         TSIMBEG T230,15000,100,1,C'XR R,R'
*
         XR    R2,R2
         LA    R3,1
T230L    REPINS XR,(R2,R3)              repeat: XR R2,R3
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 231 -- X R,m ----------------------------------------
*
         TSIMBEG T231,10000,50,1,C'X R,m'
*
         XR    R2,R2
T231L    REPINS X,(R2,=F'1')            repeat: X R2,=F'1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 232 -- XI R,i ---------------------------------------
*
         TSIMBEG T232,10000,50,1,C'XI R,i'
*
T232L    REPINS XI,(T232V,X'FF')        repeat: XI T232V,X'FF'
         BCTR  R15,R11
         TSIMRET
*
T232V    DC    X'11'
         TSIMEND
*
* Test 235 -- XC m,m (10c) ---------------------------------
*
         TSIMBEG T235,4500,50,1,C'XC m,m (10c)'
*
         LA    R2,T235V1
         LA    R3,T235V2
T235L    REPINS XC,(0(10,R2),0(R3))     repeat: XC 0(10,R2),0(R3)
         BCTR  R15,R11
         TSIMRET
*
T235V1   DC    10X'11'
T235V2   DC    10X'FF'
         TSIMEND
*
* Test 236 -- XC m,m (100c) --------------------------------
*
         TSIMBEG T236,2500,20,1,C'XC m,m (100c)'
*
         LA    R2,T236V1
         LA    R3,T236V2
T236L    REPINS XC,(0(100,R2),0(R3))    repeat: XC 0(100,R2),0(R3)
         BCTR  R15,R11
         TSIMRET
*
T236V1   DC    100X'11'
T236V2   DC    100X'FF'
         TSIMEND
*
* Test 237 -- XC m,m (250c) --------------------------------
*
         TSIMBEG T237,1000,20,1,C'XC m,m (250c)'
*
         LA    R2,T237V1
         LA    R3,T237V2
T237L    REPINS XC,(0(250,R2),0(R3))    repeat: XC 0(250,R2),0(R3)
         BCTR  R15,R11
         TSIMRET
*
T237V1   DC    250X'11'
T237V2   DC    250X'FF'
         TSIMEND
*
* Test 238 -- NR R,R ---------------------------------------
*
         TSIMBEG T238,13000,100,1,C'NR R,R'
*
         XR    R2,R2
         LA    R3,1
T238L    REPINS NR,(R2,R3)              repeat: NR R2,R3
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 239 -- OR R,R ---------------------------------------
*
         TSIMBEG T239,14000,100,1,C'OR R,R'
*
         XR    R2,R2
         LA    R3,1
T239L    REPINS OR,(R2,R3)              repeat: OR R2,R3
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 24x -- logical shifts ===============================
*
* Test 240 -- SLL R,1 --------------------------------------
*
         TSIMBEG T240,35000,30,1,C'SLL R,1'
*
T240L    LA    R2,1
         REPINS SLL,(R2,1)              repeat: SLL R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 241 -- SLDL R,1 -------------------------------------
*
         TSIMBEG T241,13000,60,1,C'SLDL R,1'
*
T241L    XR    R2,R2
         LA    R3,1
         REPINS SLDL,(R2,1)             repeat: SLDL R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 242 -- SRL R,1 --------------------------------------
*
         TSIMBEG T242,35000,30,1,C'SRL R,1'
*
T242L    LA    R2,1
         REPINS SRL,(R2,1)              repeat: SRL R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 243 -- SRDL R,1 -------------------------------------
*
         TSIMBEG T243,13000,60,1,C'SRDL R,1'
*
T243L    XR    R2,R2
         LA    R3,1
         REPINS SRDL,(R2,1)             repeat: SRDL R2,1
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 244 -- SLL R,30 -------------------------------------
*
         TSIMBEG T244,35000,30,1,C'SLL R,30'
*
T244L    LA    R2,1
         REPINS SLL,(R2,30)             repeat: SLL R2,30
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 245 -- SLDL R,60 ------------------------------------
*
         TSIMBEG T245,14000,60,1,C'SLDL R,60'
*
T245L    XR    R2,R2
         LA    R3,1
         REPINS SLDL,(R2,60)            repeat: SLDL R2,60
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 25x -- misc TM,TR,TRT ==================================
*
* Test 250 -- TM m,i ---------------------------------------
*
         TSIMBEG T250,10000,50,1,C'TM m,i'
*
T250L    REPINS TM,(T250V,X'01')        repeat: TM T250V,X'01'
         BCTR  R15,R11
         TSIMRET
*
T250V    DC    X'01'
         TSIMEND
*
* Test 252 -- TR m,m (10c) ---------------------------------
*
         TSIMBEG T252,3500,50,1,C'TR m,m (10c)'
*
         LA    R2,T252V
         L     R3,=A(TRTBLINV)
T252L    REPINS TR,(0(10,R2),0(R3))     repeat: TR 0(10,R2),0(R3)
         BCTR  R15,R11
         TSIMRET
*
T252V    DC    C'QWERTYUIOP'
         TSIMEND
*
* Test 253 -- TR m,m (100c) --------------------------------
*
         TSIMBEG T253,1600,20,1,C'TR m,m (100c)'
*
         LA    R2,T253V
         L     R3,=A(TRTBLINV)
T253L    REPINS TR,(0(100,R2),0(R3))    repeat: TR 0(100,R2),0(R3)
         BCTR  R15,R11
         TSIMRET
*
T253V    DC    C'QWERTYUIOPASDFGHJKLZXCVBN'
         DC    C'NM1234567890-=:<,>.?/!@#$'
         DC    C'%*()_-+=qwertyuiopasdfghj'
         DC    C'klzxcvbnm9876543210!@#$%*'
         TSIMEND
*
* Test 254 -- TR m,m (250c) --------------------------------
*
         TSIMBEG T254,700,20,1,C'TR m,m (250c)'
*
         LA    R2,T254V
         L     R3,=A(TRTBLINV)
T254L    REPINS TR,(0(250,R2),0(R3))    repeat: TR 0(250,R2),0(R3)
         BCTR  R15,R11
         TSIMRET
*
T254V    DC    C'QWERTYUIOPASDFGHJKLZXCVBN'
         DC    C'NM1234567890-=:<,>.?/!@#$'
         DC    C'%*()_-+=qwertyuiopasdfghj'
         DC    C'klzxcvbnm9876543210!@#$%*'
         DC    C'QWERTYUIOPASDFGHJKLZXCVBN'
         DC    C'NM1234567890-=:<,>.?/!@#$'
         DC    C'%*()_-+=qwertyuiopasdfghj'
         DC    C'klzxcvbnm9876543210!@#$%*'
         DC    C'QWERTYUIOPASDFGHJKLZXCVBN'
         DC    C'NM1234567890-=:<,>.?/!@#$'
         TSIMEND
*
* Test 255 -- TRT m,m (10c,zero) ---------------------------
*
         TSIMBEG T255,1200,50,1,C'TRT m,m (10c,zero)'
*
         L     R4,=A(TRTBLINV)
         LA    R5,T255V
T255L    REPINS TRT,(0(10,R4),0(R5))    repeat: TRT 0(10,R4),0(R5)
         BCTR  R15,R11
         TSIMRET
*
T255V    DC    256X'00'
         TSIMEND
*
* Test 256 -- TRT m,m (100c,zero) --------------------------
*
         TSIMBEG T256,300,20,1,C'TRT m,m (100c,zero)'
*
         L     R4,=A(TRTBLINV)
         LA    R5,T256V
T256L    REPINS TRT,(0(100,R4),0(R5))   repeat: TRT 0(100,R4),0(R5)
         BCTR  R15,R11
         TSIMRET
*
T256V    DC    256X'00'
         TSIMEND
*
* Test 257 -- TRT m,m (250c,zero) --------------------------
*
         TSIMBEG T257,130,20,1,C'TRT m,m (250c,zero)'
*
         L     R4,=A(TRTBLINV)
         LA    R5,T257V
T257L    REPINS TRT,(0(250,R4),0(R5))   repeat: TRT 0(250,R4),0(R5)
         BCTR  R15,R11
         TSIMRET
*
T257V    DC    256X'00'
         TSIMEND
*
* Test 258 -- TRT m,m (250c,10b) ---------------------------
*
         TSIMBEG T258,2500,20,1,C'TRT m,m (250c,10b)'
*
         L     R4,=A(TRTBLINV)
         LA    R5,T258V
         MVI   245(R5),X'FF'            mark TRTBLINV[10]=0xf5=245
T258L    REPINS TRT,(0(250,R4),0(R5))   repeat: TRT 0(250,R4),0(R5)
         BCTR  R15,R11
         TSIMRET
*
T258V    DC    256X'00'
         TSIMEND
*
* Test 259 -- TRT m,m (250c,100b) --------------------------
*
         TSIMBEG T259,300,20,1,C'TRT m,m (250c,100b)'
*
         L     R4,=A(TRTBLINV)
         LA    R5,T259V
         MVI   155(R5),X'FF'            mark TRTBLINV[100]=0x9b=155
T259L    REPINS TRT,(0(250,R4),0(R5))   repeat: TRT 0(250,R4),0(R5)
         BCTR  R15,R11
         TSIMRET
*
T259V    DC    256X'00'
         TSIMEND
*
* Test 26x -- compare ===========================================
*
* Test 260 -- CR R,R ---------------------------------------
*
         TSIMBEG T260,17000,100,1,C'CR R,R'
*
         XR    R2,R2
         LA    R3,1
T260L    REPINS CR,(R2,R3)              repeat: CR R2,R3
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 261 -- C R,m ----------------------------------------
*
         TSIMBEG T261,11000,50,1,C'C R,m'
*
         XR    R2,R2
T261L    REPINS C,(R2,=F'1')            repeat: C R2,=F'1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 262 -- CH R,m ---------------------------------------
         TSIMBEG T262,12000,50,1,C'CH R,m'
*
         XR    R2,R2
T262L    REPINS CH,(R2,=H'1')            repeat: CH R2,=H'1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 263 -- CLR R,R --------------------------------------
*
         TSIMBEG T263,18000,100,1,C'CLR R,R'
*
         XR    R2,R2
         LA    R3,1
T263L    REPINS CLR,(R2,R3)             repeat: CLR R2,R3
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 264 -- CL R,m ---------------------------------------
*
         TSIMBEG T264,12000,50,1,C'CL R,m'
*
         XR    R2,R2
T264L    REPINS CL,(R2,=F'1')           repeat: CL R2,=F'1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 265 -- CLI m,i --------------------------------------
*
         TSIMBEG T265,10000,50,1,C'CLI m,i'
*
T265L    REPINS CLI,(T265V,X'00')      repeat: CLI T265V,X'00'
         BCTR  R15,R11
         TSIMRET
*
T265V    DC    X'01'
         TSIMEND
*
* Test 266 -- CLM R,i,m ------------------------------------
*
         TSIMBEG T266,8000,50,1,C'CLM R,i,m'
*
         L     R2,T266V
T266L    REPINS CLM,(R2,X'7',T266V)     repeat: CLM R2,X'7',T266V
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T266V    DC    X'010203FF'
         TSIMEND
*
* Test 27x -- CLC ===============================================
*
* Test 270 -- CLC m,m (10c,eq)-----------------------------------
*
         TSIMBEG T270,7000,20,1,C'CLC m,m (10c,eq)'
*
T270L    REPINS CLC,(T270V1,T270V1)     repeat: CLC T270V1,T270V1
         BCTR  R15,R11
         TSIMRET
*
T270V1   DC    C'1234567890'
         TSIMEND
*
* Test 271 -- CLC m,m (10c,ne)-----------------------------------
*
         TSIMBEG T271,8000,20,1,C'CLC m,m (10c,ne)'
*
T271L    REPINS CLC,(T271V1,T271V2)     repeat: CLC T271V1,T271V2
         BCTR  R15,R11
         TSIMRET
*
T271V1   DC    C'1234567890'
T271V2   DC    C'2345678901'
         TSIMEND
*
* Test 272 -- CLC m,m (30c,eq)-----------------------------------
*
         TSIMBEG T272,5000,20,1,C'CLC m,m (30c,eq)'
*
T272L    REPINS CLC,(T272V1,T272V1)     repeat: CLC T272V1,T272V1
         BCTR  R15,R11
         TSIMRET
*
T272V1   DC    C'123456789012345678901234567890'
         TSIMEND
*
* Test 273 -- CLC m,m (30c,ne)-----------------------------------
*
         TSIMBEG T273,8000,20,1,C'CLC m,m (30c,ne)'
*
T273L    REPINS CLC,(T273V1,T273V2)     repeat: CLC T273V1,T273V2
         BCTR  R15,R11
         TSIMRET
*
T273V1   DC    C'123456789012345678901234567890'
T273V2   DC    C'234567890123456789012345678901'
         TSIMEND
*
* Test 274 -- CLC m,m (100c,eq)----------------------------------
*
         TSIMBEG T274,2900,20,1,C'CLC m,m (100c,eq)'
*
T274L    REPINS CLC,(T274V1(100),T274V2) repeat: CLC T274V1(100),T274V2
         BCTR  R15,R11
         TSIMRET
*
T274V1   DC    100C'X'
T274V2   DC    100C'X'
         TSIMEND
*
* Test 275 -- CLC m,m (100c,ne)----------------------------------
*
         TSIMBEG T275,8000,20,1,C'CLC m,m (100c,ne)'
*
T275L    REPINS CLC,(T275V1(100),T275V2) repeat: CLC T275V1(100),T275V2
         BCTR  R15,R11
         TSIMRET
*
T275V1   DC    100C'X'
T275V2   DC    100C'Y'
         TSIMEND
*
* Test 276 -- CLC m,m (250c,eq)----------------------------------
*
         TSIMBEG T276,1500,20,1,C'CLC m,m (250c,eq)'
*
T276L    REPINS CLC,(T276V1(250),T276V2) repeat: CLC T276V1(250),T276V2
         BCTR  R15,R11
         TSIMRET
*
T276V1   DC    250C'X'
T276V2   DC    250C'X'
         TSIMEND
*
* Test 277 -- CLC m,m (250c,ne)----------------------------------
*
         TSIMBEG T277,8000,20,1,C'CLC m,m (250c,ne)'
*
T277L    REPINS CLC,(T277V1(250),T277V2) repeat: CLC T277V1(250),T277V2
         BCTR  R15,R11
         TSIMRET
*
T277V1   DC    250C'X'
T277V2   DC    250C'Y'
         TSIMEND
*
* Test 28x -- CLCL ==============================================
*
* Test 280 -- CLCL m,m (100b,10b) -------------------------------
*
         TSIMBEG T280,4500,10,1,C'4*LA;CLCL (100b,10b)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LR    R3,R7          dest   length
*            LR    R4,R8          source addr
*            LR    R5,R7          source length
*            CLCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
         L     R7,=F'100'               transfer length
*
         LR    R2,R6              dst    = BUF4K1
         LR    R3,R7              length = 100
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K1 (dst)
         LR    R2,R8              dst    = BUF4K2
         LR    R3,R7              length = 100
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K2 (src)
         LR    R2,R6
         MVI   10(R6),X'FF'       and set src[10] to 0xff
*
T280L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LR,(R4,R8),LR,(R5,R7),                                  X
               CLCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 281 -- CLCL m,m (4kb,10b) --------------------------------
*
         TSIMBEG T281,4500,10,1,C'4*LA;CLCL (4kb,10b)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LR    R3,R7          dest   length
*            LR    R4,R8          source addr
*            LR    R5,R7          source length
*            CLCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
         L     R7,=F'4096'              transfer length
*
         LR    R2,R6              dst    = BUF4K1
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K1 (dst)
         LR    R2,R8              dst    = BUF4K2
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K2 (src)
         LR    R2,R6
         MVI   10(R6),X'FF'       and set src[10] to 0xff
*
T281L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LR,(R4,R8),LR,(R5,R7),                                  X
               CLCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 282 -- CLCL m,m (4kb,100b) -------------------------------
*
         TSIMBEG T282,600,10,1,C'4*LA;CLCL (4kb,100b)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LR    R3,R7          dest   length
*            LR    R4,R8          source addr
*            LR    R5,R7          source length
*            CLCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
         L     R7,=F'4096'              transfer length
*
         LR    R2,R6              dst    = BUF4K1
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K1 (dst)
         LR    R2,R8              dst    = BUF4K2
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K2 (src)
         LR    R2,R6
         MVI   100(R6),X'FF'       and set src[100] to 0xff
*
T282L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LR,(R4,R8),LR,(R5,R7),                                  X
               CLCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 283 -- CLCL m,m (4kb,250b) -------------------------------
*
         TSIMBEG T283,220,10,1,C'4*LA;CLCL (4kb,250b)'
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LR    R3,R7          dest   length
*            LR    R4,R8          source addr
*            LR    R5,R7          source length
*            CLCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
         L     R7,=F'4096'              transfer length
*
         LR    R2,R6              dst    = BUF4K1
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K1 (dst)
         LR    R2,R8              dst    = BUF4K2
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K2 (src)
         LR    R2,R6
         MVI   250(R6),X'FF'       and set src[250] to 0xff
*
T283L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LR,(R4,R8),LR,(R5,R7),                                  X
               CLCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 284 -- CLCL m,m (4kb,1kb) --------------------------------
*
         TSIMBEG T284,80,10,1,C'4*LA;CLCL (4kb,1kb)',DIS=1
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LR    R3,R7          dest   length
*            LR    R4,R8          source addr
*            LR    R5,R7          source length
*            CLCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
         L     R7,=F'4096'              transfer length
*
         LR    R2,R6              dst    = BUF4K1
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K1 (dst)
         LR    R2,R8              dst    = BUF4K2
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K2 (src)
         LR    R2,R6
         MVI   1024(R6),X'FF'     and set src[1024] to 0xff
*
T284L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LR,(R4,R8),LR,(R5,R7),                                  X
               CLCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 285 -- CLCL m,m (4kb,16kb) -------------------------------
*
         TSIMBEG T285,5,10,1,C'4*LA;CLCL (4kb,4kb)',DIS=1
*
*          use sequence
*            LR    R2,R6          dest   addr
*            LR    R3,R7          dest   length
*            LR    R4,R8          source addr
*            LR    R5,R7          source length
*            CLCL  R2,R4          doit
*
         L     R6,=A(PBUF4K1)           get ptr to ptr
         L     R6,0(R6)                 get ptr to BUF4K1
         L     R8,=A(PBUF4K2)           get ptr to ptr
         L     R8,0(R8)                 get ptr to BUF4K2
         L     R7,=F'4096'              transfer length
*
         LR    R2,R6              dst    = BUF4K1
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K1 (dst)
         LR    R2,R8              dst    = BUF4K2
         LR    R3,R7              length = 4k
         LA    R4,0               setup zero fill
         LA    R5,0
         MVCL  R2,R4              clear BUF4K2 (src)
         LR    R2,R6
*                                 leave dst zero'ed !!
*
T285L    REPINS5 LR,(R2,R6),LR,(R3,R7),                                X
               LR,(R4,R8),LR,(R5,R7),                                  X
               CLCL,(R2,R4)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 29x -- CS,CDS ============================================
*
* Test 290 -- CS R,R,m (eq,eq) -----------------------------
*
         TSIMBEG T290,6000,20,1,C'LR;CS R,R,m (eq,eq)' 
*
*          CS  OP1,OP3,OP2 - if OP1==OP2 then OP2:=OP3
*                            if OP1!=OP2 then OP1:=OP2
*
         LA    R2,1               init OP1
         ST    R2,T290V           init OP2, OP2==OP1
         LA    R4,1               init OP3, OP3==OP1
         LA    R6,1               restore OP1
T290L    REPINS2 LR,(R2,R6),CS,(R2,R4,T290V)
         BCTR  R15,R11
         TSIMRET
*
T290V    DC    F'-1'              will be set
         TSIMEND
*
* Test 291 -- CS R,R,m (eq,ne) -----------------------------
*
         TSIMBEG T291,6000,20,1,C'LR;CS R,R,m (eq,ne)'
*
         LA    R2,0               init OP1
         ST    R2,T291V           init OP2, OP2==OP1
         LR    R4,R15             init OP3 (counter)
T291L    REPINS2 CS,(R2,R4,T291V),LR,(R2,R4)
         BCTR  R4,R11             counter is R4 here !!
         TSIMRET
*
T291V    DC    F'-1'              will be setup
         TSIMEND
*
* Test 292 -- CS R,R,m (ne) --------------------------------
*
         TSIMBEG T292,1400,20,1,C'LR;CS R,R,m (ne)'
*
         LA    R2,100             init OP1, OP1!=OP2
         LA    R4,1               init OP3
         LA    R6,100             restore OP1
T292L    REPINS2 LR,(R2,R6),CS,(R2,R4,T292V)
         BCTR  R15,R11
         TSIMRET
*
T292V    DC    F'1'               init OP2
         TSIMEND
*
* Test 295 -- CDS R,R,m (eq,eq) -----------------------------
*
         TSIMBEG T295,6000,20,1,C'LR;CDS R,R,m (eq,eq)'
*
*          CDS  OP1,OP3,OP2 - if OP1==OP2 then OP2:=OP3
*                             if OP1!=OP2 then OP1:=OP2
*
         LA    R2,11             init OP1
         LA    R3,22               upper part
         ST    R2,T295V          init OP2, OP2==OP1
         ST    R3,T295V+4          upper part
         LA    R4,11             init OP3
         LA    R5,22               upper part
         LA    R6,11             restore OP1
T295L    REPINS2 LR,(R2,R6),CDS,(R2,R4,T295V)
         BCTR  R15,R11
         TSIMRET
*
         DS    0D
T295V    DC    F'-1',F'-2'       will be set
         TSIMEND
*
* Test 296 -- CDS R,R,m (eq,ne) ----------------------------
*
         TSIMBEG T296,6000,20,1,C'LR;CDS R,R,m (eq,ne)'
*
         LA    R2,0               init OP1
         LA    R3,1                 upper part
         ST    R2,T296V           init OP2
         ST    R3,T296V+4           upper part
         LR    R4,R15             init OP3 (counter)
         LR    R5,R3                upper part
T296L    REPINS2 CDS,(R2,R4,T296V),LR,(R2,R4)
         BCTR  R4,R11             counter is R4 here !!
         TSIMRET
*
         DS    0D
T296V    DC    F'-1',F'-2'         will be setup
         TSIMEND
*
* Test 297 -- CDS R,R,m (ne) -------------------------------
*
         TSIMBEG T297,1400,20,1,C'LR;CDS R,R,m (ne)'
*
         LA    R2,110             init OP1, OP1!=OP2
         LA    R3,220               upper part
         LA    R4,11              init OP3
         LA    R5,22                upper part
         LA    R6,110             restore OP1
T297L    REPINS2 LR,(R2,R6),CDS,(R2,R4,T297V)
         BCTR  R15,R11
         TSIMRET
*
         DS    0D
T297V    DC    F'11',F'22'        init OP2
         TSIMEND
*
* Test 3xx -- flow control ======================================
*
* Test 300 -- BCR 0,0 --------------------------------------
*
         TSIMBEG T300,20000,100,1,C'BCR 0,0 (noop)'
*
T300L    REPINS BCR,(0,0)               repeat: BCR 0,0
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 301 -- BNZ l (no br) --------------------------------
*
         TSIMBEG T301,22000,100,1,C'BNZ l (no br)'
*
         XR    R0,R0                    clear, ensure Z cond set
T301L    REPINS BNZ,(T301BAD)           repeat: BNZ T301BAD
         BCTR  R15,R11
         TSIMRET
*
T301BAD  ABEND 50
         TSIMEND
*
* Test 302 -- BNZ l (do br) --------------------------------
*
         TSIMBEG T302,12000,60,1,C'BNZ l (do br)'
*
         XR    R0,R0                    clear, ensure Z cond set
         A     R0,=F'1'                 inc, ensure Z cond not set
T302L    EQU   *
         BNZ   T302D01                  1st branch
T302U01  BNZ   T302D02                  3rd branch
T302U02  BNZ   T302D03                  5th branch
T302U03  BNZ   T302D04
T302U04  BNZ   T302D05
T302U05  BNZ   T302D06
T302U06  BNZ   T302D07
T302U07  BNZ   T302D08
T302U08  BNZ   T302D09
T302U09  BNZ   T302D10
T302U10  BNZ   T302D11
T302U11  BNZ   T302D12
T302U12  BNZ   T302D13
T302U13  BNZ   T302D14
T302U14  BNZ   T302D15
T302U15  BNZ   T302D16
T302U16  BNZ   T302D17
T302U17  BNZ   T302D18
T302U18  BNZ   T302D19
T302U19  BNZ   T302D20
T302U20  BNZ   T302D21
T302U21  BNZ   T302D22
T302U22  BNZ   T302D23
T302U23  BNZ   T302D24
T302U24  BNZ   T302D25
T302U25  BNZ   T302D26
T302U26  BNZ   T302D27
T302U27  BNZ   T302D28
T302U28  BNZ   T302D29                  57th branch
T302U29  BNZ   T302D30                  59th branch
         ABEND 50
*
T302D01  BNZ   T302U01                  2nd branch
T302D02  BNZ   T302U02                  4th branch
T302D03  BNZ   T302U03
T302D04  BNZ   T302U04
T302D05  BNZ   T302U05
T302D06  BNZ   T302U06
T302D07  BNZ   T302U07
T302D08  BNZ   T302U08
T302D09  BNZ   T302U09
T302D10  BNZ   T302U10
T302D11  BNZ   T302U11
T302D12  BNZ   T302U12
T302D13  BNZ   T302U13
T302D14  BNZ   T302U14
T302D15  BNZ   T302U15
T302D16  BNZ   T302U16
T302D17  BNZ   T302U17
T302D18  BNZ   T302U18
T302D19  BNZ   T302U19
T302D20  BNZ   T302U20
T302D21  BNZ   T302U21
T302D22  BNZ   T302U22
T302D23  BNZ   T302U23
T302D24  BNZ   T302U24
T302D25  BNZ   T302U25
T302D26  BNZ   T302U26
T302D27  BNZ   T302U27
T302D28  BNZ   T302U28
T302D29  BNZ   T302U29
T302D30  BNZ   T302END                  60th branch
         ABEND 50
*
T302END  BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 303 -- BNZ l (do br) --------------------------------
*
         TSIMBEG T303,6000,60,1,C'BNZ l (do br, far)',NBASE=2
*
         XR    R0,R0                    clear, ensure Z cond set
         A     R0,=F'1'                 inc, ensure Z cond not set
T303L    EQU   *
         BNZ   T303D01                  1st branch
T303U01  BNZ   T303D02                  3rd branch
T303U02  BNZ   T303D03                  5th branch
T303U03  BNZ   T303D04
T303U04  BNZ   T303D05
T303U05  BNZ   T303D06
T303U06  BNZ   T303D07
T303U07  BNZ   T303D08
T303U08  BNZ   T303D09
T303U09  BNZ   T303D10
T303U10  BNZ   T303D11
T303U11  BNZ   T303D12
T303U12  BNZ   T303D13
T303U13  BNZ   T303D14
T303U14  BNZ   T303D15
T303U15  BNZ   T303D16
T303U16  BNZ   T303D17
T303U17  BNZ   T303D18
T303U18  BNZ   T303D19
T303U19  BNZ   T303D20
T303U20  BNZ   T303D21
T303U21  BNZ   T303D22
T303U22  BNZ   T303D23
T303U23  BNZ   T303D24
T303U24  BNZ   T303D25
T303U25  BNZ   T303D26
T303U26  BNZ   T303D27
T303U27  BNZ   T303D28
T303U28  BNZ   T303D29                  57th branch
T303U29  BNZ   T303D30                  59th branch
         ABEND 50
*
         DS    2048H                    force next page
*
T303D01  BNZ   T303U01                  2nd branch
T303D02  BNZ   T303U02                  4th branch
T303D03  BNZ   T303U03
T303D04  BNZ   T303U04
T303D05  BNZ   T303U05
T303D06  BNZ   T303U06
T303D07  BNZ   T303U07
T303D08  BNZ   T303U08
T303D09  BNZ   T303U09
T303D10  BNZ   T303U10
T303D11  BNZ   T303U11
T303D12  BNZ   T303U12
T303D13  BNZ   T303U13
T303D14  BNZ   T303U14
T303D15  BNZ   T303U15
T303D16  BNZ   T303U16
T303D17  BNZ   T303U17
T303D18  BNZ   T303U18
T303D19  BNZ   T303U19
T303D20  BNZ   T303U20
T303D21  BNZ   T303U21
T303D22  BNZ   T303U22
T303D23  BNZ   T303U23
T303D24  BNZ   T303U24
T303D25  BNZ   T303U25
T303D26  BNZ   T303U26
T303D27  BNZ   T303U27
T303D28  BNZ   T303U28
T303D29  BNZ   T303U29
T303D30  BNZ   T303END                  60th branch
         ABEND 50
*
T303END  BCTR  R15,R10                  R10 is loop target !!
         TSIMRET
         TSIMEND
*
* Test 310 -- BCTR R,0 -------------------------------------
*
         TSIMBEG T310,15000,100,1,C'BCTR R,0'
*
         L     R2,=F'1000000000'  init counter
T310L    REPINS BCTR,(R2,0)             repeat: BCTR R2,0
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 311 -- BCTR R,R -------------------------------------
*
         TSIMBEG T311,700000,1,0,C'BCTR R,R'
*
T311L    EQU   *                  no test body, just test BCTR
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 312 -- BCT R,l --------------------------------------
*
         TSIMBEG T312,600000,1,0,C'BCT R,l'
*
T312L    EQU   *                  no test body, just test BCT
         BCT   R15,T312L
         TSIMRET
         TSIMEND
*
* Test 315 -- BXLE R,R,l -----------------------------------
*
         TSIMBEG T315,6000,100,1,C'BXLE R,R,l'
*
T315L    LA    R3,0               index begin
         LA    R4,1               index increment
         LA    R5,99              index end
T315LL   EQU   *                  no inner loop body     
         BXLE  R3,R4,T315LL       will be executed 100 times
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 320 -- BALR R,R; BR R -------------------------------
*
         TSIMBEG T320,8000,50,1,C'BALR R,R; BR R'
*
         LA    R2,T320R                 load target address
T320L    REPINS BALR,(R14,R2)           repeat: BALR R14,R2
         BCTR  R15,R11
         TSIMRET
*
         DS    0H
T320R    BR    R14
         TSIMEND
*
* Test 321 -- BALR R,R; BR R (far) -------------------------------
*
         TSIMBEG T321,2500,50,1,C'BALR R,R; BR R (far)'
*
         L     R2,=A(BR14FAR)           load target address
T321L    REPINS BALR,(R14,R2)           repeat: BALR R14,R2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 322 -- BAL R,l; BR R --------------------------------
*
         TSIMBEG T322,7000,50,1,C'BAL R,l; BR R'
*
T322L    REPINS BAL,(R14,T322R)         repeat: BAL R14,T322R
         BCTR  R15,R11
         TSIMRET
*
         DS    0H
T322R    BR    R14
         TSIMEND
*
* Test 323 -- BAL R,l; BR R (far) --------------------------
*
         TSIMBEG T323,3500,50,1,C'BAL R,l; BR R (far)'
*
         L     R2,=A(BR14FAR)           load target address
T323L    REPINS BAL,(R14,0(R2))         repeat: BAL R14,0(R2)
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 324 -- BASR R,R; BR R -------------------------------
*
         TSIMBEG T324,8000,50,1,C'BASR R,R; BR R'
*
         LA    R2,T324R                 load target address
T324L    REPINS BASR,(R14,R2)           repeat: BASR R14,R2
         BCTR  R15,R11
         TSIMRET
*
         DS    0H
T324R    BR    R14
         TSIMEND
*
* Test 325 -- BAS R,l; BR R --------------------------------
*
         TSIMBEG T325,7000,50,1,C'BAS R,l; BR R'
*
T325L    REPINS BAS,(R14,T325R)         repeat: BAS R14,T325R
         BCTR  R15,R11
         TSIMRET
*
         DS    0H
T325R    BR    R14
         TSIMEND
*
* Test 330 -- L;BALR;SAV;RET --------------------------------
*
         TSIMBEG T330,4500,10,1,C'L;BALR;SAV(14,12);RET'
*
*          use sequence
*            L     R15,=A(T330R)    load target addres
*            BALR  R14,R15          and call it
*
         LR    R10,R15                   use R10 as repeat count
T330L    REPINS2 L,(R15,=A(T330R)),BALR,(R14,R15)
         BCTR  R10,R11
         TSIMRET
         TSIMEND
*
T330CS   CSECT                    call target in separate CSECT
T330R    SAVE  (14,12)            Save input registers
         LR    R12,R15            base register := entry address
         USING T330R,R12          declare base register
         ST    R13,T330SAV+4      set back pointer in current save area
         LR    R2,R13             remember callers save area
         LA    R13,T330SAV        setup current save area
         ST    R13,8(R2)          set forw pointer in callers save area
*                                 <-- empty body of procedure
         L     R13,T330SAV+4      get old save area back
         RETURN (14,12)           return to OS (will setup RC)     
         DROP  R12
*
T330SAV  DS    18F                save area (for T330R)
*
* Test 4xx -- packed/decimal ====================================
*
* Test 40x -- convert/pack/unpack ==========================
*
* Test 400 -- CVB R,m --------------------------------------
*
         TSIMBEG T400,2500,50,1,C'CVB R,m'
*
T400L    REPINS CVB,(R2,T400V)          repeat: CVB R2,T400V
         BCTR  R15,R11
         TSIMRET
*
         DS    0D
T400V    DC    PL8'1234567890'
         TSIMEND
*
* Test 401 -- CVD R,m --------------------------------------
*
         TSIMBEG T401,2500,50,1,C'CVD R,m'
*
         L     R2,=F'123456789'
T401L    REPINS CVD,(R2,T401V)          repeat: CVD R2,T401V
         BCTR  R15,R11
         TSIMRET
*
T401V    DS    1D
         TSIMEND
*
* Test 402 -- PACK m,m (5d) --------------------------------
*
         TSIMBEG T402,6000,20,1,C'PACK m,m (5d)'
*
T402L    REPINS PACK,(T402V1,T402V2)    repeat: PACK T402V1,T402V2
         BCTR  R15,R11
         TSIMRET
*
T402V1   DC    PL3'0'
T402V2   DC    ZL6'12345'
         TSIMEND
*
* Test 403 -- PACK m,m (15d) -------------------------------
*
         TSIMBEG T403,2500,20,1,C'PACK m,m (15d)'
*
T403L    REPINS PACK,(T403V1,T403V2)    repeat: PACK T403V1,T403V2
         BCTR  R15,R11
         TSIMRET
*
T403V1   DC    PL8'0'
T403V2   DC    ZL16'123456789012345'
         TSIMEND
*
* Test 404 -- UNPK m,m (5d) --------------------------------
*
         TSIMBEG T404,6000,20,1,C'UNPK m,m (5d)'
*
T404L    REPINS UNPK,(T404V1,T404V2)    repeat: UNPK T404V1,T404V2
         BCTR  R15,R11
         TSIMRET
*
T404V1   DC    ZL6'0'
T404V2   DC    PL3'12345'
         TSIMEND
*
* Test 405 -- UNPK m,m (15d) --------------------------------
*
         TSIMBEG T405,2500,20,1,C'UNPK m,m (15d)'
*
T405L    REPINS UNPK,(T405V1,T405V2)    repeat: UNPK T405V1,T405V2
         BCTR  R15,R11
         TSIMRET
*
T405V1   DC    ZL16'0'
T405V2   DC    PL8'123456789012345'
         TSIMEND
*
* Test 41x -- edit =========================================
*
* Test 410 -- MVC;ED (10c) ----------------------------------
*
         TSIMBEG T410,3300,10,1,C'MVC;ED (10c)'
*
*          use sequence
*            MVC   0(10,R3),T410V3    setup edit pattern
*            ED    0(10,R3),T410V1+3  and do it
*
         L     R2,=F'123456789'
         CVD   R2,T410V1
         LA    R3,T410V2                points to edit position
*
T410L    REPINS2 MVC,(0(10,R3),T410V3),ED,(0(10,R3),T410V1+3)
         BCTR  R15,R11
         TSIMRET
*
T410V1   DS    1D
T410V2   DS    10C
T410V3   DC    C' ',7X'20',X'21',X'20'
         TSIMEND
*
* Test 411 -- MVC;ED (30c) ----------------------------------
*
         TSIMBEG T411,1200,10,1,C'MVC;ED (30c)'
*
*          use sequence
*            MVC   0(30,R3),T411V3    setup edit pattern
*            ED    0(30,R3),T411V1    and do it
*
         LA    R3,T411V2                points to edit position
*
T411L    REPINS2 MVC,(0(30,R3),T411V3),ED,(0(30,R3),T411V1)
         BCTR  R15,R11
         TSIMRET
*
T411V1   DC    PL15'1234567890123456789012345678'
T411V2   DS    30C
T411V3   DC    C' ',27X'20',X'21',X'20'
         TSIMEND
*
* Test 415 -- MVC;EDMK (10c) --------------------------------
*
         TSIMBEG T415,3300,10,1,C'MVC;EDMK (10c)'
*
*          use sequence
*            MVC   0(10,R3),T415V3    setup edit pattern
*            EDMK  0(10,R3),T415V1+3  and do it
*
         L     R2,=F'123456789'
         CVD   R2,T415V1
         LA    R3,T415V2                points to edit position
*
T415L    REPINS2 MVC,(0(10,R3),T415V3),EDMK,(0(10,R3),T415V1+3)
         BCTR  R15,R11
         TSIMRET
*
T415V1   DS    1D
T415V2   DS    10C
T415V3   DC    C' ',7X'20',X'21',X'20'
         TSIMEND
*
* Test 42x -- decimal add/mul/div ==========================
*
* Test 420 -- AP m,m (10d) ---------------------------------
*
         TSIMBEG T420,700,30,1,C'AP m,m (10d)'
*
* value range *-999999999: start at -999999999, add 66666660
*
T420L    MVC   T420V1,T420V3
         REPINS AP,(T420V1,T420V2)      repeat: AP T420V1,T420V2
         BCTR  R15,R11
         TSIMRET
*
T420V1   DC    PL5'0'                   accululator
T420V2   DC    PL5'66666660'            increment value
T420V3   DC    PL5'-999999999'          initial value
         TSIMEND
*
* Test 421 -- AP m,m (30d) ---------------------------------
*
         TSIMBEG T421,700,30,1,C'AP m,m (30d)'
*
T421L    MVC   T421V1,T421V3
         REPINS AP,(T421V1,T421V2)      repeat: AP T421V1,T421V2
         BCTR  R15,R11
         TSIMRET
*
T421V1   DC    PL15'0'                             accululator
T421V2   DC    PL15'123456789012345678901234'      incr (24 sign.dig)
T421V3   DC    PL15'1234567890123456789012345678'  init (28 sign.dig)
         TSIMEND
*
* Test 422 -- MP m,m (10d) ---------------------------------
*
         TSIMBEG T422,900,20,1,C'MP m,m (10d)'
*
T422L    MVC   T422V1,T422V3
         REPINS MP,(T422V1,T422V2)      repeat: AP T422V1,T422V2
         BCTR  R15,R11
         TSIMRET
*
T422V1   DC    PL5'0'
T422V2   DC    PL1'2'
T422V3   DC    PL5'1'
         TSIMEND
*
* Test 423 -- MP m,m (30d) ---------------------------------
*
         TSIMBEG T423,900,20,1,C'MP m,m (30d)'
*
T423L    MVC   T423V1,T423V3
         REPINS MP,(T423V1,T423V2)      repeat: AP T423V1,T423V2
         BCTR  R15,R11
         TSIMRET
*
T423V1   DC    PL15'0'
T423V2   DC    PL1'-9'
T423V3   DC    PL15'1'
         TSIMEND
*
* Test 43x -- decimal compare ==============================
*
* Test 430 -- CP m,m (10d) ---------------------------------
*
         TSIMBEG T430,1000,30,1,C'CP m,m (10d)'
*
T430L    REPINS CP,(T430V1,T430V2)      repeat: CP T430V1,T430V2
         BCTR  R15,R11
         TSIMRET
*
T430V1   DC    PL5'999999999'
T430V2   DC    PL5'999999998'
         TSIMEND
*
* Test 431 -- CP m,m (30d) ---------------------------------
*
         TSIMBEG T431,1000,30,1,C'CP m,m (30d)'
*
T431L    REPINS CP,(T431V1,T431V2)      repeat: CP T431V1,T431V2
         BCTR  R15,R11
         TSIMRET
*
T431V1   DC    PL15'1234567890123456789012345678'
T431V2   DC    PL15'1234567890123456789012345677'
         TSIMEND
*
* Test 44x -- ZAP,SRP ======================================
*
*
* Test 440 -- ZAP m,m (10d,10d) ----------------------------
*
         TSIMBEG T440,1600,30,1,C'ZAP m,m (10d,10d)'
*
T440L    REPINS ZAP,(T440V1,T440V2)     repeat: ZAP T440V1,T440V2
         BCTR  R15,R11
         TSIMRET
*
T440V1   DC    PL5'0'
T440V2   DC    PL5'999999999'
         TSIMEND
*
* Test 441 -- ZAP m,m (30d,30d) ----------------------------
*
         TSIMBEG T441,1600,30,1,C'ZAP m,m (30d,30d)'
*
T441L    REPINS ZAP,(T441V1,T441V2)     repeat: ZAP T441V1,T441V2
         BCTR  R15,R11
         TSIMRET
*
T441V1   DC    PL15'0'
T441V2   DC    PL15'1234567890123456789012345677'
         TSIMEND
*
* Test 442 -- ZAP m,m (10d,30d) ----------------------------
*
         TSIMBEG T442,1600,30,1,C'ZAP m,m (10d,30d)'
*
T442L    REPINS ZAP,(T442V1,T442V2)     repeat: ZAP T442V1,T442V2
         BCTR  R15,R11
         TSIMRET
*
T442V1   DC    PL5'0'
T442V2   DC    PL15'999999999'
         TSIMEND
*
* Test 443 -- ZAP m,m (30d,10d) ----------------------------
*
         TSIMBEG T443,1600,30,1,C'ZAP m,m (30d,10d)'
*
T443L    REPINS ZAP,(T443V1,T443V2)     repeat: ZAP T443V1,T443V2
         BCTR  R15,R11
         TSIMRET
*
T443V1   DC    PL15'0'
T443V2   DC    PL5'999999999'
         TSIMEND
*
* Test 445 -- SRP m,i,i (30d,<<) -------------------------
*
         TSIMBEG T445,1600,25,1,C'MVC;SRP m,i,i (30d,<<)'
*
T445L    MVC   T445V1,T445V2
         REPINS SRP,(T445V1,1,0)        repeat: SRP T445V1,1,0
         BCTR  R15,R11
         TSIMRET
*
T445V1   DC    PL15'0'
T445V2   DC    PL15'1'
         TSIMEND
*
* Test 446 -- SRP m,i,i (30d,>>) ---------------------------
*
         TSIMBEG T446,1000,25,1,C'MVC;SRP m,i,i (30d,>>)'
*
T446L    MVC   T446V1,T446V2
         REPINS SRP,(T446V1,64-1,5)     repeat: SRP T446V1,64-1,5
         BCTR  R15,R11
         TSIMRET
*
T446V1   DC    PL15'0'
T446V2   DC    PL15'19191919191919191919191919'
         TSIMEND
*
* Test 450 -- MVO m,m (10d) --------------------------------
*
         TSIMBEG T450,5000,20,1,C'MVO m,m (10d)'
*
T450L    REPINS MVO,(T450V1,T450V2)     repeat: MVO T450V1,T450V2
         BCTR  R15,R11
         TSIMRET
*
T450V1   DC    PL5'123'
T450V2   DC    PL5'4567'
         TSIMEND
*
* Test 451 -- MVO m,m (30d) --------------------------------
*
         TSIMBEG T451,2000,20,1,C'MVO m,m (30d)'
*
T451L    REPINS MVO,(T451V1,T451V2)     repeat: MVO T451V1,T451V2
         BCTR  R15,R11
         TSIMRET
*
T451V1   DC    PL15'123'
T451V2   DC    PL15'19191919191919191919191919'
         TSIMEND
*
* Test 5xx -- floating point ====================================
*
* Test 50x -- short float load/store =======================
*
* Test 500 -- LER R,R --------------------------------------
*
         TSIMBEG T500,10000,100,1,C'LER R,R'
*
         LE    FR2,=E'1.1'
T500L    REPINS LER,(FR0,FR2)           repeat: LER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 501 -- LE R,m ---------------------------------------
*
         TSIMBEG T501,10000,50,1,C'LE R,m'
*
T501L    REPINS LE,(FR0,=E'1.0')        repeat: LE FR0,=E'1.0'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 502 -- LE R,m (unal) --------------------------------
*
         TSIMBEG T502,10000,50,1,C'LE R,m (unal)'
*
         LA    R3,T502V
T502L    REPINS LE,(FR0,1(R3))          repeat: LE FR0,1(R3)'
         BCTR  R15,R11
         TSIMRET
*
         DS    0E
T502V    DC    2X'4E4E4E4E'             target for unaligned load
         TSIMEND
*
* Test 503 -- LTER R,R -------------------------------------
*
         TSIMBEG T503,10000,100,1,C'LTER R,R'
*
         LE    FR2,=E'1.0'
T503L    REPINS LTER,(FR0,FR2)          repeat: LTER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 504 -- LCER R,R -------------------------------------
*
         TSIMBEG T504,10000,100,1,C'LCER R,R'
*
         LE    FR2,=E'1.0'
T504L    REPINS LCER,(FR0,FR2)          repeat: LCER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 505 -- LNER R,R -------------------------------------
*
         TSIMBEG T505,10000,100,1,C'LNER R,R'
*
         LE    FR2,=E'1.0'
T505L    REPINS LNER,(FR0,FR2)          repeat: LNER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 506 -- LPER R,R -------------------------------------
*
         TSIMBEG T506,9000,100,1,C'LPER R,R'
*
         LE    FR2,=E'-1.0'
T506L    REPINS LPER,(FR0,FR2)          repeat: LPER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 507 -- LRER R,R -------------------------------------
*
         TSIMBEG T507,8000,100,1,C'LRER R,R'
*
         LD    FR2,=D'1.1'
T507L    REPINS LRER,(FR0,FR2)          repeat: LRER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 508 -- STE R,m --------------------------------------
*
         TSIMBEG T508,10000,50,1,C'STE R,m'
*
T508L    REPINS STE,(FR0,T508V)         repeat: STE FR0,T508V'
         BCTR  R15,R11
         TSIMRET
*
T508V    DS    1E
         TSIMEND
*
* Test 509 -- STE R,m (unal) -------------------------------
*
         TSIMBEG T509,10000,50,1,C'STE R,m (unal)'
*
         LA    R3,T509V
T509L    REPINS STE,(FR0,1(R3))         repeat: STE FR0,1(R3)'
         BCTR  R15,R11
         TSIMRET
*
T509V    DS    2E
         TSIMEND
*
* Test 51x -- short float arithmetic =======================
*
* Test 510 -- AER R,R --------------------------------------
*
         TSIMBEG T510,8000,50,1,C'AER R,R'
*
         LE    FR2,=E'1.1'
T510L    SER   FR0,FR0
         REPINS AER,(FR0,FR2)           repeat: AER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 511 -- AE R,m ---------------------------------------
*
         TSIMBEG T511,6000,50,1,C'AE R,m'
*
T511L    SER   FR0,FR0
         REPINS AE,(FR0,=E'1.1')        repeat: AE FR0,=E'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 512 -- MER R,R --------------------------------------
*
         TSIMBEG T512,10000,50,1,C'MER R,R'
*
         LE    FR2,=E'1.1'
T512L    LE    FR0,=E'1.0'
         REPINS MER,(FR0,FR2)           repeat: MER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 513 -- ME R,m --------------------------------------
*
         TSIMBEG T513,6500,50,1,C'ME R,m'
*
T513L    LE    FR0,=E'1.0'
         REPINS ME,(FR0,=E'1.1')        repeat: ME FR0,=E'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 514 -- DER R,R --------------------------------------
*
         TSIMBEG T514,5000,50,1,C'DER R,R'
*
         LE    FR2,=E'1.1'
T514L    LE    FR0,=E'1.0'
         REPINS DER,(FR0,FR2)           repeat: DER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 515 -- DE R,m ---------------------------------------
*
         TSIMBEG T515,4000,50,1,C'DE R,m'
*
T515L    LE    FR0,=E'1.0'
         REPINS DE,(FR0,=E'1.1')        repeat: DE FR0,=E'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 516 -- CER R,R --------------------------------------
*
         TSIMBEG T516,10000,50,1,C'CER R,R'
*
         LE    FR0,=E'1.0'
         LE    FR2,=E'1.1'
T516L    REPINS CER,(FR0,FR2)           repeat: CER FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 517 -- CE R,m ---------------------------------------
*
         TSIMBEG T517,6000,50,1,C'CE R,m'
*
         LE    FR0,=E'1.0'
T517L    REPINS CE,(FR0,=E'1.1')        repeat: CE FR0,=E'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 518 -- AUR R,R --------------------------------------
*
         TSIMBEG T518,10000,50,1,C'AUR R,R'
*
         LE    FR2,T518V
T518L    LE    FR0,=E'1234.1'
         REPINS AUR,(FR0,FR2)           repeat: AUR FR0,FR2
         BCTR  R15,R11
         TSIMRET
*
         DS    0E
T518V    DS    X'4E000001'
         TSIMEND
*
* Test 519 -- HER R,R --------------------------------------
*
         TSIMBEG T519,16000,50,1,C'HER R,R'
*
T519L    LE    FR0,=E'1111111111.0'
         REPINS HER,(FR0,FR0)           repeat: HER FR0,FR0
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 52x -- long float load/store ========================
*
* Test 520 -- LDR R,R --------------------------------------
*
         TSIMBEG T520,9000,100,1,C'LDR R,R'
*
         LD    FR2,=D'1.1'
T520L    REPINS LDR,(FR0,FR2)           repeat: LDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 521 -- LD R,m ---------------------------------------
*
         TSIMBEG T521,10000,50,1,C'LD R,m'
*
T521L    REPINS LD,(FR0,=D'1.0')        repeat: LD FR0,=D'1.0'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 522 -- LD R,m (unal) --------------------------------
*
         TSIMBEG T522,10000,50,1,C'LD R,m (unal)'
*
         LA    R3,T522V
T522L    REPINS LD,(FR0,1(R3))          repeat: LD FR0,1(R3)'
         BCTR  R15,R11
         TSIMRET
*
         DS    0D
T522V    DC    3X'4E4E4E4E'             target for unaligned load
         TSIMEND
*
* Test 523 -- LTDR R,R -------------------------------------
*
         TSIMBEG T523,10000,100,1,C'LTDR R,R'
*
         LD    FR2,=D'1.0'
T523L    REPINS LTDR,(FR0,FR2)          repeat: LTDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 524 -- LCDR R,R -------------------------------------
*
         TSIMBEG T524,10000,100,1,C'LCDR R,R'
*
         LD    FR2,=D'1.0'
T524L    REPINS LCDR,(FR0,FR2)          repeat: LCDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 525 -- LNDR R,R -------------------------------------
*
         TSIMBEG T525,10000,100,1,C'LNDR R,R'
*
         LD    FR2,=D'1.0'
T525L    REPINS LNDR,(FR0,FR2)          repeat: LNDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 526 -- LPDR R,R -------------------------------------
*
         TSIMBEG T526,10000,100,1,C'LPDR R,R'
*
         LD    FR2,=D'-1.0'
T526L    REPINS LPDR,(FR0,FR2)          repeat: LPDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 527 -- LRDR R,R -------------------------------------
*
         TSIMBEG T527,7000,100,1,C'LRDR R,R'
*
         LD    FR4,T527V1
         LD    FR6,T527V1+8
T527L    REPINS LRDR,(FR0,FR4)          repeat: LRDR FR0,FR4
         BCTR  R15,R11
         TSIMRET
T527V1   DC    L'1.1'
         TSIMEND
*
* Test 528 -- STD R,m --------------------------------------
*
         TSIMBEG T528,10000,50,1,C'STD R,m'
*
T528L    REPINS STD,(FR0,T528V)         repeat: STD FR0,T528V'
         BCTR  R15,R11
         TSIMRET
*
T528V    DS    1D
         TSIMEND
*
* Test 529 -- STD R,m (unal) -------------------------------
*
         TSIMBEG T529,10000,50,1,C'STD R,m (unal)'
*
         LA    R3,T529V
T529L    REPINS STD,(FR0,1(R3))         repeat: STD FR0,1(R3)'
         BCTR  R15,R11
         TSIMRET
*
T529V    DS    2D
         TSIMEND
*
* Test 53x -- long float arithmetic ========================
*
* Test 530 -- ADR R,R --------------------------------------
*
         TSIMBEG T530,7000,50,1,C'ADR R,R'
*
         LD    FR2,=D'1.1'
T530L    SDR   FR0,FR0
         REPINS ADR,(FR0,FR2)           repeat: ADR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 531 -- AD R,m ---------------------------------------
*
         TSIMBEG T531,5500,50,1,C'AD R,m'
*
T531L    SDR   FR0,FR0
         REPINS AD,(FR0,=D'1.1')        repeat: AD FR0,=D'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 532 -- MDR R,R --------------------------------------
*
         TSIMBEG T532,6000,50,1,C'MDR R,R'
*
         LD    FR2,=D'1.1'
T532L    LD    FR0,=D'1.0'
         REPINS MDR,(FR0,FR2)           repeat: MDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 533 -- MD R,m ---------------------------------------
*
         TSIMBEG T533,4500,50,1,C'MD R,m'
*
T533L    LD    FR0,=D'1.0'
         REPINS MD,(FR0,=D'1.1')        repeat: MD FR0,=D'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 534 -- DDR R,R --------------------------------------
*
         TSIMBEG T534,700,50,1,C'DDR R,R'
*
         LD    FR2,=D'1.1'
T534L    LD    FR0,=D'1.0'
         REPINS DDR,(FR0,FR2)           repeat: DDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 535 -- DD R,m ---------------------------------------
*
         TSIMBEG T535,700,50,1,C'DD R,m'
*
T535L    LD    FR0,=D'1.0'
         REPINS DD,(FR0,=D'1.1')        repeat: DD FR0,=D'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 536 -- CDR R,R --------------------------------------
*
         TSIMBEG T536,8000,50,1,C'CDR R,R'
*
         LD    FR0,=D'1.0'
         LD    FR2,=D'1.1'
T536L    REPINS CDR,(FR0,FR2)           repeat: CDR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 537 -- CD R,m ---------------------------------------
*
         TSIMBEG T537,6000,50,1,C'CD R,m'
*
         LE    FR0,=D'1.0'
T537L    REPINS CD,(FR0,=D'1.1')        repeat: CD FR0,=D'1.1'
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 538 -- AWR R,R --------------------------------------
*
         TSIMBEG T538,8000,50,1,C'AWR R,R'
*
         LD    FR2,T538V
T538L    LD    FR0,=D'1234.1'
         REPINS AWR,(FR0,FR2)           repeat: AWR FR0,FR2
         BCTR  R15,R11
         TSIMRET
         DS    0D
T538V    DS    X'4E000000',X'00000001'
         TSIMEND
*
* Test 539 -- HDR R,R --------------------------------------
*
         TSIMBEG T539,13000,50,1,C'HDR R,R'
*
T539L    LE    FR0,=D'1111111111.0'
         REPINS HDR,(FR0,FR0)           repeat: HDR FR0,FR0
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 54x -- extended float arithmetic ====================
*
* Test 540 -- AXR R,R --------------------------------------
*
         TSIMBEG T540,4000,50,1,C'AXR R,R'
*
         LD    FR4,T540V1
         LD    FR6,T540V1+8
T540L    SDR   FR0,FR0
         SDR   FR2,FR2
         REPINS AXR,(FR0,FR4)           repeat: AXR FR0,FR4
         BCTR  R15,R11
         TSIMRET
*
T540V1   DC    L'1.1'
         TSIMEND
*
* Test 541 -- MXR R,R --------------------------------------
*
         TSIMBEG T541,3300,50,1,C'MXR R,R'
*
         LD    FR4,T541V2
         LD    FR6,T541V2+8
T541L    LD    FR0,T541V1
         LD    FR2,T541V1+8
         REPINS MXR,(FR0,FR4)           repeat: MXR FR0,FR4
         BCTR  R15,R11
         TSIMRET
*
T541V1   DC    L'1.0'
T541V2   DC    L'1.1'
         TSIMEND
*
* Test 6xx -- miscellaneous instructions ========================
*
* Test 600 -- STCK m ---------------------------------------
*
         TSIMBEG T600,1000,10,1,C'STCK m'
*
T600L    REPINS STCK,(T600V)            repeat: STCK T600V
         BCTR  R15,R11
         TSIMRET
*
         DS    0D
T600V    DS    2L
         TSIMEND
*
* Test 601 -- SPM R ----------------------------------------
*
         TSIMBEG T601,19000,100,1,C'SPM R'
*
         BALR  R2,0                     get prog mask to R2
T601L    REPINS SPM,R2                  repeat: SPM R2
         BCTR  R15,R11
         TSIMRET
         TSIMEND
*
* Test 610 -- EX R,i (with TM) -----------------------------
*
         TSIMBEG T610,3500,50,1,C'EX R,i (with TM)'
*
         LA    R2,X'01'
T610L    REPINS EX,(R2,T610I)           repeat: EX R2,T610I
         BCTR  R15,R11
         TSIMRET
*
T610I    TM    T610V,X'00'        executed via EX
T610V    DC    X'01'              target for TM instruction
         TSIMEND
*
* Test 611 -- EX R,i (with XI) -----------------------------
*
         TSIMBEG T611,3500,50,1,C'EX R,i (with XI)'
*
         LA    R2,X'03'
T611L    REPINS EX,(R2,T611I)           repeat: EX R2,T611I
         BCTR  R15,R11
         TSIMRET
*
T611I    XI    T611V,X'00'        executed via EX
T611V    DC    X'F1'              target for XI instruction
         TSIMEND
*
* Test 620 -- TS m (zero) ----------------------------------
*
         TSIMBEG T620,2300,50,1,C'MVI;TS m (zero)' 
*
*          use sequence
*            MVI   T620V,X'00'    set byte to all zeros
*            TS    T620V          test and set
*
T620L    REPINS2 MVI,(T620V,X'00'),TS,(T620V)
         BCTR  R15,R11
         TSIMRET
*
T620V    DC    X'00'              target for TS instruction
         TSIMEND
*
* Test 621 -- TS m (ones) ----------------------------------
*
         TSIMBEG T621,500,50,1,C'MVI;TS m (ones)' 
*
*          use sequence
*            MVI   T621V,X'FF'    set byte to all zeros
*            TS    T621V          test and set
*
T621L    REPINS2 MVI,(T621V,X'FF'),TS,(T621V)
         BCTR  R15,R11
         TSIMRET
*
T621V    DC    X'FF'              target for TS instruction
         TSIMEND
*
* Test 700 -- Mix Int RR -----------------------------------
*
         TSIMBEG T700,20000,40,1,C'mix int RR basic'
*
T700L    EQU   *
         LA    R2,1               R2 :=00000001 FIN
         LR    R3,R2              R3 :=00000001
         SLA   R3,8               R3 :=00000100 FIN
         XR    R4,R4              R4 :=00000000
         OR    R4,R3              R4 :=00000100
         BCTR  R4,0               R4 :=000000FF FIN
         LCR   R5,R4              R5 :=FFFFFF01
         SLL   R5,2               R5 :=FFFFFC04 FIN
         LPR   R6,R5              R6 :=000003FC
         AR    R6,R1              R6 :=000003FD
         CR    R6,R1              !=
         BE    T700BAD
         LNR   R7,R3              R7 :=FFFFFF00
         NR    R7,R6              R7 :=00000300
         SRA   R7,2               R7 :=000000C0
         SR    R7,R4              R7 :=FFFFFFC1
         LTR   R8,R3              R8 :=00000100
         SRL   R8,1               R8 :=00000080
         ALR   R8,R3              R8 :=00000180
         SLR   R8,R7              R8 :=000001BF
         CLR   R8,R3              !=
         BE    T700BAD
         LA    R9,602             R9 :=0000025A
         XR    R9,R4              R9 :=000002A5 FIN
         LTR   R10,R9             R10:=000002A5
         AR    R10,R9             R10:=000004FF
         OR    R10,R5             R10:=FFFFFCFF
         LPR   R6,R10             R6 :=00000301
         ALR   R6,R4              R6 :=00000400
         SLA   R6,1               R6 :=00000800
         SR    R6,R9              R6 :=0000055B
         BCTR  R6,0               R6 :=0000055A
         NR    R6,R5              R6 :=00000400
         SRA   R6,5               R6 :=00000020
         CR    R6,R4              !=
         LNR   R7,R6              R7 :=FFFFFFC0
         SLL   R7,2               R7 :=FFFFFF00
         SLR   R7,R2              R7 :=FFFFFEFF
         LCR   R8,R7              R8 :=00000101
         CLR   R8,R3              !=
         BCTR  R15,R11
         TSIMRET
*
         DS    0H
T700BAD  ABEND 60
         TSIMEND
*
* Test 701 -- Mix Int RX -----------------------------------
*
         TSIMBEG T701,22000,21,1,C'mix int RX'
*
T701L    EQU   *
         L     R2,T701F1          R2 :=00000072
         A     R2,T701F2          R2 :=00010072
         N     R2,T701F3          R2 :=00010042
         SH    R2,T701H1          R2 :=00010041
         MH    R2,T701H2          R2 :=00020082
         AH    R2,T701H3          R2 :=00020182
         CH    R2,T701H3
         AL    R2,T701F4          R2 :=00020180
         S     R2,T701F5          R2 :=0002017F
         O     R2,T701F6          R2 :=0013817F
         STH   R2,T701VH1
         ST    R2,T701VF1+4
         X     R2,T701F7          R2 :=00030178
         C     R2,T701F6
         LM    R4,R5,T701VF1      R5 :=0013817F (1278335)
         M     R4,T701F8          R5 :=         (157235205)
         D     R4,T701F9          R5 :=         (9249129)
         STM   R4,R5,T701VF2
         LH    R6,T701VH1         R6 :=FFFF817F
         SL    R6,T701F10         R6 :=0000017F
         CL    R6,T701F9
         BCTR  R15,R11
         TSIMRET
*
         DS    0F
T701F1   DC    X'00000072'
T701F2   DC    X'00010000'
T701F3   DC    X'FFFFFF4F'
T701F4   DC    X'FFFFFFFE'
T701F5   DC    X'00000001'
T701F6   DC    X'00118000'
T701F7   DC    X'00100007'
T701F8   DC    F'123'
T701F9   DC    F'17'
T701F10  DC    X'FFFF8000'
T701VF1  DC    2F'0'
T701VF2  DS    2F
         DS    0H
T701H1   DC    X'0001'
T701H2   DC    X'0002'
T701H3   DC    X'0100'
T701VH1  DS    1H
         TSIMEND
*
* Test 702 -- Mix Int RX (far) -----------------------------
*
         TSIMBEG T702,22000,21,1,C'mix int RX (far)'
*
         L     R10,=A(T702CS)     load base for data
T702L    EQU   *        
         USING T702CS,R10
         L     R2,T702F1          R2 :=00000072
         A     R2,T702F2          R2 :=00010072
         N     R2,T702F3          R2 :=00010042
         SH    R2,T702H1          R2 :=00010041
         MH    R2,T702H2          R2 :=00020082
         AH    R2,T702H3          R2 :=00020182
         CH    R2,T702H3
         AL    R2,T702F4          R2 :=00020180
         S     R2,T702F5          R2 :=0002017F
         O     R2,T702F6          R2 :=0013817F
         STH   R2,T702VH1
         ST    R2,T702VF1+4
         X     R2,T702F7          R2 :=00030178
         C     R2,T702F6
         LM    R4,R5,T702VF1      R5 :=0013817F (1278335)
         M     R4,T702F8          R5 :=         (157235205)
         D     R4,T702F9          R5 :=         (9249129)
         STM   R4,R5,T702VF2
         LH    R6,T702VH1         R6 :=FFFF817F
         SL    R6,T702F10         R6 :=0000017F
         CL    R6,T702F9
         DROP  R10
         BCTR  R15,R11
         TSIMRET
*
         TSIMEND
*
T702CS   CSECT
         DS    0F
T702F1   DC    X'00000072'
T702F2   DC    X'00010000'
T702F3   DC    X'FFFFFF4F'
T702F4   DC    X'FFFFFFFE'
T702F5   DC    X'00000001'
T702F6   DC    X'00118000'
T702F7   DC    X'00100007'
T702F8   DC    F'123'
T702F9   DC    F'17'
T702F10  DC    X'FFFF8000'
T702VF1  DC    2F'0'
T702VF2  DS    2F
         DS    0H
T702H1   DC    X'0001'
T702H2   DC    X'0002'
T702H3   DC    X'0100'
T702VH1  DS    1H
MAIN     CSECT
*
* Remember end of TDSCTBL ----------------------------------
*
TDSCTBL  CSECT
TDSCTBLE EQU   *
*
* other defs and end -------------------------------------------------
*
         YREGS ,
FR0      EQU   0
FR2      EQU   2
FR4      EQU   4
FR6      EQU   6
         END   MAIN               define main entry point
