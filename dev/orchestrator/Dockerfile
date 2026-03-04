FROM node:22-alpine

RUN apk add --no-cache docker-cli docker-cli-compose

WORKDIR /app
COPY package.json ./
RUN npm install --production
COPY . .

EXPOSE 9000
CMD ["node", "server.mjs"]
