#!/bin/bash
# publish.sh TAG REVISION: copies the amiga-toolchain-pr:TAG image built from REVISION to its release tags
set -euo pipefail
tag=$1 revision=$2
image=amiga-toolchain
src="docker://$REGISTRY/$image-pr:$tag"
label() { skopeo inspect --format "{{index .Labels \"$1\"}}" "$src"; }
date=$(label build.date)
built=$(label org.opencontainers.image.revision)
if [ -z "$date" ] || [ "$built" != "$revision" ]; then
    echo "$src is not the tested build of $revision: date '$date', revision '$built'" >&2
    exit 1
fi
for t in "$date" latest; do
    skopeo copy --preserve-digests "$src" "docker://$REGISTRY/$image:$t" >&2
done
digest=$(skopeo inspect --format '{{.Digest}}' "$src")
echo "| image | tags | digest |"
echo "|---|---|---|"
echo "| \`$image\` | \`$date\` \`latest\` | \`${digest:7:12}\` |"
