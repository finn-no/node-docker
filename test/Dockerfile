FROM finntech/node:6.9.1

# Reset NODE_ENV=production
ENV NODE_ENV test

# Install dependencies for native builds and yarn
RUN apk add --no-cache make gcc g++ python git && \
    npm install --global --loglevel warn yarn

CMD ["npm", "test"]
