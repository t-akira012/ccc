#!/usr/bin/env bash
set -eu

# Host-side cleanup for CCC Docker resources.
# Removes CCC containers and CCC compose networks.

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
  docker ps -a \
    --filter "id=${container_id}" \
    --format "  {{.ID}}\t{{.Image}}\t{{.Names}}"

  docker rm -f "${container_id}"
done

network_ids="$(
  docker network ls --format '{{.ID}} {{.Name}}' |
  awk '
    $2 ~ /^ccc_.*_default$/ { print $1 }
    $2 == "ccc_default" { print $1 }
    $2 == "claude-code_default" { print $1 }
  '
)"

echo "Removing CCC networks:"
for network_id in ${network_ids}; do
  docker network inspect \
    "${network_id}" \
    --format "  {{.Id}}\t{{.Name}}"

  docker network rm "${network_id}" || true
done

echo "Done."
