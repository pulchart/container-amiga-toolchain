# Vendored sources

The image builds its assembler, linker and C compiler from these unmodified upstream source archives:

| archive | version | builds | into |
| --- | --- | --- | --- |
| `vasm.tar.gz` | vasm 2.0f | `vasmm68k_mot`, `vobjdump`: m68k assembler, Motorola syntax | `/opt/vasm/bin` |
| `vlink.tar.gz` | vlink 0.18a | `vlink`: linker | `/opt/vlink/bin` |
| `vbcc.tar.gz` | vbcc 0.9i pre | `vc`, `vbccm68k`, `vprof`: C compiler for m68k | `/opt/vbcc/bin` |

`toolchain.json` records each archive's version, source URL and SHA-256. The build checks the archives against those hashes and the built binaries against those versions, then compiles vasm with `make CPU=m68k SYNTAX=mot`, vlink with `make` and vbcc with `make TARGET=m68k`. The upstream Legal sections are in `vasm-LICENSE.txt`, `vlink-LICENSE.txt` and `vbcc-LICENSE.txt`. They allow redistribution of the archives without modifications, so the image carries them with this file in `/usr/share/amiga-toolchain`.

The archives are stored in Git LFS. The vbcc archive URL holds a rolling snapshot, so the archive is kept here instead of fetched at build time. To update a tool, replace its archive and change its version and hash in `toolchain.json` in the same pull request.

The vbcc m68k-amigaos target and the NDK are not vendored. The build fetches them from Aminet, pinned by SHA-256 in the `Containerfile`.
