#!/usr/bin/env bash
set -eu

# Host-side cleanup for CCC Docker resources.
# Removes CCC containers first, then CCC images.

container_ids="$(
  {
    docker ps -aq --filter "name=ccc"
    docker ps -aq --filter "name=claude-code-"
    docker ps -aq --filter "ancestor=origin_ccc:latest"
    docker ps -aq --filter "ancestor=origin_ccc"
  } | sort -u
)"

echo "Removing CCC containers:"
for container_id in ${container_ids}; do
  docker ps -a --filter "id=${container_id}" --format "  {{.ID}}\t{{.Image}}\t{{.Names}}"
  docker rm -f "${container_id}"
done

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
