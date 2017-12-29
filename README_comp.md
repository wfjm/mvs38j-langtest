## Available Compilers for MVS 3.8J

### Overview <a name="overview"></a>
The [tk4-](http://wotho.ethz.ch/tk4-/) system kindly provided by Juergen
Winkelmann contains a nice selection of compilers.
For further reference each compiler is identified by a 3 or 4 character
compiler ID.

| Language  | Compiler ID | Description | Default Options | Benchmark Options |
| --------- | :---------: |------------ | --------------- | ----------------- |
| Algol 60  | [a60](jcl/job_a60_clg.JESI)   | IBM Algol 60: 360S-AL-531 LEVEL 2.1 |        |          |
| Assembler | [asm](jcl/job_asm_clg.JESI)   | IBM Assembler Level F (370)         |        |          |
| C         | [gcc](jcl/job_gcc_clg.JESI)   | MVSGCC, a 370 port of gcc           | -O3    | -O3      |
| C         | [jcc](jcl/job_jcc_clg.JESI)   | early version of Dignus System/C    |        |          |
| COBOL     | [cob](jcl/job_cob_clg.JESI)   | IBM Cobol CB545 V2 LVL78 01MAY72    |        |          |
| FORTRAN-4 | [forg](jcl/job_forg_clg.JESI) | IBM FORTRAN IV G LEVEL  21          |        |          |
| FORTRAN-4 | [forh](jcl/job_forh_clg.JESI) | IBM FORTRAN H LEVEL 21.8            | OPT=2  | OPT=2    |
| FORTRAN-4 | [forw](jcl/job_forw_clg.JESI) | WATFIV Compiler JAN 1976 V1L5       | CHECK  | NOCHECK  |
| Pascal    | [pas](jcl/job_pas_clg.JESI)   | Stanford PASCAL, Version of Oct.-79 | D+     | D-       |
| PL/I      | [pli](jcl/job_pli_clg.JESI)   | IBM PL/I COMPILER (F) VERSION 5.5   | OPT=2  | OPT=2    |
| Simula    | [sim](jcl/job_sim_clg.JESI)   | SIMULA 67 (VERS 12.00)              | SUBCHK | NOSUBCHK |

The links in the table point to the 'compile-link-go' JCL templates in
the [jcl](jcl) directory.

### General Notes
- for all optimizing compilers (gcc, forh, pli) the highest optimization
  level is used as default.
- if a compiler offers configurable run-time checks (forw, pas, sim),
  these tests are
  - enabled for test jobs (`_t`)
  - disabled for benchmark jobs (`_f`)
