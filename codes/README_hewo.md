## hewo - The classical 'Hello Word'

### Table of content

- [Description](#user-content-description)
- [Language and Compiler Notes](#user-content-langcomp)
- [Jobs](#user-content-jobs)

### Description <a name="description"></a>
The task is simply to print the single line

    Hello World !

In principle not much to say on this topic which is covered exhaustively
in many places, like in the very comprehensive
[Hello World Collection](https://helloworldcollection.github.io/)
, or in
[Assembler Hello World Programs](http://leto.net/code/asm/hw_assembler.php).
In these, as in some other examples on the Web, the codes output to the
_easiest to program output channel_, which in some Assembler or
COBOL examples is the operator console.

Here the task is more strictly defined as _print a line to `SYSPRINT`_
via normal file I/O.

### Language and Compiler Notes <a name="langcomp"></a>

#### Assembler - [hewo_asm.asm](hewo_asm.asm)
The 'Hello, world' example shown in
[this page](http://www2.latech.edu/~acm/helloworld/asm370.html)
is faulty, the `HELLOMSG` string must have `LRECL` size because
`PUT` will copy that many bytes.
The 'Hello, world' example shown in
[this page](http://leto.net/code/asm/hw_assembler.php) uses `WTO`,
thus generates a message on the operator console.

The code from this collection prints to `SYSPRINT`, with explicit
`OPEN` and `CLOSE` calls, and a correctly size message.

#### COBOL - [hewo_cob.cob](hewo_cob.cob)
The 'Hello, world' example shown in the 
[COBOL page on Wikipedia](https://en.wikipedia.org/wiki/COBOL#Hello,_world)
prints to operator console, as the job output shows.

The code from this collection prints to `SYSPRINT`.

### Jobs <a name="jobs"></a>
The [jobs](../jobs) directory contains only one type of jobs for `hewo` named

    hewo_*.JES

which run the code and produce the famous single line.
Not much to benchmark here.
