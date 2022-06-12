# mvs38j-langtest: MVS 3.8J Compiler and Language Tests

[![Build Status](https://travis-ci.org/wfjm/mvs38j-langtest.svg?branch=master)](https://travis-ci.org/wfjm/mvs38j-langtest)

### <a id="overview">Overview</a>
The project contains example codes for many of the languages available
on the MVS 3.8J turnkey systems. Several test cases have been implemented
with equivalent logic in the available languages.
JES2 jobs are provided to 'compile-link-go' the codes with the available
compilers (in some cases several for one language). Test jobs, which
generate detailed output for verification, as well as benchmark jobs,
which consume a significant amount of CPU time, are provided.

### <a id="cases">The Cases</a>
The test cases are chosen to test different aspects of languages and
are identified by a 4 character case ID:

| Case ID | Description | Objective |
| :-----: | ----------- | --------- |
| [hewo](codes/README_hewo.md) | The classical **'Hello Word'** | Get **minimal program** producing output |
| [sine](codes/README_sine.md) | Line **printer plot** of sine and cosine | Test **basic text & character handling** |
| [soep](codes/README_soep.md) | Sieve of Eratosthenes **prime search** (byte) | Test **integer array handling** and **formatted output** |
| [soeq](codes/README_soeq.md) | Sieve of Eratosthenes **prime search (bit)** | Test **bit handling** |
| [towh](codes/README_towh.md) | **Tower of Hanoi** solver | Test **recursive function calls** |
| [mcpi](codes/README_mcpi.md) | **Monte Carlo** estimate of pi | Test **floating point arithmetic** |

The cases were implemented with essentially the same basic logic in all
languages so that one can compare the code quality of the compilers.
The algorithms should also be short and simple, so that an assembler
implementation is feasible. The links in the Case-Id column point to a
description of the test case.
The pick of cases is highly biased by the background of the author,
see '_Author's Note_' section in each of the READMEs.

### <a id="compilers">The Compilers and Languages</a>
The [tk4-](http://wotho.ethz.ch/tk4-/) system contains a nice selection of
languages and compilers which are for further reference identified by
a 3 or 4 character compiler ID.

| Language  | Compiler IDs |
| --------- | ------------ |
| Algol 60  | a60              |
| Assembler | asm              |
| C         | gcc, jcc         |
| COBOL     | cob              |
| FORTRAN-4 | forg, forh, forw |
| Pascal    | pas              |
| PL/I      | pli              |
| Simula    | sim              |

Consult the [Compiler README](README_comp.md) for more information on the
compilers and the options used, and the
[benchmark summary](README_bench.md) for an overview of some
benchmark runs and a compiler ranking.

### <a id="codes">The Codes</a>
The test cases were, if possible, implemented in these languages.
The [Language-Case matrix](codes/README.md) with all Language - Case
combinations is shown in the README of the [codes](codes) directory.

### <a id="jobs">The Jobs</a>
For each Language-Case combination one or several batch jobs are provided
in the [jobs](jobs) directory. See
[README](jobs/README.md) for the 
[Case - Job Type table](jobs/README.md#user-content-types) explaining
all available jobs types and the 
[Compiler-Case matrix](jobs/README.md#user-content-jobs) listing all
available jobs. The later also includes a list of
[known issues](jobs/README.md#user-content-issues).

### Reception
Moshe Bar covered the langtest and herc-tools suites in tutorials entitled
>>  Test your IBM MVS 3.8 compilers and benchmark your Hercules  
>>  https://www.youtube.com/watch?v=hH0dlylJVCY  
>>  Building an MVS printout distribution system  
>>  https://www.youtube.com/watch?v=GF677Z3Zidw

This is part of the [moshix suite](https://www.youtube.com/user/moshe5760/videos)
of mainframe (mostly MVS) related tutorials.

### Directory organization
The project files are organized in directories as

| Directory | Content |
| --------- | ------- |
| [codes](codes) | the codes |
| herc-tools     | the [herc-tools](https://github.com/wfjm/herc-tools) project as submodule, mainly for access to `hercjis`|
| [jcl](jcl)     | JCL job templates |
| [jobs](jobs)   | the jobs |
| sios           | the [mvs38j-sios](https://github.com/wfjm/mvs38j-sios) project as submodule, simple I/O system asm code |
| [tests](tests) | some test programs |

### License
This project is released under the 
[GPL V3 license](https://www.gnu.org/licenses/gpl-3.0.html),
all files contain a [SPDX](https://spdx.org/)-style disclaimer:

    SPDX-License-Identifier: GPL-3.0-or-later

The full text of the GPL license is in this directory as
[License.txt](License.txt).

### Installation
This project uses submodules, therefore use
```
  git clone --recurse-submodules git@github.com:wfjm/mvs38j-langtest.git
```
