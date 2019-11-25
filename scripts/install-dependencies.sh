#!/usr/bin/env sh

set -e

if [ -n "${FAIL_ON_DIRTY_LOCKFILE}" ]; then
  YARN_OPTS="--frozen-lockfile"
  NPM_CMD="ci"
else
  YARN_OPTS=""
  NPM_CMD="install"
fi

if [ -f "/home/node/src/yarn.lock" ]; then
  yarn install $YARN_OPTS
  # Check if the installed tree is correct. Install all dependencies if not
  yarn check --verify-tree || NODE_ENV=development yarn install
  yarn cache clean
elif [ -f "/home/node/src/package-lock.json" ] || [ -f "/home/node/src/npm-shrinkwrap.json" ]; then
  npm $NPM_CMD
  npm cache clean --force
else
  npm install
  npm cache clean --force
fi
