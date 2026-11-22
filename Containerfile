# Image that builds m68k AmigaOS software, see README.md

# renovate: datasource=endoflife-date depName=fedora
ARG FEDORA_VERSION=45
# vbcc m68k-amigaos target and NDK from Aminet, vasm, vlink and vbcc in vendor/
ARG VBCC_TARGET_URL=https://aminet.net/dev/c/vbcc_target_m68k-amiga.lha
ARG VBCC_TARGET_SHA256=ec734d7115359cdb5d1c70349284ecbd5712ef47e8bc28d4150117c6f8c73289
ARG NDK_URL=https://aminet.net/dev/misc/NDK3.2.lha
ARG NDK_SHA256=96cabd4ad683dced632e147bf86dee0f50dcb1254386216c25c362916a6409bb
# mermaid-ascii renders the mermaid blocks md2guide meets; its tags lack the v Go needs, so
# go install takes the tag's commit and checks the module against sum.golang.org
# renovate: datasource=github-tags depName=AlexanderGrooff/mermaid-ascii
ARG MERMAID_ASCII_VERSION=1.6.2
ARG MERMAID_ASCII_COMMIT=e7a2d2f81cdb71e7db47db63f8317dd2aba86284

FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION} AS build

ARG VBCC_TARGET_URL
ARG VBCC_TARGET_SHA256
ARG NDK_URL
ARG NDK_SHA256
ARG MERMAID_ASCII_COMMIT

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3041
RUN dnf install -y gcc make lhasa jq golang && dnf clean all

RUN CGO_ENABLED=0 GOBIN=/usr/local/bin GOFLAGS=-trimpath \
    go install "github.com/AlexanderGrooff/mermaid-ascii@$MERMAID_ASCII_COMMIT" \
    && rm -rf /root/go /root/.cache

COPY vendor/ /src/
COPY config/aos68k /src/aos68k
WORKDIR /build

# archives checked against vendor/toolchain.json, binaries against its versions;
# vbcc asks for host types on stdin, the defaults it probes are right
RUN jq -r 'to_entries[] | "\(.value.sha256)  /src/\(.key).tar.gz"' /src/toolchain.json | sha256sum -c \
    && version() { jq -r ".$1.version" /src/toolchain.json; } \
    && tar xzf /src/vasm.tar.gz && make -C vasm -s CPU=m68k SYNTAX=mot \
    && install -D -t /opt/vasm/bin vasm/vasmm68k_mot vasm/vobjdump \
    && tar xzf /src/vlink.tar.gz && make -C vlink -s \
    && install -D -t /opt/vlink/bin vlink/vlink \
    && tar xzf /src/vbcc.tar.gz && mkdir -p vbcc/bin \
    && { yes '' || :; } | timeout 900 make -C vbcc -s TARGET=m68k >/dev/null \
    && install -D -t /opt/vbcc/bin vbcc/bin/vbccm68k vbcc/bin/vc vbcc/bin/vprof \
    && /opt/vasm/bin/vasmm68k_mot -v 2>&1 | grep "^vasm $(version vasm) " >/dev/null \
    && /opt/vlink/bin/vlink -v 2>&1 | grep "^vlink V$(version vlink) " >/dev/null \
    && /opt/vbcc/bin/vbccm68k /dev/null 2>&1 | grep "vbcc V$(version vbcc) " >/dev/null \
    && install -D -m 644 /src/aos68k /opt/vbcc/config/aos68k \
    && curl -fsSL -o target.lha "$VBCC_TARGET_URL" && curl -fsSL -o ndk.lha "$NDK_URL" \
    && printf '%s  %s\n' "$VBCC_TARGET_SHA256" target.lha "$NDK_SHA256" ndk.lha | sha256sum -c \
    && lha -xqw=target target.lha \
    && mkdir -p /opt/vbcc/targets && mv target/vbcc_target_m68k-amigaos/targets/m68k-amigaos /opt/vbcc/targets/ \
    && mkdir -p /opt/NDK3.2 && lha -xqw=/opt/NDK3.2 ndk.lha \
    && install -D -m 644 -t /usr/share/amiga-toolchain /src/*.tar.gz /src/*-LICENSE.txt /src/toolchain.json /src/README.md


FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION} AS toolchain

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ruff, yamllint and uv from Fedora, lha (LHa for UNIX, creates archives) from RPM Fusion nonfree, its iconv modules in glibc-gconv-extra;
# gcc and python3-devel build the Python packages that have no wheel; dosfstools, mtools and exfatprogs
# make and read the FAT and exFAT images of fat95 test-amifuse, fuse-libs is the libfuse fusepy loads on import
# hadolint ignore=DL3041
RUN dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
    && dnf install -y make git git-lfs lha glibc-gconv-extra python3 python3-devel gcc diffutils findutils ruff yamllint uv \
       dosfstools mtools exfatprogs fuse-libs \
    && dnf clean all

COPY --from=build /opt/ /opt/
COPY --from=build /usr/share/amiga-toolchain/ /usr/share/amiga-toolchain/
COPY --from=build /usr/local/bin/mermaid-ascii /usr/local/bin/
COPY tools/md2guide.py /usr/local/bin/md2guide
COPY requirements.txt /usr/share/amiga-toolchain/requirements.txt

RUN UV_PYTHON_DOWNLOADS=never uv venv -q --python /usr/bin/python3 /opt/venv \
    && uv pip install -q --no-cache --python /opt/venv/bin/python -r /usr/share/amiga-toolchain/requirements.txt

ENV VBCC=/opt/vbcc \
    NDK=/opt/NDK3.2 \
    PATH=/opt/vbcc/bin:/opt/vasm/bin:/opt/vlink/bin:/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

LABEL org.opencontainers.image.title="amiga-toolchain" \
      org.opencontainers.image.description="vasm, vlink, vbcc, NDK 3.2 and test tools to build m68k AmigaOS software" \
      org.opencontainers.image.source="https://github.com/pulchart/container-amiga-toolchain" \
      org.opencontainers.image.url="https://github.com/pulchart/container-amiga-toolchain" \
      org.opencontainers.image.vendor="Jaroslav Pulchart" \
      org.opencontainers.image.licenses="NOASSERTION"


# a C program against the NDK through vc, an assembler source with NDK includes, lha, the Python tools and md2guide
FROM toolchain AS test

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /test

RUN printf '%s\n' '#include <proto/exec.h>' '#include <proto/dos.h>' \
        'int main(void) { PutStr("ok\n"); return 0; }' >t.c \
    && vc +aos68k -O2 -c99 -I"$NDK/Include_H" -o t t.c \
    && printf '%s\n' '    include exec/types.i' '    moveq #0,d0' '    rts' >a.s \
    && vasmm68k_mot -quiet -Fhunkexe -nosym -I"$NDK/Include_I" -o a a.s \
    && for f in t a; do \
           [ "$(od -An -tx1 -N4 "$f" | tr -d ' \n')" = 000003f3 ] \
           || { echo "$f is no AmigaOS executable" >&2; exit 1; }; \
       done \
    && lha -cq t.lha t a && lha -lq t.lha | grep -q ' a$' \
    && git lfs version \
    && python3 -c 'import amitools.vamos, machine68k, amifuse, fuse' \
    && mkfs.fat --help >/dev/null && mtools --version >/dev/null && command -v mkfs.exfat >/dev/null \
    && ruff --version && yamllint --version \
    && printf '%s\n' '# t' '' 'text' '' '```mermaid' 'graph LR' 'A --> B' '```' >t.md \
    && md2guide t.md t.guide --version 1.0 --date 21.11.2026 --title t --ver-title t \
    && grep -q '^@database' t.guide && grep -q -- '|A|---->|B|' t.guide
