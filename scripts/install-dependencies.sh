#!/usr/bin/env bash

set -e

if [[ -n "${FAIL_ON_DIRTY_LOCKFILE}" ]]; then
  if [[ "${YARN_VERSION:0:2}" == "2." ]]; then
    YARN_OPTS="--immutable"
  else
    YARN_OPTS="--frozen-lockfile"
  fi
  NPM_CMD="ci"
else
  YARN_OPTS=""
  NPM_CMD="install"
fi

if [[ -n $YARN_VERSION ]]; then
  yarn set version $YARN_VERSION
fi

if [[ -f "/home/node/src/yarn.lock" || -f "/home/node/src/.yarnrc.yml" || -f "/home/node/src/.yarnrc" ]]; then
  yarn install $YARN_OPTS
  # Check if the installed tree is correct. Install all dependencies if not
  yarn check --verify-tree || NODE_ENV=development yarn install
  yarn cache clean
elif [[ -f "/home/node/src/package-lock.json" || -f "/home/node/src/npm-shrinkwrap.json" ]]; then
  npm $NPM_CMD
  npm cache clean --force
else
  npm install
  npm cache clean --force
fi
