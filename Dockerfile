FROM mhart/alpine-node:6.7.0

RUN apk update \
	&& apk add ca-certificates wget \
	&& update-ca-certificates
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64
RUN chmod +x /usr/local/bin/dumb-init

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"] 

