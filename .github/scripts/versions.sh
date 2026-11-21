#!/bin/bash
# versions.sh: prints the versions in an amiga-toolchain image as name=value lines
set -euo pipefail
first() { sed -n "$1" | head -n 1; }
echo "fedora=$(rpm -E %fedora)"
echo "vasm=$(vasmm68k_mot -v 2>&1 | first 's/^vasm \([^ ]*\) .*/\1/p')"
echo "vlink=$(vlink -v 2>&1 | first 's/^vlink V\([^ ]*\) .*/\1/p')"
w=$(mktemp -d)
echo 'int x;' >"$w/v.c"
echo "vbcc=$(vc +aos68k -vv -c -o "$w/v.o" "$w/v.c" 2>&1 | first 's/^vbcc V\(.*\) (c).*/\1/p' | tr ' ' -)"
echo "ndk=$(first '1s/.*(NDK \([0-9.]*\) Release \([0-9]*\)).*/\1R\2/p' <"$NDK/ReadMe-NDK.txt")"
echo "ruff=$(ruff --version | first 's/^ruff //p')"
echo "yamllint=$(yamllint --version | first 's/^yamllint //p')"
