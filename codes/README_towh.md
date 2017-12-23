## towh - Tower of Hanio solver

### Table of content

- [Description](#user-content-description)
- [Algorithm](#user-content-algorithm)
- [Input File](#user-content-ifile)
- [Language and Compiler Notes](#user-content-langcomp)
- [Jobs](#user-content-jobs)
- [Author's Note](#user-content-anote)

### Description <a name="description"></a>
The [Tower of Hanoi](https://en.wikipedia.org/wiki/Tower_of_Hanoi) is a
is a mathematical game or puzzle. It can be implemented with a few lines
of code, using only simplest integer arithmetic and a recursively called
procedure. It's nice as a simple integer benchmark, and was part of the
**UNIX BENCH V4.1** benchmark suite published by the
[**Byte Magazine**](https://en.wikipedia.org/wiki/Byte_(magazine)) ages ago.

### Algorithm <a name="algorithm"></a>
The `towh` codes follow closely the algorithm of the `hanoi` code of
UNIX BENCH V4.1, see source on
[GitHub meteorfox/byte-unixbench](https://github.com/meteorfox/byte-unixbench/blob/master/UnixBench/src/hanoi.c).
Maybe it's possible to write it nicer or more compact.
The key point is that all langauges follow the same logic, this
way we get a good comparision of the compiler quality.

The core of the algorithm is a recursive procedure working on the
array `tow` in a common scope, which in C looks like
``` c
    void mov(int n, int f, int t)
    {
      int o;
      if(n == 1) {
        tow[f]--;
        tow[t]++;
        return;
      }
      o = 6-(f+t);
      mov(n-1,f,o);
      mov(1,f,t);
      mov(n-1,o,t);
      return;
    }
```

### Input File <a name="ifile"></a>
The codes are controlled by an input file with a single line in `2I5` format
```
 NDSK TRCE
```

where `NDSK` gives largest tower size to be investigated and `TRCE`
enables (1) or disables (0) the debug printout of all moves.
The code will iterate of all tower sizes from 2 to `NDSK`.
Keep in mind that the CPU time grows exponentially as 2**NDSK.
See typical [test run](towh_ctst.dat) or
[benchmark run](towh_cnat.dat) input files.


### Language and Compiler Notes <a name="langcomp"></a>

#### Fortran 4 - [towh_for.f](towh_for.f)
Fortran introduced recursive calls only with
[Fortran 90](https://en.wikipedia.org/wiki/Fortran#Fortran_90),
so the Fortran implementation simulates the call nexting with a set
of arrays which contain what is otherwise in argument lists and stack
allocated variables. That adds more array accesses, but eliminates all
call overheads, so the Fortran implementation is in terms of speed
quite competitive. But certainly not in terms of readability.

### Jobs <a name="jobs"></a>
The [jobs](../jobs) directory contains three types of jobs for `towh` named

    towh_*_t.JES  --> trace all steps for small tower sizes (verification)
    towh_*_f.JES  --> print summaries (benchmarking)

Usually `towh_*_t.JES` is used for a verification check and should produce

    STRT ndsk=   2
    mov-go:    1 :    2   1   3 :    2   0   0
    mov-do:    2 :    1   1   2 :    1   1   0
    mov-do:    2 :    1   1   3 :    0   1   1
    mov-do:    2 :    1   2   3 :    0   0   2
    DONE ndsk=   2:  maxstk=   2  ncall=         4  nmove=         3
    ... snip ...
    STRT ndsk=   4
    mov-go:    1 :    4   1   3 :    4   0   0
    mov-go:    2 :    3   1   2 :    4   0   0
    ... snip ...
    mov-do:    4 :    1   1   3 :    0   1   3
    mov-do:    4 :    1   2   3 :    0   0   4
    DONE ndsk=   4:  maxstk=   4  ncall=        22  nmove=        15
    
`towh_*_f.JES` should in general output the equivalent of

    DONE ndsk=   2:  maxstk=   2  ncall=         4  nmove=         3
    DONE ndsk=   3:  maxstk=   3  ncall=        10  nmove=         7
    DONE ndsk=   4:  maxstk=   4  ncall=        22  nmove=        15
    DONE ndsk=   5:  maxstk=   5  ncall=        46  nmove=        31
    DONE ndsk=   6:  maxstk=   6  ncall=        94  nmove=        63
    DONE ndsk=   7:  maxstk=   7  ncall=       190  nmove=       127
    DONE ndsk=   8:  maxstk=   8  ncall=       382  nmove=       255
    DONE ndsk=   9:  maxstk=   9  ncall=       766  nmove=       511
    DONE ndsk=  10:  maxstk=  10  ncall=      1534  nmove=      1023
    DONE ndsk=  11:  maxstk=  11  ncall=      3070  nmove=      2047
    DONE ndsk=  12:  maxstk=  12  ncall=      6142  nmove=      4095
    DONE ndsk=  13:  maxstk=  13  ncall=     12286  nmove=      8191
    DONE ndsk=  14:  maxstk=  14  ncall=     24574  nmove=     16383
    DONE ndsk=  15:  maxstk=  15  ncall=     49150  nmove=     32767
    DONE ndsk=  16:  maxstk=  16  ncall=     98302  nmove=     65535
    DONE ndsk=  17:  maxstk=  17  ncall=    196606  nmove=    131071
    DONE ndsk=  18:  maxstk=  18  ncall=    393214  nmove=    262143
    DONE ndsk=  19:  maxstk=  19  ncall=    786430  nmove=    524287
    DONE ndsk=  20:  maxstk=  20  ncall=   1572862  nmove=   1048575
    DONE ndsk=  21:  maxstk=  21  ncall=   3145726  nmove=   2097151
    DONE ndsk=  22:  maxstk=  22  ncall=   6291454  nmove=   4194303

where the largest problem solved depends on the language.

### Author's Note <a name="anote"></a>

I worked in the late 70's and early 80's a lot with mainframes, mainly
[IBM System/370](https://en.wikipedia.org/wiki/IBM_System/370) and
[Cray 7600](https://en.wikipedia.org/wiki/CDC_7600), and minicomputers,
mainly [DEC PDP-11](https://en.wikipedia.org/wiki/PDP-11). Since we used
PDP-11 systems as
[data acquisition](https://en.wikipedia.org/wiki/Data_acquisition)
computers I had a lot of very direct hands-on interaction with them.

Based on that background I created, as leisure time project, a
[FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array)
based implementation of a PDP-11/70. See GitHub
[wfjm/w11](https://github.com/wfjm/w11/) project and the associated
[w11 home page](https://wfjm.github.io/home/w11/). When
[2.11BSD UNIX](https://en.wikipedia.org/wiki/Berkeley_Software_Distribution)
finally booted in 2009 it was time to do a few
[benchmarks](https://en.wikipedia.org/wiki/Benchmarking).
The UNIX BENCH V4.1 was an obvious candidate, and the `hanoi`
code is, besides [Dhrystone](https://en.wikipedia.org/wiki/Dhrystone),
a key part of my still quite simple performance studies, see
[comparison of w11 performance on different FPGAs](https://wfjm.github.io/home/w11/impl/performance.html#h_benchmarks).

Since the core of the algorithm is very simple and tests with
_recursive function calls_ a feature not covered by the other cases
I added `towh`. Also because I was curious how the compilers would
handle this on the
System/370 architecture which does not offer a build-in
[stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type))
support.
