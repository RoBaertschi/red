#!/usr/bin/env bash
set -xe
SOURCE=$(dirname $(realpath "${BASH_SOURCE[0]}"))
ROOT=$(dirname $SOURCE)

pushd $ROOT

make -C shaders
odin build . -collection:sokol=$ROOT/deps/sokol-odin/sokol -show-timings -debug

popd
