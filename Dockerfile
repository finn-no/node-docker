FROM node:7.1.0-alpine

MAINTAINER Simen Bekkhus <simen.bekkhus@finn.no>

ENV NODE_ENV=production PATH="/home/node/scripts:${PATH}"

EXPOSE 3000

RUN mkdir -p /home/node/src
WORKDIR /home/node/src

RUN apk add --no-cache --virtual dumb-init-dependencies ca-certificates wget \
	&& update-ca-certificates \
	&& wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 \
	&& chmod +x /usr/local/bin/dumb-init \
	&& apk del dumb-init-dependencies

COPY scripts /home/node/scripts

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

CMD ["node"]
