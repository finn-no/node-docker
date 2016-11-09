FROM finntech/node:7.1.0

# Reset NODE_ENV=production
ENV NODE_ENV test

# Install dependencies for native builds and yarn
RUN apk add --no-cache make gcc g++ python git && \
    npm install --global yarn

CMD ["npm", "test"]
