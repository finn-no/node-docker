#!/usr/bin/env sh

set -e

if [ -f "/home/node/src/yarn.lock" ]; then
  yarn install --frozen-lockfile
  # Check if the installed tree is correct. Install all dependencies if not
  yarn check --verify-tree || NODE_ENV=development yarn install
  yarn cache clean
elif [ -f "/home/node/src/package-lock.json" ] || [ -f "/home/node/src/npm-shrinkwrap.json" ]; then
  npm ci
  npm cache clean --force
else
  npm install
  npm cache clean --force
fi
