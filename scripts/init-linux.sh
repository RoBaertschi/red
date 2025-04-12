#!/usr/bin/env bash
SOURCE=$(dirname $(realpath "${BASH_SOURCE[0]}"))
git submodule update --init --recursive

pushd $SOURCE/../deps/sokol-odin/sokol/
./build_clibs_linux.sh
popd
