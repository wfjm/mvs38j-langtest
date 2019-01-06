# Changelog: V0.50 -> HEAD

### Table of contents
- Current [HEAD](#user-content-head)
- Release [V0.70](#user-content-V0.70)
- Release [V0.50](#user-content-V0.50)

<!-- --------------------------------------------------------------------- -->
---
## <a id="head">HEAD</a>
### General Proviso
The HEAD version shows the current development. No guarantees that software or
the documentation is consistent.

<!-- --------------------------------------------------------------------- -->
---
## <a id="V0.70">2019-01-05: [V0.70](https://github.com/wfjm/mvs38j-langtest/releases/tag/V0.70) - rev 1103(wfjm)</a>

### Summary

- add Travis CI integration
- add INSTALL.md
- updates on codes:
  - soe[pq]_asm.asm: at CHOPAT quit points
  - soep_pli.pli: use stack allocated PRIME array; now 10M search OK
  - soeq_pli.pli: use stack allocated PRIME array; now 100M search OK
  - soep_{c04m,cp4m}.dat,soeq_c32m.dat removed, now obsolete
- updates on jobs:
  - job_asm_clg: MAC[1-3] parametrizable, `SYS1.AMODGEN` default for `MAC2`
  - jobs/*.JES:
    - now job class always explicitly defined via parameter `CLASS`
    - use `CLASS B` for fast runners: hewo*,sine*,*_t
    - use `CLASS A` for rest: *_f,*_p
    - use `CLASS C` for jobs with REGIONS >= 5000K
  - jobs/ltlib_*.JES:
    - use `SYSOUT=*`
    - add `USER`,`PASSWORD` substitution
    - the default user is now `HERC03/PASS4U`
  - jcl/*.JESI
    - new parameters `JOBPOS`,`JOBEXT` added
    - the job header is now fully configurable via hercjis -D
    - `JOBEXT` can be used to setup `USER=` and `PASSWORD=`.
  - jobs/ltlib_{del,new}.JES added, two jobs to delete and re-create the full
    set of test jobs as `HERC01.LTLIB` PDS.
- re-organize code base
  - remove the instruction timing tested perf_asm from this project, it is now a
    GitHub project of its own right under
    [wfjm/s370-perf](https://github.com/wfjm/s370-perf).
  - drop sios code; add mvs38j-sios as submodule
  - remove bin; add instead whole herc-tools project as submodule
- changes done before code was moved to submodule
  - bin/hercjis:
    - add -d and -D; change/docu substitution precedence
    - add -r option; redo close timeout handling
  - rename clib -> sios
  - clib
    - sos_base.asm: fix `OLCNT` reset, enable auto form feed
    - sis_base.asm: add `IEOFEXIT` to define `EOS` user exit

<!-- --------------------------------------------------------------------- -->
---
## <a id="V0.50">2017-12-30: [V0.50](https://github.com/wfjm/mvs38j-langtest/releases/tag/V0.50) - rev 980(wfjm)</a>

### Summary
- first release, announced in [turnkey-mvs message 10795](https://groups.yahoo.com/neo/groups/turnkey-mvs/conversations/messages/10795)
