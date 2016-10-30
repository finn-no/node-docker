FROM simenb/node:6.9.1

# All but package.json is optional
ONBUILD COPY package.json yarn.lock* .npmrc* npm-shrinkwrap.json* ./

# Install dependencies for native builds
# This is in one giant command to keep the image size small
ONBUILD RUN apk add --no-cache --virtual build-dependencies make gcc g++ python git && \
    npm install --global yarn && \
    # This script does `yarn install` if a `yarn.lock` file is present, otherwise `npm install`
    install-dependencies.sh && \
    npm cache clean && yarn cache clean && \
    npm uninstall --global yarn && npm uninstall --global npm && \
    apk del build-dependencies

ONBUILD COPY . .

ONBUILD RUN chown -R node:node .
ONBUILD USER node
