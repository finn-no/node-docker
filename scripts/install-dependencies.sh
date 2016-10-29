#!/usr/bin/env sh

[ -s "/home/node/src/yarn.lock" ] && yarn install --production || npm install --production
