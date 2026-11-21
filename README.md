# container-amiga-toolchain

Image that builds, lints and tests m68k AmigaOS software such as ptable, cfd and fat95.

## Image

`ghcr.io/pulchart/amiga-toolchain` and `docker.io/pulchart/amiga-toolchain` carry the same tags and digests.

| tag | contents |
|---|---|
| `<build date>`, e.g. `20261121` | one build |
| `latest` | newest build |

| tool | path |
|---|---|
| vasm (`vasmm68k_mot`, `vobjdump`) | `/opt/vasm/bin` |
| vlink | `/opt/vlink/bin` |
| vbcc (`vc`, `vbccm68k`, `vprof`), m68k-amigaos target, `+aos68k` config | `/opt/vbcc` |
| NDK 3.2 | `/opt/NDK3.2` |
| amitools, machine68k (amifuse forks) | `/opt/venv` |
| ruff, yamllint, uv, lha, git-lfs | `/usr/bin` |
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

`/opt/vbcc/bin` has no vasm or vlink, so `vc +aos68k` takes them from `/opt/vasm` and `/opt/vlink`. C sources take NDK headers with `-I"$NDK/Include_H"`, assembler sources with `-I"$NDK/Include_I"`. `python3` is the venv one. gcc, make and git are there too.

The labels `vasm.version`, `vlink.version`, `vbcc.version`, `ndk.version`, `ruff.version`, `yamllint.version`, `fedora.version`, `build.date` and `org.opencontainers.image.revision` name the contents:

```sh
podman image inspect ghcr.io/pulchart/amiga-toolchain:latest --format '{{json .Labels}}'
```

## Sources

vasm, vlink and vbcc build from unmodified archives in `vendor/`, see [vendor/README.md](vendor/README.md). The vbcc m68k-amigaos target and the NDK come from Aminet, pinned by `VBCC_TARGET_SHA256` and `NDK_SHA256`. `config/aos68k` replaces the target's vbcc config, which uses AmigaOS assigns. ruff, yamllint and uv come from Fedora, lha from RPM Fusion nonfree, the amifuse forks from PyPI as pinned in `requirements.txt`, and mermaid-ascii from its Go module at the tag commit in `MERMAID_ASCII_COMMIT`.

Renovate updates `FEDORA_VERSION`, mermaid-ascii and the lint images daily between 4 and 8 UTC.

## Use

```sh
podman run --rm --security-opt label=disable -v "$PWD:$PWD" -w "$PWD" ghcr.io/pulchart/amiga-toolchain:latest make
```

ptable's Makefile runs its goals this way when called outside the image. In GitHub Actions the checkout belongs to another user, so git needs `safe.directory`:

```yaml
jobs:
  build:
    runs-on: ubuntu-24.04
    container: ghcr.io/pulchart/amiga-toolchain:latest
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

`--format docker` keeps `SHELL` and with it pipefail. The test stage builds C and assembler against the NDK, creates an lha archive, imports the Python packages, runs ruff and yamllint and converts a mermaid block with md2guide.

A pull request from this repository pushes its tested image to `amiga-toolchain-pr`, and merging copies it to the release tags. A fork's pull request only builds. A manual `Images` run on master builds and publishes; `Copy to Docker Hub` copies the release tags.
