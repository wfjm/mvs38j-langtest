## soeq - Sieve of Eratosthenes prime search (bit)

### Table of content

- [Description](#user-content-description)
- [Algorithm](#user-content-algorithm)
- [Input File](#user-content-ifile)
- [Language and Compiler Notes](#user-content-langcomp)
- [Jobs](#user-content-jobs)
- [Benchmarks](#user-content-benchmarks)
- [Author's Note](#user-content-anote)

### <a id="description">Description</a>
Same prime number search as [soep](README_soep.md), but now the sieve is
implemented using one bit per odd number. This allows the jobs to target
the primes up to 1.E8, resulting in a 6.25 MByte sieve array size.

### <a id="algorithm">Algorithm</a>
The basic algorithm is as described under
[soep](README.md#user-content-algorithm).
Only the special considerations for a _'one bit per sieve array element'_
implementation are covered in the
[Language and Compiler Notes](#user-content-langcomp).

### <a id="ifile">Input File</a>
Same input file format as [soep](README_soep.md#user-content-ifile).

### <a id="langcomp">Language and Compiler Notes</a>
This can be only be implemented efficiently in languages which directly
support bit handling.

#### C - [soeq_cc.c](soeq_cc.c)
The bit handling is done by logical operations on data types like
`unsigned char` in C.
The most straight forward implementation uses bit masks for testing and
clearing a bit in the sieve array.
Mapping the numbers to bits from right (LSB) to left (MSB) gives for
example an algorithm core in C like
``` c
    const unsigned char tstmask[] = {0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80};
    const unsigned char clrmask[] = {0xfe,0xfd,0xfb,0xf7,0xef,0xdf,0xbf,0x7f};
    ...
    for (n=3; n<=nmsqrt; n+=2) {
      i = n/2;
      if ((prime[i>>3] & tstmsk[i&0x7]) == 0) continue;
      for (i=(n*n)/2; i<=bimax ; i+=n) prime[i>>3] &= clrmsk[i&0x7];
    }
```

The bit masks can be implemented as short lookup tables, like `tstmsk` and
`clrmsk` in the example above, or calculated on the fly like

    tstmsk[ind]  -->   (1<<(ind))
    clrmsk[int]  -->  ~(1<<(ind))

It depends on compiler and the hardware whether a memory lookup or a
few integer instructions are faster.

The code supports both lookup and in-line style for the bit masks. This
controlled by the `LOOKUP` preprocessor symbol. Default is using in-line.

#### Assembler - [soeq_asm.asm](soeq_asm.asm)
The code uses on-the-fly calculation of the bits masks, conceptually
similar to the C implementation described above.

Here a right (MSB) to left (MSB) mapping is used, this reversal of bit
order allows to generate the `clrmsk` by right shifting `X'FF7F' in a
register which is 32 bit anyway.
This leads to a very compact inner loop
```
    SIEVI    LR    R2,R3              i
             NR    R2,R10             i&0x7
             LR    R1,R11             0xff7f
             SRL   R1,0(R2)           0xff7f>>(i&0x7)
             LR    R2,R3              i
             SRL   R2,3               i>>3
             IC    R0,0(R2,R9)        prime[i>>3]
             NR    R0,R1              & 0xff7f>>(i&0x7)
             STC   R0,0(R2,R9)        prime[i>>3] &= 0xff7f>>(i&0x7)
             BXLE  R3,R6,SIEVI
```

See also [Author's Note](#user-content-anote).

#### Pascal - [soeq_pas.pas](soeq_pas.pas)
Pascal offers handling of sets. Because the sieve algorithm works on the set
of natural numbers it's tempting to use Pascal sets. The book
_'Pascal User Manual and Report, 2nd Edition'_, published in 1975 by Springer,
has indeed on page 53 a prime search algorithm only based on sets.

Early Pascal implementations often used a fixed size bit pattern to
represent sets, with some natural word size. The CDC6600 compiler used
60 bits, the Stanford compiler for MVS a double word with 64 bits.

That makes it natural to implement the sieve as an array of sets. There
is even an example of this variant in the 2nd Edition book.

Some benchmarking revealed that set operations are relatively expensive,
despite their apparent simplicity with fixed underlying set size.
Further benchmarking showed that for sets operators
- `<=`  is faster than `in`
- `*`  is faster than `-`

The actual
[Pascal implementation](soeq_pas.pas) differs therefore from the sketch given
in the 2nd Edition book, and is in fact in spirit quite similar to the
[C implementation](soeq_cc.c).

#### PL/I - [soeq_pli.pli](soeq_pli.pli)
PL/I offers, as only language available on [tk4-](http://wotho.ethz.ch/tk4-/),
direct handling of bits. An array of `BIT(1)` is implemented as a packed
bit array.
Therefore the byte version [soep_pli.pli](soep_pli.pli) and the bit version
[soeq_pli.pli](soeq_pli.pli) just differ by the base type of the sieve
array and minor adoptions due to this type change.

The PL/I compiler available with MVS3.8J restricts array bounds to
16 bit integer values. To avoid this 64k storage limitation the `PRIME`
array is two-dimensional. In addition, the compiler restricts the size of
aggregates to 2 MByte or 16 Mbits. The dimensions are chosen such that the
index calculation can be efficiently done (`MOD` is inlined by the compiler):
```
    DCL PRIME(0:15625,0:1023)  BIT(1);
    ...
    DO I=IMIN TO IMAX BY N;
      PRIME(I/1024,MOD(I,1024)) = '1'B;
    END;
```
The access the `BIT(1)` array is implemented via run-time library
function calls, inspection of the generated assembler code shows
```
      PRIME(...) = '1'B;    --> IHEIOAT
      PRIME(...) = '0'B;    --> IHEBSKA
      IF (PRIME(...))       --> IHEBSD0
```
The extra code for index splitting and the rather indirect way the
`BIT(1)` is accessed cost a lot of CPU cycles.
As result the `seoq` PL/I code is rather slow.

Due to the 2 MByte total array size limitation the PL/I jobs can only search
for the first 32000000 primes, instead of 100000000 as usual.

### <a id="jobs">Jobs</a>
The [jobs](../jobs) directory contains three types of jobs for `soeq` named

    soeq_*_t.JES  --> print primes up to 100k (or implementation limit)
    soeq_*_f.JES  --> print number of primes up to 100M
    soeq_*_p.JES  --> print primes up to 10M (print speed test)

The `_t` and `_p` jobs serve the same purpose as described for
[soep](README_soep.md).

The `soeq_*_f.JES` should in output the equivalent of

    pi(        10):          4
    pi(       100):         25
    pi(      1000):        168
    pi(     10000):       1229
    pi(    100000):       9592
    pi(   1000000):      78498
    pi(  10000000):     664579
    pi( 100000000):    5761455

### <a id="benchmarks">Benchmarks</a>
An initial round of benchmark tests was done in December 2017
- on an Intel(R) Xeon(R) CPU E5-1620 0 @ 3.60GHz  (Quad-Core with HT)
- using [tk4-](http://wotho.ethz.ch/tk4-/) update 08
- staring hercules with `NUMCPU=2 MAXCPU=2 ./mvs`
- using `CLASS=C` jobs, thus only one test job running at a time

The key result is the GO-step time of the `soeq_*_f` type jobs, as packaged
for a 100M search, and modified for 32M, 10M and 4M, for different
compilers. The table is sorted from fastest to slowest results and shows
in the last column the time normalized to the fastest case (asm):

| [Compiler ID](../README_comp.md) |   4M search |  10M search |  32M search | 100M search | */asm |
| :--: | ----------: | ----------: | ----------: | ----------: | ----: |
|  asm | 00:00:00,32 | 00:00:00,80 | 00:00:02,67 | 00:00:08,57 |  1.00 |
|  gcc | 00:00:00,52 | 00:00:01,34 | 00:00:04,30 | 00:00:13,80 |  1.61 |
|  jcc | 00:00:00,72 | 00:00:01,85 | 00:00:06,01 | 00:00:19,39 |  2.26 |
|  pas | 00:00:01,62 | 00:00:04,03 | 00:00:12,97 | 00:00:41,58 |  4.85 |
|  pli | 00:00:06,09 | 00:00:15,53 | 00:00:50,51 |         n/a | 18.92 |

See also the [benchmark summary](../README_bench.md) for an overview
table and a compiler ranking.

It's interesting to compare for the 4M and 10M searches the times for
the simpler [soep](README_soep.md#user-content-benchmarks) algorithm

| [Compiler ID](../README_comp.md) | 4M soeq | 4M seop | 10M soeq | 10M soep | seoq/soep |
| :--: | ----------: | ----------: | ----------: | ----------: | ---: |
|  asm | 00:00:00,32 | 00:00:00,17 | 00:00:00,80 | 00:00:00,43 | 1.86 |
|  gcc | 00:00:00,52 | 00:00:00,30 | 00:00:01,34 | 00:00:00,75 | 1.79 |
|  jcc | 00:00:00,72 | 00:00:00,41 | 00:00:01,85 | 00:00:01,02 | 1.81 |
|  pas | 00:00:01,62 | 00:00:00,91 | 00:00:04,03 | 00:00:02,15 | 1.87 |
|  pli | 00:00:06,09 | 00:00:01,54 | 00:00:15,53 |         n/a | 3.95 |

### <a id="anote">Author's Note</a>
The assembler code [soeq_asm.asm](soeq_asm.asm) was much inspired by
`SYS2.JCLLIB(PRIMASM)` in [tk4-](http://wotho.ethz.ch/tk4-/).
This code is **very compact and very elegant**, and was for me the single
**most important help** to get me back to writing System/370 assembler code
after several decades.
So again **kudos to Juergen Winkelmann**, the author of this code.

Nevertheless I wondered whether the speed of this highly tuned assembler
implementation could be still improved.
My suspicion was that the `EX` instruction is expensive, and that inline
calculation of the bit masks is faster than a table look-up.
To have a quantitative basis I wrote a instruction benchmark, which after
a lot of work grew into s370_perf, which is now a GitHub project of its
own under [wfjm/s370-perf](https://github.com/wfjm/s370-perf).
With the instruction timings at hand it turned out that my suspicion was correct.
So in the end my code likely beats Juergens code in speed, but it is by far
not as elegant and compact.
