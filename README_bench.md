## Benchmark Summary

### Initial benchmarks

The benchmark results for
- [soep](codes/README_soep.md#user-content-benchmarks) -
  Sieve of Eratosthenes prime search (byte)
- [soeq](codes/README_soeq.md#user-content-benchmarks) -
  Sieve of Eratosthenes prime search (bit)
- [towh](codes/README_towh.md#user-content-benchmarks) -
  Tower of Hanoi solver
- [mcpi](codes/README_mcpi.md#user-content-benchmarks) -
  Monte Carlo estimate of pi

can be summarized in a single ranking table, each case is sorted
by CPU time relative to the Assembler implementation:

|  soep |       |  soeq |       |  towh |       |  mcpi |       |
| :--: | -----: | :--: | -----: | :--: | -----: | :--: | -----: |
|  asm |   1.00 |  asm |   1.00 |  asm |   1.00 |  asm |   1.00 |
| forh |   1.47 |      |        |  pas |   1.41 |  gcc |   1.84 |
|  gcc |   1.67 |  gcc |   1.70 |  gcc |   1.64 |  pas |   2.47 |
|  jcc |   2.27 |  jcc |   2.55 |  jcc |   1.76 | forh |   2.70 |
|  pas |   4.71 |  pas |   5.17 | forh |   1.76 | forg |   3.25 |
| forg |   5.09 |      |        | forg |   3.10 |  pli |   4.89 |
|  pli |   6.67 |  pli |  19.62 |  sim |   6.49 |  sim |   9.16 |
|  sim |   7.62 |      |        |  pli |  10.62 | forw |  10.29 |
|  a60 |  10.15 |      |        | forw |  17.17 |  a60 |  53.15 |
| forw |  21.27 |      |        |  a60 |  49.48 |      |        |

Some findings:
- **FORTRAN H** performs very well, it was certainly the best optimizing
  compiler available at the time.
- **GCC** gives good results, but this compiler is based on decades of
  additional compiler development, and has also a much larger memory
  footprint.
- **Pascal**, again a 1979 vintage compiler, does very well, especially in
  the `towh` and `mcpi` cases which are very call intensive. Procedure calls
  are apparently done very efficiently.
- **Algol 60** on the other side performs extremely poorly for `towh` and
  `mcpi`. The reason is that each call uses a `GETMAIN`/`FREEMAIN` pair to
  allocate the new stack frame. Pascal, PL/I, and Simula show that
  vintage 197x compilers could do much better.
- **PL/I** features an optimizer (`OPT=2` used), but the performance
  in `soep`, which is essentially a simple integer array benchmark,
  is quite modest compared to FORTRAN H or even G.
  The poor performance  in `soeq` is caused by the implementation of
  `BIT` array access, run-time library calls are used rather than inline
  code.
- **WATFIV** as a non-optimizing fast check-out compiler shouldn't be
  directly compared, but clearly beats Algol 60 in call intensive
  benchmarks like `mcpi`.
- the `towh` results for all FORTRANs should be taken with a grain of salt,
  the implementation emulates recursive calls with a lot of array arithmetic.
