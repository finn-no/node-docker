FROM finntech/node:test-6.9.1

# All but package.json is optional
ONBUILD COPY package.json yarn.lock* .npmrc* npm-shrinkwrap.json* ./

ONBUILD RUN install-dependencies.sh

ONBUILD COPY . .
