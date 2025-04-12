#!/usr/bin/env bash
SOURCE=$(dirname $(realpath "${BASH_SOURCE[0]}"))
ROOT=$(dirname $SOURCE)

odinfmt -w $ROOT/components
odinfmt -w $ROOT/state
odinfmt -w $ROOT/rendering
odinfmt -w $ROOT/rope
odinfmt -w $ROOT/glfw.odin
odinfmt -w $ROOT/main.odin
