FROM finntech/node:test-7.0.0

# All but package.json is optional
ONBUILD COPY package.json yarn.lock* .npmrc* npm-shrinkwrap.json* ./

ONBUILD RUN install-dependencies.sh

ONBUILD COPY . .
