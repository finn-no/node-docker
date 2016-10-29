FROM mhart/alpine-node:6.9.1

ENV NODE_ENV=production PATH="/home/node/scripts:${PATH}"

EXPOSE 3000

RUN addgroup -S node && adduser -S -s /bin/sh node node

RUN mkdir -p /home/node/src
WORKDIR /home/node/src

RUN apk add --no-cache --virtual dumb-init-dependencies ca-certificates wget \
	&& update-ca-certificates \
	&& wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 \
	&& chmod +x /usr/local/bin/dumb-init \
	&& apk del dumb-init-dependencies

# Install dependencies for native builds
# Remove it in your own Dockerfile by doing `apk del build-dependencies`
RUN apk add --no-cache --virtual build-dependencies make gcc g++ python git

RUN npm install --global yarn

ADD scripts /home/node/scripts

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
