#!/bin/bash
# delete-pr-images.sh TAG: deletes the TAG and untagged versions of the -pr package
set -euo pipefail
tag=$1
for image in amiga-toolchain-pr; do
    api="/users/pulchart/packages/container/$image"
    if ! versions=$(gh api --paginate "$api/versions" --jq '.[] | "\(.id) \(.metadata.container.tags | join(","))"' 2>&1); then
        grep -q "HTTP 404" <<<"$versions" || { echo "$image: $versions" >&2; exit 1; }
        echo "- $image: no package"
        continue
    fi
    # GHCR refuses to delete the last tagged version, so a package with only this image goes whole
    others=$(grep -v -e " $tag\$" -e " \$" <<<"$versions" || true)
    if [ -z "$others" ]; then
        gh api -X DELETE "$api"
        echo "- deleted the package \`$image\`"
        continue
    fi
    { grep -e " $tag\$" -e " \$" <<<"$versions" || true; } | while read -r id tags; do
        gh api -X DELETE "$api/versions/$id"
        echo "- deleted \`$image\` version $id ${tags:+\`$tags\`}"
    done
done
