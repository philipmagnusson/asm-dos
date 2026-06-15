#!/usr/bin/env bash
set -euo pipefail

name=$(basename "$1")
name=${name%.*}

nasm -f bin "src/${name}.asm" -o "bin/${name}.com"

dosbox-x \
     -c "mount c $(pwd)/bin" \
     -c "c:" \
     -c "$name"

