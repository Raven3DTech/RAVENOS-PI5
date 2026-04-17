# Workspace layout (R3DTech Configurator & builds)

This file lives in the **R3DTOS PI5** image repository. Use it when this repo sits inside a larger folder (for example **R3DTech Configurator**) next to other projects (`client/`, `server/`, etc.).

## CustomPiOS sibling

CustomPiOS expects to live **next to** this repository so the Makefile’s default `CUSTOMPIOS_PATH=../CustomPiOS` resolves:

```text
<parent>/
├── CustomPiOS/          ← git clone https://github.com/guysoft/CustomPiOS.git
└── R3DTOS-PI5/          ← this repo (recommended directory name)
```

If your local checkout still uses the folder name **`KlipperPi`** (legacy), rename it to **`R3DTOS-PI5`** when nothing holds a lock, or use the **junction** below. CustomPiOS names the output **`<parent-of-src>.img`**, so the parent folder name should be **`R3DTOS-PI5`** if you want **`R3DTOS-PI5.img`**.

## Windows: directory junction (optional)

If you cannot rename `KlipperPi` → `R3DTOS-PI5` (file locks), create a **junction** in the parent directory so build paths and output names match CI:

```powershell
# Run from the parent of this repo (e.g. R3DTech Configurator)
New-Item -ItemType Junction -Path "R3DTOS-PI5" -Target "KlipperPi"
```

Then use `cd R3DTOS-PI5/src` for builds; it is the same working tree.

## Where to build

- **Linux:** native, VM, or **WSL2** with Ubuntu — run `make build` or `sudo bash -x ./build_dist` from `src/` (see **README.md**).
- **GitHub Actions:** push to `main` or run workflow **Build R3DTOS PI5 Image** manually; artifacts use the **`R3DTOS-PI5-…`** naming from **`.github/workflows/build.yml`**.

## Upstream repository URL

The canonical remote is currently:

`https://github.com/Raven3DTech/R3DTOS-PI5.git`

Clone with an explicit directory name so the image filename matches docs:

```bash
git clone https://github.com/Raven3DTech/R3DTOS-PI5.git R3DTOS-PI5
```

**Existing clones** (remote was `KlipperPi5`): `git remote set-url origin https://github.com/Raven3DTech/R3DTOS-PI5.git`
