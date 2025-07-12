#!/bin/bash

zip -r piper.love .
love.js piper.love build -c # `build` is the output dir
