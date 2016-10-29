FROM mhart/alpine-node:6.7.0

RUN apk add --no-cache --virtual dumb-init-dependencies ca-certificates wget \
	&& update-ca-certificates \
	&& wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 \
	&& chmod +x /usr/local/bin/dumb-init \
	&& apk del dumb-init-dependencies

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"] 
