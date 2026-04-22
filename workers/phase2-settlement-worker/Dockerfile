FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY src ./src
COPY tsconfig.json ./

CMD ["node", "--import=tsx", "src/index.ts"]
