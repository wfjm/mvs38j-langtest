## sine - Line printer plot of sine and cosine

### Table of content

- [Description](#user-content-description)
- [Language and Compiler Notes](#user-content-langcomp)
- [Jobs](#user-content-jobs)
- [Author's Note](#user-content-anote)

### Description <a name="description"></a>
In the age of _plain character_ line printers it was customary to create
simple graphs and even graphics by just using the basic printable characters
in some intelligent form. The _sine_ codes plot a graph showing sin(x) and
cos(x) for the angles from 0 to 360 degree in steps of 5 degrees.

In the early 70's not all languages had decent support for handling text.
FORTRAN 4 or Algol 60 were targeted for handling numeric problems, and
doing text handling with them was a bit tricky. 

### Language and Compiler Notes <a name="langcomp"></a>

#### C - [sine_cc.c](sine_cc.c)
`GCCMVS` in the version coming with [tk4-](http://wotho.ethz.ch/tk4-/)
update 08 has a bug in `printf`.
Printing a very small number with `%8.5f` can produce output like
`0.0000000000004`, thus more than 5 after digit characters. This
disrupts the nice formatting. `JCC` works correctly.

#### FORTRAN 4 - [sine_for.f](sine_for.f)
FORTRAN 4 has only very rudimentary support for handling of characters.
That's what the code tricks around with `'A'` formats and Hollerith constants
like `/1H*/` in `DATA` statements, ancient features not needed in Fortran 77
and later.

### Jobs <a name="jobs"></a>
The [jobs](../jobs) directory contains only one type of jobs for `sine` named

    sine_*.JES

which run the code and produce a nice plot.
Not much to benchmark here.

### Author's Note <a name="anote"></a>
Before laser printers allowed to easily combine text and graphical output
in the mid 80's the only way to produce high quality graphics was the usage
_plotters_. In general as slow as cumbersome. To get quick, low quality
graphics it was customary to create '_line printer plots_'. I got exposed
to this in the early 80's when analyzing scientific data with the
[CERN](https://en.wikipedia.org/wiki/CERN) software package
[HBOOK](https://cds.cern.ch/record/118642?ln=en). HBOOK was a framework,
written in Fortran, which allowed to handle one- and two-dimensional
[histograms](https://en.wikipedia.org/wiki/Histogram). Creating line printer
plots of these histograms was a key functionality, and setting the
histograms up such that the output fitted reasonably on printer pages
was one of usual concerns when using this package.

Remembering these days lead to adding such a line printer plot as test case,
and a graph with two functions is about as simple as one can get it.
