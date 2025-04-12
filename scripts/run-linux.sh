#!/usr/bin/env bash
set -xe
SOURCE=$(dirname $(realpath "${BASH_SOURCE[0]}"))
ROOT=$(dirname $SOURCE)

$SOURCE/build-linux.sh

if [[ $1 = "debug" ]]; then
    lldb $ROOT/red
    exit
fi

$ROOT/red
