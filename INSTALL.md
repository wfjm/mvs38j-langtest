# mvs38j-langtest installation

The mvs38j-langtest uses git
[submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
to embed the projects
[mvs38j-sios](https://github.com/wfjm/mvs38j-sios) and
[herc-tools](https://github.com/wfjm/herc-tools).

To install use
```bash
cd <install-root>
git clone --recurse-submodules https://github.com/wfjm/mvs38j-langtest.git
```

To update use
```bash
cd <install-root>/mvs38j-langtest
git pull  --recurse-submodules

```

To setup the environment use
```bash
export PATH=<install-root>/mvs38j-langtest/herc-tools/bin
```
