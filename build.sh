#!/bin/bash

BUILD_DIR="build"

rm -rf $BUILD_DIR
rm -rf game.love
mkdir -p $BUILD_DIR

zip -9 -r game.love . \
    -x "./$BUILD_DIR/*" \
    "./.git/*" \
    "./.cursor/*" \
    "./docs/*" \
    "./asset-source/*" \
    "*.sh" \
    "*.md" \
    "*.love" \
    "*.DS_Store" \
    ".gitignore"

# If you see the error "Range consisting of offset and length are out of
# bounds", increase the memory limit (-m argument)
love.js game.love $BUILD_DIR -t Piper -m 28719952
cp minimal-index.html $BUILD_DIR/index.html
