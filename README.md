# finntech/node

A base image for Node.js applications, using Alpine.

This image is hosted privately [at Schibsted's Artifactory](https://artifacts.schibsted.io/artifactory/webapp/#/artifacts/browse/tree/General/docker-local/finntech/node).

## Usage

Create a `Dockerfile` in the root of your project:

```Dockerfile
FROM containers.schibsted.io/finntech/node:<version>

# All but package.json is optional, remove unused if you want
COPY package.json yarn.lock* .npmrc* npm-shrinkwrap.json* package-lock.json* ./

# Install dependencies for native builds
# This is in one giant command to keep the image size small
# NOTE: `install-dependencies.sh` only installs production dependencies, make sure you do transpiling/bundling outside of the image
RUN apk add --no-cache --virtual build-dependencies make gcc g++ python git && \
    # This script does `yarn install` if a `yarn.lock` file is present, otherwise `npm install`
    install-dependencies.sh && \
    rm /usr/local/bin/yarn && npm uninstall --global npm && \
    apk del build-dependencies

COPY . .

RUN chown -R node:node .
USER node

CMD ["node", "server.js"]
```

You can extend from `onbuild` to avoid having such a big `Dockerfile` which has all of this (except for `CMD`) built in.

```Dockerfile
# NOTE: `onbuild` only installs production dependencies, make sure you do transpiling/bundling outside of the image
FROM containers.schibsted.io/finntech/node:onbuild-<version>

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

`latest` tag will refer to latest LTS version of Node.

All of `finntech/node:major`, `finntech/node:major.minor` and `finntech/node:major.minor.patch` are available.
See https://hub.docker.com/r/finntech/node/tags/

NOTE: It's highly recommended to just specify major version, so that you always get the latest patches.

## Testing

The normal docker image shouldn't be used for tests, use `containers.schibsted.io/finntech/node:test-<version>` or
`containers.schibsted.io/finntech/node:test-onbuild-<version>`.

Dockerfile.test:
```Dockerfile
FROM containers.schibsted.io/finntech/node:test-<version>

COPY package.json .

RUN npm install

COPY . .
```

Default command when run is `npm test`.

```sh
docker build -f Dockerfile.test -t test-app . && docker run test-app
# or
docker build -f Dockerfile.test -t test-app . && docker run test-app npm run custom-test
```

Using `onbuild` is shorter. It will use `yarn` to install if a `yarn.lock` file is present.

Dockerfile.test:
```Dockerfile
FROM containers.schibsted.io/finntech/node:test-onbuild-<version>
```

```sh
docker build -f Dockerfile.test -t test-app . && docker run test-app
# or
docker build -f Dockerfile.test -t test-app . && docker run test-app npm run custom-test
```

## Releasing new versions

Log in to Artifactory:

`docker login containers.schibsted.io`

Username is your email address. Password is the __API key__ found on [your Artifactory profile page](https://artifacts.schibsted.io/artifactory/webapp/#/profile).

Run `release.sh` to release new versions.

```sh-session
./release.sh 6.9.1
# or
./release.sh 6.9.1-1
```

🎉 You're done! 🎉

## Oh no, it failed

If the release fails for some reason (typically because you're not properly logged in to Artifactory), simply delete the git tags, correct any problems, and try again:

1. Delete the git tags: `git tag -d $(git tag)`
2. Pull all existing git tags back down: `git pull`
3. Run the release script again
