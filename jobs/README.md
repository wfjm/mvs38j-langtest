### Table of content

- [Overview](#user-content-overview)
- [Available Job Types](#user-content-types)
- [Available Jobs](#user-content-jobs)
  - [Known Issues](#user-content-issues)
- [Howto create JCL](#user-content-getjcl)
- [Howto submit directly](#user-content-submit)

### Overview <a name="overview"></a>

Each case in implemented in different languages, and for some cases
several job types (like test job, benchmark job) are provided.
This leads to a fairly large number of case-language-type combinations where 
- same code is used for compilers of the same language
- same data input files are used across languages
- the basic JCL structure is only langauage, but not case or type specific

The final jcl for a job is therefore dynamically created by the tool
`hercjis` (in [bin](../bin) directory)
based on descriptor files with the file type `.JES` stored this directory.
The `.JES` are short and contain
- name of source code (from [codes](../codes) directory)
- name of input data file (from [codes](../codes) directory)
- name of jcl template file (type `.JESI`, from [jcl](../jcl) directory)
- if required, special job parameters used by the template

### Available Job Types <a name="types"></a>
For some test cases several job types are provided

| Case ID | Job Type | Decription |
| :-----: | -------- | --------- |
| [hewo](../codes/README_hewo.md) | hewo_*.JES   | print Hello World|
| [sine](../codes/README_sine.md) | sine_*.JES   | print printer plot|
| [soep](../codes/README_soep.md) | soep_*_t.JES | test job (verification) |
|                              | soep_*_f.JES | benchmark job (algorithm) |
|                              | soep_*_p.JES | benchmark job (formatted output)|
| [soeq](../codes/README_soeq.md) | soeq_*_t.JES | test job (verification) |
|                              | soeq_*_f.JES | benchmark job (algorithm) |
|                              | soeq_*_p.JES | benchmark job (formatted output)|
| [towh](../codes/README_towh.md) | towh_*_t.JES | test job (verification) |
|                              | towh_*_f.JES | benchmark job |
| [mcpi](../codes/README_mcpi.md) | mcpi_*_t.JES | test job (verification) |
|                              | mcpi_*_f.JES | benchmark job |

For details follow the link in the Case ID column and consult the
"Jobs" section. See also the [benchmark summary](../README_bench.md) for an
overview table of benchmark results and a compiler ranking.

### Available Jobs <a name="jobs"></a>
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

#### Known Issues <a name="issues"></a>
- **N01:** `mcpi_jcc_*.JES` fails on [tk4-](http://wotho.ethz.ch/tk4-/)
  update 08 due to a compiler bug.
  JCC generates a wrong constant, which screws up the random number sequence.
  The code compiles and executes, but the results are wrong.
  The bug is reported to the maintainer.
- **N02:** `mcpi_a60_*.JES` fails on [tk4-](http://wotho.ethz.ch/tk4-/)
  update 08 due to a compiler bug.
  The code requires double precision floating point, which in IBM Algol 60
  must be selected with a compiler option. Due to a bug in the compiler this
  option is not recognized, simgle precision code generate, which is does not
  give proper results.
  The bug is reported to the maintainer, a fixed version of the compiler is
  available and will ship with tk4- update 09.

### Howto create JCL <a name="getjcl"></a>
When `hercjis` is called with the `-o` option it will write the generated
job to the file given after the `-o` option, like
```
   hercjis -o hewo_asm.jcl  hewo_asm.JES
```
The generated `.jcl` file can now be submitted with any available tool.
Converting all `.JES` files is easiest done with `make`.
A [Makefile](Makefile) is provided which allows to convert a single
file or all files if `make` is called with no target or `all` as target.
To convert all `.JES` into `.jcl` simply
- ensure that `bin/hercjis` is in the search path (e.g. set `$PATH` properly)
- type `make`

### Howto submit directly <a name="submit"></a>
When `hercjis` is called without `-o` option it will send the job to a
`sockdev` reader on port 3505. To use this most direct way to submit a job
- setup hercules with `devinit 00c 3505 sockdev ascii trunc eof`
- ensure that `bin/hercjis` is in the search path (e.g. set `$PATH` properly)
- submit with `hercjis <file>.JES`

Since `hercjis` accepts multiple input files whole job trains can be submitted,
for example all simple and test jobs with
```
   hercjis hewo*.JES sine*.JES *_t.JES
```

For benchmarking it is often better to ensure that only one job is active
at a time. On tk4- `CLASS=C` jobs have only a single initiator, so
```
   hercjis -c C *_f.JES
```
will submit all benchmark jobs and run them sequentially.
