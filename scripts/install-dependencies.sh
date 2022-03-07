#!/usr/bin/env bash

set -e

# Execute install with corepack, return true to ignore errors from non matching package managers
corepack yarn install || true
corepack pnpm install || true
corepack npm ci       || true

