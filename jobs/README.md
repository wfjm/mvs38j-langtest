### Overview

Each case in implemented in different languages, and for some cases
several job types (like test job, benchmark job) are provided.
This leads to a fairly large number of case-language-type combinations where 
- same code is used for compilers of the same language
- same data input files are used across languages
- the basic JCL structure is only langauage, but not case or type specific

The final jcl for a job is therefore dynamically created by the tool
hercjis
based descriptor files with the file type `.JES` stored this directory.
The `.JES` are short and contain
- name of source code (from [codes](../codes) directory)
- name of input data file (from [codes](../codes) directory)
- name of jcl template file (type `.JESI`, from [jcl](../jcl) directory)
- if required, special job parameters used by the template

### Available Job Types
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

For details follow the link in the Case ID column and consult the "Jobs" section.

### Known issues
- `mcpi_jcc_*.JES` fail on [tk4-](http://wotho.ethz.ch/tk4-/) update 08 due
  to a compiler bug.
  JCC generates a wrong constant, which screws up the random number sequence.
  The code compiles and executes, but the results are wrong.
- `mcpi_a60_*.JES` fail on [tk4-](http://wotho.ethz.ch/tk4-/) update 08 due
  to a compiler bug.
  The code requires double precision floating point, which in IBM Algol 60
  must be selected with a compiler option. Due to a bug in the compiler this
  option is not recognized, simgle precision code generate, which is does not
  give proper results.
