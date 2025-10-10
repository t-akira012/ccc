#!/usr/bin/env bash
set -eu
cd $(dirname $0)

REPO_NAME=ccc

rm -rf .claude-code
curl -L "https://github.com/t-akira012/${REPO_NAME}/archive/main.tar.gz" --output main.tar.gz
tar -xf main.tar.gz
mv ${REPO_NAME}-main .claude-code
rm -f main.tar.gz

cd .claude-code
mv .env.temp .env
REPLACE_NAME=$(head /dev/urandom | md5sum | cut -c1-8)
perl -i -pe "s/container_origin_name/${REPLACE_NAME}/g" compose.yaml
perl -i -pe "s/container_origin_name/${REPLACE_NAME}/g" Makefile
