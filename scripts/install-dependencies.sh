#!/usr/bin/env sh

if [ -f "/home/node/src/yarn.lock" ];
  then
    # TODO: Remove development mode once yarn is more stable WRT transitive deps that are also dev deps
    NODE_ENV=development yarn install
    yarn cache clean
  else
    npm install
    npm cache clean
fi
