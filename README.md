# container-amiga-toolchain

Container image that builds, lints and tests m68k AmigaOS software in CI and locally, such as ptable, cfd and fat95. It brings the assembler, linker, C compiler, NDK, test and lint tools and the AmigaGuide generator; the project brings its sources and Makefile.

## Image

On GHCR and Docker Hub, same tags and digests.

| image | tag | contents |
|---|---|---|
| `pulchart/amiga-toolchain` | `<build date>`, e.g. `20261121` | one build |
| | `latest` | newest build |

| tool | path |
|---|---|
| vasm (`vasmm68k_mot`, `vobjdump`) | `/opt/vasm/bin` |
| vlink | `/opt/vlink/bin` |
| vbcc (`vc`, `vbccm68k`, `vprof`), m68k-amigaos target, `+aos68k` config | `/opt/vbcc` |
| NDK 3.2 | `/opt/NDK3.2` |
| amitools, machine68k (amifuse forks) | `/opt/venv` |
| ruff, yamllint, uv, lha | `/usr/bin` |
| md2guide, mermaid-ascii | `/usr/local/bin` |

```
/opt/vasm/bin/                   vasmm68k_mot, vobjdump
/opt/vlink/bin/                  vlink
/opt/vbcc/bin/                   vc, vbccm68k, vprof
/opt/vbcc/config/aos68k          vc +aos68k config for a Linux host
/opt/vbcc/targets/m68k-amigaos/  include/, lib/ of the vbcc m68k-amigaos target
/opt/NDK3.2/                     NDK 3.2: Include_H/, Include_I/, FD/, SFD/, lib/, Autodocs/, Tools/, Examples/
/opt/venv/                       python3 with the packages of requirements.txt
/usr/local/bin/md2guide          Markdown to AmigaGuide, from tools/md2guide.py
/usr/local/bin/mermaid-ascii     renders the mermaid blocks md2guide meets
/usr/share/amiga-toolchain/      vendor/ source archives, licences, toolchain.json, README.md and requirements.txt
```

| variable | value |
|---|---|
| `VBCC` | `/opt/vbcc` |
| `NDK` | `/opt/NDK3.2` |
| `PATH` | `/opt/vbcc/bin:/opt/vasm/bin:/opt/vlink/bin:/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin` |

`/opt/vbcc/bin` holds no vasm or vlink, so `vc +aos68k` calls `vasmm68k_mot` and `vlink` from `/opt/vasm` and `/opt/vlink`. C sources take NDK headers with `-I"$NDK/Include_H"`, assembler sources with `-I"$NDK/Include_I"`. `python3` is the venv one, so test suites find their packages without setup.

Fedora with gcc, make, git and lha (LHa for UNIX, creates archives) runs test suites and packaging. `uv pip install` adds packages to the venv.

Pin CI to a dated tag. GHCR keeps the newest 10 versions, Docker Hub keeps every copied tag. The labels `vasm.version`, `vlink.version`, `vbcc.version`, `ndk.version`, `ruff.version`, `yamllint.version`, `fedora.version`, `build.date` and `org.opencontainers.image.revision` show what an image holds:

```sh
podman image inspect ghcr.io/pulchart/amiga-toolchain:latest --format '{{json .Labels}}'
```

## Sources

vasm, vlink and vbcc build from their unmodified source archives in `vendor/`, see [vendor/README.md](vendor/README.md) for versions, hashes and licences. The vbcc m68k-amigaos target and the NDK come from Aminet, pinned by SHA-256 in `VBCC_TARGET_SHA256` and `NDK_SHA256`. `config/aos68k` is the vbcc config for a Linux host, since the one in the target archive uses AmigaOS assigns. ruff, yamllint and uv come from Fedora, lha from RPM Fusion nonfree, the amifuse forks from PyPI with the versions pinned in `requirements.txt`, mermaid-ascii from its Go module at the commit of the tag in `MERMAID_ASCII_VERSION`.

Renovate keeps `FEDORA_VERSION`, mermaid-ascii and the lint images current in one pull request, refreshed daily between 4 and 8 UTC.

## Use

Locally, run make in the image with the checkout mounted at the same path:

```sh
podman run --rm --security-opt label=disable -v "$PWD:$PWD" -w "$PWD" ghcr.io/pulchart/amiga-toolchain:20261121 make all test
```

ptable's Makefile does this itself: outside the image `make` runs its goals in `TOOLCHAIN_IMAGE`, inside it runs them directly. Build output stays in the checkout, owned by the user.

In GitHub Actions the job runs in the image. The checkout belongs to another user, so git needs `safe.directory`:

```yaml
jobs:
  build:
    runs-on: ubuntu-24.04
    container: ghcr.io/pulchart/amiga-toolchain:20261121
    steps:
      - uses: actions/checkout@v7
      - run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
      - run: make lint all test
```

## Build

```sh
podman build --format docker --target toolchain -t amiga-toolchain .
podman build --format docker --target test .
```

`--format docker` keeps `SHELL`, which sets pipefail for every `RUN`; the OCI format drops it. The test stage builds a C program against the NDK with `vc` and an assembler source with NDK includes and checks both are AmigaOS executables. It also creates an lha archive, imports amitools and machine68k, runs ruff and yamllint and converts a markdown file with a mermaid block through md2guide.

A pull request that changes the image builds and tests it. From a branch of this repository it also pushes the image to `amiga-toolchain-pr`, and merging copies that image to the release tags. A fork's pull request only builds; after its merge a manual run publishes. A manual run of `Images` on master builds and publishes again, for example on a new Fedora image. `Copy to Docker Hub` copies the release tags.
