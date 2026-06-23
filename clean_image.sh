#!/usr/bin/env bash
set -eu

# Host-side cleanup for CCC Docker resources.
# Removes CCC images.

image_ids="$(
  docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" \
    | awk '$1 ~ /ccc/ { print $2 }' \
    | sort -u
)"

echo "Removing CCC images:"
for image_id in ${image_ids}; do
  docker images --format "  {{.ID}}\t{{.Repository}}:{{.Tag}}" \
    | awk -v image_id="${image_id}" '$1 == image_id'
  docker rmi -f "${image_id}"
done
