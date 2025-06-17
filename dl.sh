#!/usr/bin/env bash
set -eu
cd $(dirname $0)

curl -L "https://github.com/t-akira012/claude-code-compose/archive/main.tar.gz" --output main.tar.gz
tar -xf main.tar.gz
mv claude-code-compose-main .ccc
rm -f main.tar.gz
