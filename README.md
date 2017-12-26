# mvs38j-langtest: MVS 3.8J Compiler and Language Tests

### Overview
The project contains example codes for many of the languages available
on the MVS 3.8J turnkey systems. Several test cases have been implemented
with equivalent logic in the available languages.
JES2 jobs are provided to 'compile-link-go' the codes with the available
compilers (in some cases several for one language). Test jobs, which
generate detailed output for verification, as well as benchmark jobs,
which consume a significant amount of CPU time, are provided.

### The Cases
The test cases are choosen to test different aspects of languages and
are identified by a 4 character case ID:

| Case ID | Description | Objective |
| :-----: | ----------- | --------- |
| [hewo](codes/README_hewo.md) | The classical **'Hello Word'** | Get **minimal program** producing output |
| [sine](codes/README_sine.md) | Line **printer plot** of sine and cosine | Test **basic text & character handling** |
| [soep](codes/README_soep.md) | Sieve of Erastosthenes **prime search** (byte) | Test **integer array handling** and **formatted output** |
| [soeq](codes/README_soeq.md) | Sieve of Erastosthenes **prime search (bit)** | Test **bit handling** |
| [towh](codes/README_towh.md) | **Tower of Hanio** solver | Test **recursive function calls** |
| [mcpi](codes/README_mcpi.md) | **Monte Carlo** estimate of pi | Test **floating point arithmetic** |

The cases were implemented with essentially the same basic logic in all
langauges so that one can compare the code quality of the compilers.
The algorithms should also be short and simple, so that an assembler
implementation is feasible. Beyond that the pick of cases is highly
biased by the background of the author, see '_Author's Note_' section
in each of the READMEs.

The [tk4-](http://wotho.ethz.ch/tk4-/) system kindly provided by Juergen
Winkelmann contains a nice selection of compilers.
For further reference each compiler is identified by 3 or 4 character
compiler ID.
The links in the table point to the 'compile-link-go' JCL templates in
the [jcl](jcl) directory:

| Language  | Compiler ID | Description |
| --------- | :---------: | ----------- |
| Algol 60  | [a60](jcl/job_a60_clg.JESI) | IBM Algol 60: 360S-AL-531 LEVEL 2.1 |
| Assembler | [asm](jcl/job_asm_clg.JESI) | IBM Assembler Level F (370) |
| C         | [gcc](jcl/job_gcc_clg.JESI) | MVSGCC, a 370 port of gcc |
| C         | [jcc](jcl/job_jcc_clg.JESI) | early version of Dignus System/C |
| Cobol     | [cob](jcl/job_cob_clg.JESI) | IBM Cobol CB545 V2 LVL78 01MAY72 |
| Fortran-4 | [forg](jcl/job_forg_clg.JESI) | IBM FORTRAN IV G LEVEL  21 |
| Fortran-4 | [forh](jcl/job_forh_clg.JESI) | IBM FORTRAN H LEVEL 21.8 |
| Fortran-4 | [forw](jcl/job_forw_clg.JESI) | WATFIV Compiler JAN 1976 V1L5 |
| Pascal    | [pas](jcl/job_pas_clg.JESI) | Stanford PASCAL, Version of Oct.-79 |
| PL/I      | [pli](jcl/job_pli_clg.JESI) | IBM PL/I COMPILER (F) VERSION 5.5 |
| Simula    | [sim](jcl/job_sim_clg.JESI) | SIMULA 67 (VERS 12.00) |

### The Codes
The test cases were, if possible, implemented in these languages.
The matrix of available Language-Case combinations is shown in the
[README](codes/README.md) of the [codes](codes) directory.

### The Jobs
For each Language-Case combination one or several batch jobs are provided
in the [jobs](jobs) directory. See
[README](jobs/README.md) for the 
[Case - Job Type table](jobs/README.md#user-content-types) explaining
all available jobs types and the 
[Compiler-Case matrix](jobs/README.md#user-content-jobs) listing all
available jobs. The later also includes a list of
[known issues](jobs/README.md#user-content-issues).


### Directory organization
The project files are organized in directories as

| Directory | Content |
| --------- | ------- |
| [bin](bin)     | some helper scripts |
| [clib](clib)   | assembler code sniplets  |
| [codes](codes) | the codes |
| [jcl](jcl)     | JCL job templates |
| [jobs](jobs)   | the jobs |
| [tests](tests) | some test programs |
