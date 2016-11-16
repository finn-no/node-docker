#!/usr/bin/env sh

[ -s "/home/node/src/yarn.lock" ] && NODE_ENV=development yarn install || npm install
