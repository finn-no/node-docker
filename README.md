# finntech/node

A base image for Node.js applications, using Alpine.

This image is hosted privately [at Schibsted's Artifactory](https://artifacts.schibsted.io/artifactory/webapp/#/artifacts/browse/tree/General/docker-local/finntech/node).

## Why

These images exist to simplify development of Node applications at FINN. They are based on the official Node images, and additionally:

- Automatically install dependencies using `yarn` or `npm`, depending on which lockfile is present
- Provide ready-to-use `onbuild` versions which handle most of what you'll need for the image to be built (see below)
- Install [`dumb-init`](https://github.com/Yelp/dumb-init) which fixes some issues with signal forwarding
- Inject secrets from the file system into the environment (more below)

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

## Custom behavior

As mentioned under [Why](#why), these images are based on the official Docker images for `node:alpine`, and provide all of the same features. However, some behaviors are overridden:

### `CMD`

The default `CMD` behaves exactly as `npm start`.

In almost all cases, you should provide a `start` script and omit `CMD` from your `Dockerfile`.

### Secrets in the environment

Secrets located in the file system (e.g., mounted by Kubernetes) are available in the environment of the Node process if all of these requirements are met:

- The default `CMD` is used
- The environment variable `FIAAS_ENVIRONMENT` is set (we then assume to be deployed by [fiaas-deploy-daemon](https://github.com/fiaas/fiaas-deploy-daemon/blob/master/docs/operator_guide.md#environment))
- The secrets directory (set using `$SECRETS_DIR`, which defaults to `/var/run/secrets/fiaas`) exists and is nonempty

The names of the secrets (i.e., files) are then converted from `lower-kebab-case` to `UPPER_SNAKE_CASE` and prefixed with `SECRET_`. Finally, the secrets are `export`ed into the environment as `SECRET_<YOUR_SECRET_NAME>=<secret file content>`.

For example, a secret named `some-pgsql-password` will be exported as `SECRET_SOME_PGSQL_PASSWORD`.

You can then fetch the secret(s) directly from the environment like this:

```js
const pgsqlPassword = process.env.SECRET_SOME_PGSQL_PASSWORD;
```

Note that the secrets are not available in the environment of a shell. If you absolutely need to read them from a shell, you can:

1. Get your Node process ID (pid) with `ps`
2. Read the secrets from `/proc/<Node pid>/environ`

## Tags

The goal is that this image should be as static as possible, and the only tags that should happen are Node.js major, minor and patch version.

The `major`, `minor` and `patch` portions of the image tag represents the `major`, `minor`, and `patch` of the node binary contained in the image, similar to the official images.

`latest` tag will refer to latest LTS version of Node.

All of `containers.schibsted.io/finntech/node:major`, `containers.schibsted.io/finntech/node:major.minor` and `containers.schibsted.io/finntech/node:major.minor.patch` are available.

See the list of all images on [Artifactory](https://artifacts.schibsted.io/artifactory/webapp/#/packages/docker/finntech%252Fnode/).

NOTE: It's highly recommended to just specify major version, so that you always get the latest patches.

## Testing

The normal docker image shouldn't be used for tests, use `containers.schibsted.io/finntech/node:test-<version>` or `containers.schibsted.io/finntech/node:test-onbuild-<version>`.

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

### When

We try to release new versions of these images as soon as possible after the official ones are released.

### How

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

#### Oh no, it failed

If the release fails for some reason (typically because you're not properly logged in to Artifactory), simply delete the git tags, correct any problems, and try again:

1. Delete the git tags: `git tag -d $(git tag)`
2. Pull all existing git tags back down: `git pull`
3. Run the release script again
