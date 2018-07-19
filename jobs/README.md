### Table of content

- [Overview](#user-content-overview)
- [Available Job Types](#user-content-types)
- [Available Jobs](#user-content-jobs)
  - [Job CLASS Usage](#user-content-class)
  - [Known Issues](#user-content-issues)
- [Howto create JCL](#user-content-getjcl)
- [Howto submit directly](#user-content-submit)

### <a id="overview">Overview</a>

Each case in implemented in different languages, and for some cases
several job types (like test job, benchmark job) are provided.
This leads to a fairly large number of case-language-type combinations where 
- same code is used for compilers of the same language
- same data input files are used across languages
- the basic [JCL](https://en.wikipedia.org/wiki/Job_Control_Language) structure
  is only language, but not case or type specific

The final jcl for a job is therefore dynamically created by the tool
[hercjis](https://github.com/wfjm/herc-tools/blob/master/doc/hercjis.md)
(in `herc-tools/bin` directory)
based on descriptor files with the file type `.JES` stored this directory.
The `.JES` are short and contain
- name of source code (from [codes](../codes) directory)
- name of input data file (from [codes](../codes) directory)
- name of jcl template file (type `.JESI`, from [jcl](../jcl) directory)
- if required, special job parameters used by the template

### <a id="types">Available Job Types</a>
For most test cases several job types are provided

| Case ID | Job Type | Decription |
| :-----: | -------- | --------- |
| [hewo](../codes/README_hewo.md) | hewo_*.JES   | print Hello World|
| [sine](../codes/README_sine.md) | sine_*.JES   | print printer plot|
| [soep](../codes/README_soep.md) | soep_*_t.JES | test job (verification) |
|                              | soep_*_f.JES | benchmark job (algorithm) |
|                              | soep_*_p.JES | benchmark job (formatted output)|
| [soeq](../codes/README_soeq.md) | soeq_*_t.JES | test job (verification) |
|                              | soeq_*_f_10.JES | benchmark job (algorithm, 10M sieve for `soep` comparison) |
|                              | soeq_*_f.JES | benchmark job (algorithm, full 100M sieve) |
|                              | soeq_*_p.JES | benchmark job (formatted output)|
| [towh](../codes/README_towh.md) | towh_*_t.JES | test job (verification) |
|                              | towh_*_f.JES | benchmark job |
| [mcpi](../codes/README_mcpi.md) | mcpi_*_t.JES | test job (verification) |
|                              | mcpi_*_f.JES | benchmark job |

For details follow the link in the Case ID column and consult the
[available jobs](#user-content-jobs) section. See also the
[benchmark summary](../README_bench.md) for an overview table of benchmark
results and a compiler ranking.

### <a id="jobs">Available Jobs</a>
The available Compiler-Case combinations are

| Language  | Compiler ID | [hewo](../codes/README_hewo.md) | [sine](../codes/README_sine.md) | [soep](../codes/README_soep.md) | [soeq](../codes/README_soeq.md) | [towh](../codes/README_towh.md) | [mcpi](../codes/README_mcpi.md) |
| --------- | :---------: | :--- | :--- | :--- | :--- | :--- | :--- |
| Algol 60  | [a60](../jcl/job_a60_clg.JESI)   | yes  | yes  | _t, _f, _p  | --          | _t, _f  | _t, _f **N02** |
| Assembler | [asm](../jcl/job_asm_clg.JESI)   | yes  | --   | _t, _f, _p  | _t, _f, _p  | _t, _f  | _t, _f         |
| C         | [gcc](../jcl/job_gcc_clg.JESI)   | yes  | yes  | _t, _f, _p  | _t, _f, _p  | _t, _f  | _t, _f         |
| C         | [jcc](../jcl/job_jcc_clg.JESI)   | yes  | yes  | _t, _f, _p  | _t, _f, _p  | _t, _f  | _t, _f **N01** |
| COBOL     | [cob](../jcl/job_cob_clg.JESI)   | yes  | --   | --          | --          | --      | --             |
| FORTRAN-4 | [forg](../jcl/job_forg_clg.JESI) | yes  | yes  | _t, _f, _p  | --          | _t, _f  | _t, _f         |
| FORTRAN-4 | [forh](../jcl/job_forh_clg.JESI) | yes  | yes  | _t, _f, _p  | --          | _t, _f  | _t, _f         |
| FORTRAN-4 | [forw](../jcl/job_forw_clg.JESI) | yes  | yes  | _t, _f, _p  | --          | _t, _f  | _t, _f         |
| Pascal    | [pas](../jcl/job_pas_clg.JESI)   | yes  | yes  | _t, _f, _p  | _t, _f, _p  | _t, _f  | _t, _f         |
| PL/I      | [pli](../jcl/job_pli_clg.JESI)   | yes  | yes  | _t, _f, _p  | _t, _f, _p  | _t, _f  | _t, _f         |
| Simula    | [sim](../jcl/job_sim_clg.JESI)   | yes  | yes  | _t, _f, _p  | --          | _t, _f  | _t, _f         |

#### <a id="class">Job CLASS Usage</a>
The job `CLASS` is chosen to give best response on
[tk4-](http://wotho.ethz.ch/tk4-/) systems and set to B,C or A
depending on expected CPU time and memory consumption
- `CLASS B` for fast runners: hewo*,sine*,*_t
- `CLASS C` for jobs with `REGION` >= 5000K
- `CLASS A` for rest: _f,_p

The predefined job `CLASS` can be overridden with the `hercjis`
[-c option](https://github.com/wfjm/herc-tools/blob/master/doc/hercjis.md#user-content-opt-c). For benchmarking it is highly advisable to use `CLASS C` via
a `-c C` option, see
[Howto submit directly](#user-content-submit) section.

#### <a id="issues">Known Issues</a>
- **N01:** `mcpi_jcc_*.JES` fails on [tk4-](http://wotho.ethz.ch/tk4-/)
  update 08 due to a compiler bug.
  JCC generates a wrong constant, which screws up the random number sequence.
  The code compiles and executes, but the results are wrong.
  The bug is reported to the maintainer.
- **N02:** `mcpi_a60_*.JES` fails on [tk4-](http://wotho.ethz.ch/tk4-/)
  update 08 due to a compiler bug.
  The code requires double precision floating point, which in IBM Algol 60
  must be selected with the compiler option `LONG`. Due to a bug in the
  compiler this option is not recognized, single precision code is generated,
  which is does not give proper results.
  The bug is reported, see
  [turnkey-mvs posting](https://groups.yahoo.com/neo/groups/turnkey-mvs/conversations/topics/10401).
  A fix of the compiler is available from the maintainer, Tom Armstrong, see
  [turnkey-mvs/files/IEX10.zip](https://groups.yahoo.com/neo/groups/turnkey-mvs/files/IEX10.zip), and **must be installed** before running `mpci_a60*` jobs.
  This fix will be included in tk4- update 09.

### <a id="getjcl">Howto create JCL</a>
When [hercjis](https://github.com/wfjm/herc-tools/blob/master/doc/hercjis.md)
is called with the
[-o option](https://github.com/wfjm/herc-tools/blob/master/doc/hercjis.md#user-content-opt-o)
it will write the generated job to the file given after the `-o` option, like
```
   hercjis -o hewo_asm.jcl  hewo_asm.JES
```
The generated `.jcl` file can now be submitted with any available tool.
Converting all `.JES` files is easiest done with `make`.
A [Makefile](Makefile) is provided which allows to convert a single
file or all files if `make` is called with no target or `all` as target.
To convert all `.JES` into `.jcl` simply
- ensure that `herc-tools/bin/hercjis` is in the search path
  (e.g. set `$PATH` properly)
- type `make`

### <a id="submit">Howto submit directly</a>
When
[hercjis](https://github.com/wfjm/herc-tools/blob/master/doc/hercjis.md)
is called without `-o` option it will send the job to a
`sockdev` reader on port 3505. To use this most direct way to submit a job
- setup hercules with `devinit 00c 3505 sockdev ascii trunc eof`
- ensure that `herc-tools/bin/hercjis` is in the search path
  (e.g. set `$PATH` properly)
- submit with `hercjis <file>.JES`

Since
[hercjis](https://github.com/wfjm/herc-tools/blob/master/doc/hercjis.md)
accepts multiple input files whole job trains can be submitted,
for example all simple and test jobs with
```
   hercjis hewo*.JES sine*.JES *_t.JES
```

For benchmarking it is often better to ensure that only one job is active
at a time. On a [tk4-](http://wotho.ethz.ch/tk4-/)
system `CLASS=C` jobs have only a single initiator. The
[-c option](https://github.com/wfjm/herc-tools/blob/master/doc/hercjis.md#user-content-opt-c) allows to override the `CLASS`, so a 
```
   hercjis -c C *_f.JES
```
will submit all benchmark jobs and run them sequentially.
