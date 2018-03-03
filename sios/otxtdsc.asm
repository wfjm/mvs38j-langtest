*
* OTXTDSC - setup text descriptor for simple output system -
*
         MACRO
&LABEL   OTXTDSC  &TEXT
TEXT     CSECT
SPTR&SYSNDX DC    &TEXT
&SYSECT  CSECT
         DS    0F
&LABEL   DC    AL1(L'SPTR&SYSNDX),AL3(SPTR&SYSNDX)
         MEND
