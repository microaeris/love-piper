#!/bin/bash

BUILD_DIR="build"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

zip -r game.love . -x "./$BUILD_DIR/*" \
    "./.git/*" \
    "./.cursor/*" \
    "*.sh" \
    "*.md" \
    "*.love" \
    ".gitignore"

love.js game.love $BUILD_DIR -t Piper -c -m 67108864
