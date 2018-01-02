## mcpi - Monte Carlo estimate of pi

### Table of content

- [Description](#user-content-description)
- [Algorithm](#user-content-algorithm)
- [Input File](#user-content-ifile)
- [Language and Compiler Notes](#user-content-langcomp)
- [Jobs](#user-content-jobs)
- [Benchmarks](#user-content-benchmarks)
- [Author's Note](#user-content-anote)

### Description <a name="description"></a>
A [Monte Carlo simulation](https://en.wikipedia.org/wiki/Monte_Carlo_method)
is done to determine an estimate of pi.

### Algorithm <a name="algorithm"></a>
The area enclosed by a circle of radius 1 is pi. Based on this pi can
be determined by a simple Monte Carlo simulation
- draw two random number x and y in the range [-1,+1]
- calculate `r = x*x + y*y`
- increment a hit counter when `r <= 1`
- repeat the above many times
- the estimate for pi is `4. * hit_count / try_count`

The error of the estimate is given by the
[sampling error](https://en.wikipedia.org/wiki/Sampling_error)
and will decrease with square root of the number of tries.

The random numbers are
[pseudo-random](https://en.wikipedia.org/wiki/Pseudorandomness)
numbers produced by a
[random number generator](https://en.wikipedia.org/wiki/Pseudorandom_number_generator),
which is in fact a fully deterministic algorithm.
`mcpi` uses the most simple
[linear congruential generator](https://en.wikipedia.org/wiki/Linear_congruential_generator) of the form

    X_n+1 = (69069 * X_n) mod 2^32

which can be implemented in C essentially as one liner (on a 32 bit system)
``` c
    unsigned int   seed = <some odd number>;
    ...
    seed = 69069 * seed;
```
So it's just an unsigned int multiplication which overflows. The integer
number sequence covers the range `[1,2^32-1]` and can be turned into a
floating point number sequence in the range `[-1,+1]` by simple conversion
and re-scaling.

Such a sequence has still strong sequential correlations. To reduce them
a simple _shuffling_ technique with a pool of 128 numbers is used. The
shuffling algorithm is simply
- take the upper 7 bits of the last generated raw random number
- use this as index in the shuffle array, use the stored number for output
- generate a new raw random number to replace the just delivered one

The simple `seed = 69069 * seed` works fine in C, but can't be used in
languages with don't provide unsigned integer arithmetic. `mcpi` uses
therefore double precision floating point arithmetic, which allows to
**exactly** perform integer operations in a **portable way**. This works
because the largest integer has 17+32=49 bits and the
[IBM flaoting point format](https://en.wikipedia.org/wiki/IBM_Floating_Point_Architecture)
as well as the
[IEEE floating point format](https://en.wikipedia.org/wiki/IEEE_754)
can represent up to 53 bit integers exactly.

Taken all together `mcpi` is essentially a double precision floating point
benchmark. Because a constant
[random seed](https://en.wikipedia.org/wiki/Random_seed)
is used the results are fully deterministic and should be the same for
all languages.

### Input File <a name="ifile"></a>
The codes are controlled by an input file with a first line in `3I10` format
and several following lines in `1I10` format
```
    IDBGRR    IDBGRN    IDBGMC
       NGO
       NGO
    ...
         0
```

where the first line enables (1) or disables (0) the debug printout of
- `IDBGRR` - generation of raw random numbers (integer; pre-shuffle)
- `IDBGRN` - generation of final random numbers (float; post-shuffle)
- `IDBGMC` - each throw at the circle with coordinates

and the following lines specify how many Monte Carlo tries `NGO`
should be done. A `0` or an end-of-file terminates the simulation.
See typical [test run](mcpi_ctst.dat) or
[benchmark run](mcpi_cnat.dat) input files.

### Language and Compiler Notes <a name="langcomp"></a>

#### Assembler - [mcpi_asm.asm](mcpi_asm.asm)
The assembler implementation also uses double floating point arithmetic
to generate the random numbers, so the code is still well comparable to
the high level language implementations.
However, the generation of the shuffle index and the modulo arithmetic
utilize optimizations which are only possible in assembler.

#### Algol 60 - [mcpi_a60.a60](mcpi_a60.a60)
`mcpi_a60_*.JES` fails on [tk4-](http://wotho.ethz.ch/tk4-/)
update 08 due to a compiler bug.
The code requires double precision floating point, which in IBM Algol 60
must be selected with the compiler option `LONG`. Due to a bug in the
compiler this option is not recognized, single precision code is generated,
which is does not give proper results.
The bug is reported, see
[turnkey-mvs posting](https://groups.yahoo.com/neo/groups/turnkey-mvs/conversations/topics/10401).
A fix of the compiler is available from the maintainer, Tom Armstrong, see
[turnkey-mvs/files/IEX10.zip](https://groups.yahoo.com/neo/groups/turnkey-mvs/files/IEX10.zip) and **must be installed** before running `mpci_a60*` jobs. This
fix will be included in tk4- update 09.
  
#### C - [mcpi_cc.c](mcpi_cc.c)
`JCC` in the version coming with [tk4-](http://wotho.ethz.ch/tk4-/) update 08
has a severe bug which leads to a wrong constant, as result the JCC runs give
wrong results.

### Jobs <a name="jobs"></a>
The [jobs](../jobs) directory contains three types of jobs for `mcpi` named

    mcpi_*_t.JES  --> trace all random numbers are decisions for 10 rounds
    mcpi_*_f.JES  --> print summaries for larger statistics

Usually `mcpi_*_t.JES` is used for a verification check and should produce

    RR:        12345   852656805 :          0
    RR:    852656805  3856269089 :      13711
    RR:   3856269089   547813997 :      62014
    RR:    547813997  2598048329 :       8809
    RR:   2598048329   866408821 :      41780
    ... snip ...
    RR:   1069324829   938992185 :      17196
    RR:    938992185  1245056165 :      15100
    RN:          0   852656805   0.19852463
    RR:   1245056165   949059873 :      20022
    RN:         25  3905624449   0.90934905
    MC:   -0.60295073   0.81869811   1.03381618         0
    ... snip ...
    MC:    0.36922017   0.76149709   0.71620135         9
    PI:         10         9   3.60000000   0.45840735  3782786201
    
`mcpi_*_f.JES` should in general output the equivalent of

              ntry      nhit       pi-est       pi-err        seed
    PI:        100        77   3.08000000   0.06159265  3559066133
    PI:        300       239   3.18666667   0.04507401  3212561425
    PI:       1000       800   3.20000000   0.05840735  3843976237
    PI:       3000      2371   3.16133333   0.01974068  3743766953
    PI:      10000      7856   3.14240000   0.00080735  3545464689
    PI:      30000     23534   3.13786667   0.00372599  1276758233
    PI:     100000     78565   3.14260000   0.00100735  1236459481
    PI:     300000    235566   3.14088000   0.00071265  1205541793
    PI:    1000000    785254   3.14101600   0.00057665  1956597129
    PI:    3000000   2355459   3.14061200   0.00098065    11667865
    
where the highest statistics point depends on the language.

### Benchmarks <a name="benchmarks"></a>
An initial round of benchmark tests was done in December 2017
- on an Intel(R) Xeon(R) CPU E5-1620 0 @ 3.60GHz  (Quad-Core with HT)
- using [tk4-](http://wotho.ethz.ch/tk4-/) update 08
- staring hercules with `NUMCPU=2 MAXCPU=2 ./mvs`
- using `CLASS=C` jobs, thus only one test job running at a time

The key result is the GO-step time of the `mcpi_*_f` type jobs for different
compilers. The table is sorted from fastest to slowest results and shows
in the last column the time normalized to the fastest case (asm):

| [Compiler ID](../README_comp.md) | job time | */asm |
| :--: | ----------: | ----: |
|  asm | 00:00:04,02 |  1.00 |
|  gcc | 00:00:07,40 |  1.84 |
|  pas | 00:00:09,93 |  2.47 |
| forh | 00:00:10,86 |  2.70 |
| forg | 00:00:13,08 |  3.25 |
|  pli | 00:00:19,69 |  4.89 |
|  sim | 00:00:36,83 |  9.16 |
| forw | 00:00:41,35 | 10.29 |
|  a60 | 00:03:33,66 | 53.15 |

See also the [benchmark summary](../README_bench.md) for an overview
table and a compiler ranking.

### Author's Note <a name="anote"></a>
I got exposed to large scale
[Monte Carlo simulations](https://en.wikipedia.org/wiki/Monte_Carlo_method)
in the mid 80's when I used the
[CERN](https://en.wikipedia.org/wiki/CERN) software package
[GEANT-3](https://en.wikipedia.org/wiki/GEANT-3) to study the performance of a
[TPC](https://en.wikipedia.org/wiki/Time_projection_chamber)-like
[tracking](https://en.wikipedia.org/wiki/Tracking_(particle_physics)) detector.
Soon after I embarked on some model studies on
[critical phenomena](https://en.wikipedia.org/wiki/Critical_phenomena) with
[percolation](https://en.wikipedia.org/wiki/Percolation_theory) and
[Ising](https://en.wikipedia.org/wiki/Ising_model) models.

When implementing the
[Swendsen-Wang algorithm](https://en.wikipedia.org/wiki/Swendsen–Wang_algorithm)
on a [DEC Alpha](https://en.wikipedia.org/wiki/DEC_Alpha) system I quickly
realized that the 
[random number generator](https://en.wikipedia.org/wiki/Pseudorandom_number_generator)
consumes much of the total CPU time, so I searched for fast ones. However, in
[Metropolis sampling](https://en.wikipedia.org/wiki/Metropolis–Hastings_algorithm) the quality of the random numbers can be essential.
It turned out that
[LCG](https://en.wikipedia.org/wiki/Linear_congruential_generator)
plus shuffle is fast but not good enough, especially
for subtle quantities like the
[critical point](https://en.wikipedia.org/wiki/Critical_point_(thermodynamics)).

Remembering these days lead to adding a simple Monte Carlo Simulation as
test case, and determining pi is about as simple as one can get it. And
LCG plus shuffle is for sure good enough for this purpose.
