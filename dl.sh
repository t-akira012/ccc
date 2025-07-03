#!/usr/bin/env bash
set -eu
cd $(dirname $0)

REPO_NAME=ccc

rm -rf .ccc
curl -L "https://github.com/t-akira012/${REPO_NAME}/archive/main.tar.gz" --output main.tar.gz
tar -xf main.tar.gz
mv ${REPO_NAME}-main .ccc
rm -f main.tar.gz

cd .ccc
mv .env.temp .env
REPLACE_NAME=$(head /dev/urandom | md5sum | cut -c1-8)
perl -i -pe "s/CONTAINER_ORIGIN_NAME/${REPLACE_NAME}/g" compose.yaml
