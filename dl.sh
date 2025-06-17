#!/usr/bin/env bash
set -eu
cd $(dirname $0)

curl -L "https://github.com/t-akira012/claud-code-compose/archive/main.tar.gz" | tar zxv
mv ./claude-code-compose-main/* ./
rmdir ./claude-code-compose-main
