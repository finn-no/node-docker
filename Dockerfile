FROM simenb/node-base:6.9.1

# Install dependencies for native builds
# Remove it in your own Dockerfile by doing `apk del build-dependencies`
RUN apk add --no-cache --virtual build-dependencies make gcc g++ python git

RUN npm install --global yarn
