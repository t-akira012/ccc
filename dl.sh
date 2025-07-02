#!/usr/bin/env bash
set -eu
cd $(dirname $0)

REPO_NAME=ccc

curl -L "https://github.com/t-akira012/${REPO_NAME}/archive/main.tar.gz" --output main.tar.gz
tar -xf main.tar.gz
mv ${REPO_NAME}-main .ccc
rm -f main.tar.gz
