FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY src ./src
COPY tsconfig.json ./

CMD ["node", "--loader=tsx", "src/index.ts"]
