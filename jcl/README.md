This directory contains the compiler job templates.

These templates, file type `.JESI`, are used by `hercjis` to generate
from a meta-jcl `.JES` file a ready to run jcl job. The templates provide
a standardized interface to the stored procedures in `SYSx.PROCLIB` and
define variables which can be overridden from the `.JES` file. The
set of variables is compiler specific, the common ones are

| Variable | Function |
| -------- | -------- |
| JOB      | job name |
| CLASS    | job class |
| MSGCLASS | message class |
| MSGLEVEL | message level |
| REGION   | job memory |
| TIME     | job time limit |
| PRTY     | job priority |
| DDSRC    | source file |
| DDDAT    | data file |
| PARMC    | compile step PARM |
| PARML    | linker step PARM |
| OUTLIM   | go step SYSPRINT limit |

The following compilers are supported

| [Compiler ID](../README_comp.md) | JESI | called PROC | Comment |
| :---: | ---------| -------| ------- |
|   a60 | [job_a60_clg](job_a60_clg.JESI)   | ALGOFCLG |  |
|   asm | [job_asm_clg](job_asm_clg.JESI)   | ASMFCLG  |  |
|   cob | [job_cob_clg](job_cob_clg.JESI)   | COBUCLG  |  |
|  forg | [job_forg_clg](job_forg_clg.JESI) | FORTGCLG |  |
|  forh | [job_forh_clg](job_forh_clg.JESI) | FORTHCLG | OPT=2 |
|  forw | [job_forw_clg](job_forw_clg.JESI) | WATFIV   |  |
|   gcc | [job_gcc_clg](job_gcc_clg.JESI)   | GCCCLG   | -O3 |
|   jcc | [job_jcc_clg](job_jcc_clg.JESI)   | JCCCLG   |  |
|   pas | [job_pas_clg](job_pas_clg.JESI)   | PASCLG   |  |
|   pli | [job_pli_clg](job_pli_clg.JESI)   | PL1LFCLG | OPT=2 |
|   sim | [job_sim_clg](job_sim_clg.JESI)   | SIMCLG   |  |
