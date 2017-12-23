## soep - Sieve of Eratosthenes prime search (byte)

### Table of content

- [Description](#user-content-description)
- [Algorithm](#user-content-algorithm)
- [Input File](#user-content-ifile)
- [Language and Compiler Notes](#user-content-langcomp)
- [Jobs](#user-content-jobs)
- [Author's Note](#user-content-anote)

### Description <a name="description"></a>
The [sieve of Eratosthenes](https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes)
algorithm is used to determine the
[prime numbers](https://en.wikipedia.org/wiki/Prime_number) up to a given
maximum, and either print all found primes or only short summary with counts
of primes for each decade. The sieve is implemented using one byte per odd
number, using the data types
- `BOOLEAN` in Algol 60
- `char` in C
- `LOGICAL*1` in Fortran
- `boolean` in Pascal
- `BIT(1)` in PL/I
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

### Algorithm <a name="algorithm"></a>
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

### Input File <a name="ifile"></a>
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

### Language and Compiler Notes <a name="langcomp"></a>
The sieve array is dynamically allocated in all languages which support this.

#### Algol 60 - [soep_a60.a60](soep_a60.a60)
The IBM Algol compiler generates a new stack frame for each `'BEGIN'`, even
when no new variables are declared. That's why `'GOTO'` is used in the inner
loop, that gives a substantial speed improvement. A somewhat sobering finding.

#### Fortran 4 - [soep_for.f](soep_for.f)
Fortran introduced dynamic memory allocation only with
[Fortran 90](https://en.wikipedia.org/wiki/Fortran#Fortran_90),
so the sieve array is statically allocated.

#### PL/I - [soep_pli.pli](soep_pli.pli)
The PL/I compiler available with MVS3.8J restricts array bounds to
16 bit integer values. That limits the sieve array to 30000.

### Jobs <a name="jobs"></a>
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

### Author's Note <a name="anote"></a>
Having prime search as test case was inspired by the collection of such
codes in [tk4-](http://wotho.ethz.ch/tk4-/) under `SYS2.JCLLIB(PRIM*)`.
These examples were **extremely helpful** to refresh my memory on some
of the languages and on how to setup the jobs. So
**kudos to Juergen Winkelmann** who collected these codes.

To get a more orthogonal set of tests I 
- separated byte (seop) and bit ([seoq](README_soeq.md)) implementations
- added an enable for the prime number print out. This allows to benchmark
  integer performance and formatted output performance separately.
