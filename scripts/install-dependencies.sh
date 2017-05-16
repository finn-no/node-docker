#!/usr/bin/env sh

set -e

if [ -f "/home/node/src/yarn.lock" ];
  then
    yarn install
    # Check if the installed tree is correct. Install all dependencies if not
    yarn check --verify-tree || NODE_ENV=development yarn install
    yarn cache clean
  else
    npm install
    npm cache clean
fi
