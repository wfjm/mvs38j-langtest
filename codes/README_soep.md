## soep - Sieve of Eratosthenes prime search (byte)

### Table of content

- [Description](#user-content-description)
- [Algorithm](#user-content-algorithm)
- [Input File](#user-content-ifile)
- [Language and Compiler Notes](#user-content-langcomp)
- [Jobs](#user-content-jobs)
- [Benchmarks](#user-content-benchmarks)
- [Author's Note](#user-content-anote)

### <a id="description">Description</a>
The [sieve of Eratosthenes](https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes)
algorithm is used to determine the
[prime numbers](https://en.wikipedia.org/wiki/Prime_number) up to a given
maximum, and either print all found primes or only short summary with counts
of primes for each decade. The sieve is implemented using one byte per odd
number, using the data types
- `BOOLEAN` in Algol 60
- `char` in C
- `LOGICAL*1` in FORTRAN
- `boolean` in Pascal
- `CHAR(1)` in PL/I
- `CHARACTER` in Simula

Since the maximal user memory available in MVS 3.8J is about 9 MByte the
jobs target the primes up to 1.E7, resulting in a 5 MByte sieve array size.

The number of primes `pi(x)` up to a given limit `x` is well known, see for
example [this page](https://primes.utm.edu/howmany.html):

              x        pi(x)
             10            4
            100           25
          1,000          168
         10,000        1,229
        100,000        9,592
      1,000,000       78,498
     10,000,000      664,579
    100,000,000    5,761,455

### <a id="algorithm">Algorithm</a>
The basic algorithm for the determinion of all prime numbers up to a
limit `nmax` can be summarized as
- **init**: initialize an array `prime` of dimension `[1,nmax]` with `TRUE`
- **outer loop**: check for all numbers p whether `prime[p]` is `TRUE`
- **inner loop**: if yes, set `prime[n*p]` to `FALSE` for n=2,..
- **scan**: at the end scan `prime`, each entry still being `TRUE` marks a prime

This basic form can be refined by
- represent only odd numbers in `prime`
- run the outer loop only up to sqrt(nmax)
- start the inner loop at n=p (rather than n=2)

The core of the algorithm is just 4 lines in C (with nmsqrt = sqrt(nmax)):
``` c
    for (n=3; n<=nmsqrt; n+=2) {    
      if (prime[n/2] == 0) continue;
      for (p=&prime[(n*n)/2]; p<=pmax; p+=n) *p = 0;
    }
```

### <a id="ifile">Input File</a>
The codes are controlled by an input file with a single line in `2I10` format
```
      NMAX      PRNT
```

where `NMAX` gives the range of the prime search and `PRNT` enables (1)
or disables (0) printing of all found primes. The summary is always
printed.
See typical [test run](soep_ctst.dat) or
[algorithm benchmark run](soep_cnat.dat) or
[print benchmark run](soep_cprt.dat) input files.

### <a id="langcomp">Language and Compiler Notes</a>
The sieve array is dynamically allocated whenever feasible.

#### PL/I - [soep_pli.pli](soep_pli.pli)
This PL/I version uses intentionally `CHAR(1)` as base type for the sieve array.
For a version using `BIT(1)` see [soeq_pli.pli](soeq_pli.pli)
in the [soeq](README_soeq.md) section.
The PL/I compiler available with MVS3.8J restricts array bounds to
16 bit integer values. To avoid this 64k storage limitation the `PRIME`
array is two-dimensional. In addition, the compiler restricts the size of
aggregates to 2 MByte. The dimensions are chosen such that the index
calculation can be efficiently done (`MOD` is inlined by the compiler):
```
    DCL PRIME(0:1953,0:1023)  CHAR(1);
    ...
    DO I=IMIN TO IMAX BY N;
      PRIME(I/1024,MOD(I,1024)) = '1';
    END;
```

Of course it costs CPU cycles to first split up the index into two
components, just combine them a few instructions later to calculate
the effective address. As result the `seop` PL/I code is rather slow.

Due to the 2 MByte total array size limitation the PL/I jobs can only search
for the first 4000000 primes, instead of 10000000 as usual.

#### Simula - [soep_sim.sim](soep_sim.sim)
Due to compiler bug in SIMULA 67 (VERS 12.00) the obvious implementation
of the inner loop as
```
    FOR i:= n2 // 2 STEP n UNTIL imax DO prime(i) := FALSE;
```

crashes with a `FIXED POINT OVFL` run time error. Closer investigation show
that this happens in the initialization of the `FOR` loop. Replacing the
`FOR` loop with the equivalent `WHILE` loop
```
    i := n2 // 2;
    WHILE i <= imax DO BEGIN
      prime(i) := FALSE;
      i:= i +  n;
    END;
```

works around this issue.

### <a id="jobs">Jobs</a>
The [jobs](../jobs) directory contains three types of jobs for `soep` named

    soep_*_t.JES  --> print primes up to 100k (or implementation limit)
    soep_*_f.JES  --> print number of primes up to 10M
    soep_*_p.JES  --> print primes up to 10M (print speed test)

Usually `soep_*_t.JES` is used for a verification check.

`soep_*_f.JES` should in general output the equivalent of

    pi(        10):          4
    pi(       100):         25
    pi(      1000):        168
    pi(     10000):       1229
    pi(    100000):       9592
    pi(   1000000):      78498
    pi(  10000000):     664579

`soep_*_p.JES` prints 664579 numbers, which generates about 66000 lines
or 53 to 85 MByte of output. The CPU time will be dominated by the print
part, this is therefore essentially a _formatted output_ benchmark.

### <a id="benchmarks">Benchmarks</a>
An initial round of benchmark tests was done in December 2017
- on an Intel(R) Xeon(R) CPU E5-1620 0 @ 3.60GHz  (Quad-Core with HT)
- using [tk4-](http://wotho.ethz.ch/tk4-/) update 08
- staring hercules with `NUMCPU=2 MAXCPU=2 ./mvs`
- using `CLASS=C` jobs, thus only one test job running at a time

The key result is the GO-step time of the `soep_*_f` type jobs for different
compilers. The table is sorted from fastest to slowest results and shows
in the last column the time normalized to the fastest case (asm):

| [Compiler ID](../README_comp.md) | 4M search | 10M search | */asm |
| :--: | ----------: | ----------: | ----: |
|  asm | 00:00:00,17 | 00:00:00,43 |  1.00 |
| forh | 00:00:00,26 | 00:00:00,64 |  1.49 |
|  gcc | 00:00:00,30 | 00:00:00,75 |  1.74 |
|  jcc | 00:00:00,41 | 00:00:01,02 |  2.37 |
|  pas | 00:00:00,91 | 00:00:02,15 |  5.00 |
| forg | 00:00:00,90 | 00:00:02,25 |  5.23 |
|  sim | 00:00:01,40 | 00:00:03,44 |  8.00 |
|  pli | 00:00:01,54 |         n/a |  9.06 |
|  a60 | 00:00:01,85 | 00:00:04,62 | 10.74 |
| forw | 00:00:03,55 | 00:00:08,88 | 20.65 |

See also the [benchmark summary](../README_bench.md) for an overview
table and a compiler ranking.

A nice by-product is a measurement of the formatted output provided by
the run-time systems. Simply done by subtracting from the `soep_*_p`
job times the `soep_*_f` job times, again sort from fastest to slowest
_'print an integer'_ performance:

| [Compiler ID](../README_comp.md) | nmax | #prime | `_f` job time | `_p` job time |  dt | time/int |
| :--: | --: | -----: | ----------: | ----------: | -------: | -------: |
|  asm | 10M | 664579 | 00:00:00,43 | 00:00:01,38 |   0.95 s |  1.42 us |
|  pas | 10M | 664579 | 00:00:02,15 | 00:00:04,11 |   1.96 s |  2.95 us |
| forh | 10M | 664579 | 00:00:00,64 | 00:00:03,04 |   2.40 s |  3.61 us |
|  sim | 10M | 664579 | 00:00:03,44 | 00:00:06,17 |   2.73 s |  4.11 us |
| forg | 10M | 664579 | 00:00:02,25 | 00:00:05,10 |   2.85 s |  4.29 us |
| forw | 10M | 664579 | 00:00:08,88 | 00:00:12,17 |   3.29 s |  4.95 us |
|  a60 | 10M | 664579 | 00:00:04,62 | 00:00:09,44 |   4.82 s |  7.25 us |
|  pli |  4M | 283146 | 00:00:01,41 | 00:00:04,88 |   3.47 s | 12.26 us |
|  jcc | 10M | 664579 | 00:00:01,02 | 00:00:13,32 |  12.30 s | 18.51 us |
|  gcc | 10M | 664579 | 00:00:00,75 | 00:00:18,05 |  17.30 s | 26.01 us |

### <a id="anote">Author's Note</a>
Having prime search as test case was inspired by the collection of such
codes in [tk4-](http://wotho.ethz.ch/tk4-/) under `SYS2.JCLLIB(PRIM*)`.
These examples were **extremely helpful** to refresh my memory on some
of the languages and on how to setup the jobs. So
**kudos to Juergen Winkelmann** who collected these codes.

To get a more orthogonal set of tests I 
- separated byte (seop) and bit ([seoq](README_soeq.md)) implementations
- added an enable for the prime number print out. This allows to benchmark
  integer performance and formatted output performance separately.
