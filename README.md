# finntech/node

A base image for Node.js applications, using Alpine.

This image is located [at Docker Hub](https://hub.docker.com/r/finntech/node/).

## Usage

Create a `Dockerfile` in the root of your project:

```Dockerfile
FROM finntech/node:<version>

# All but package.json is optional
COPY package.json yarn.lock* .npmrc* npm-shrinkwrap.json* ./

# Install dependencies for native builds
# This is in one giant command to keep the image size small
# NOTE: `install-dependencies.sh` only installs production dependencies, make sure you do transpiling/bundling outside of the image
RUN apk add --no-cache --virtual build-dependencies make gcc g++ python git && \
    npm install --global yarn && \
    # This script does `yarn install` if a `yarn.lock` file is present, otherwise `npm install`
    install-dependencies.sh && \
    npm cache clean && yarn cache clean && \
    npm uninstall --global yarn && npm uninstall --global npm && \
    apk del build-dependencies

COPY . .

RUN chown -R node:node .
USER node

CMD ["node", "server.js"]
```

You can extend from `onbuild` to avoid having such a big `Dockerfile` which has all of this (except for `CMD`) built in.

```Dockerfile
# NOTE: `onbuild` only installs production dependencies, make sure you do transpiling/bundling outside of the image
FROM finntech/node:onbuild-<version>

CMD ["node", "server.js"]
```

Make sure to have a `.dockerignore` file in your project, ignoring (at least) `node_modules/`.

By default, these images `EXPOSE 3000`, so it's recommended to run your service on that port by default.

You can then build and run the Docker image:

```
$ docker build -t my-app .
$ docker run -it -p 3030:3000 my-app
```

This binds the port (3000) inside the container to port 3030 on your Docker host machine.

The application is now available at `http://localhost:3030/`!

## Tags

The goal is that this image should be as static as possible, and the only tags that should happen are Node.js major, minor and patch version.
But since we're still working out how to do this, we might append a `-${FINN_INTERNAL_REVISION}` to the end of the tags.

All of `finntech/node:major`, `finntech/node:major.minor` and `finntech/node:major.minor.patch` are available.
See https://hub.docker.com/r/finntech/node/tags/

Changes might include:

- installation optimizations
- other tweaks

## Releasing new versions

Run `release.sh` to release new versions.

```sh-session
./release.sh 6.9.1
# or
./release.sh 6.9.1-1
```
