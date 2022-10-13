FROM node:14.18.1-slim
WORKDIR /usr/app

COPY package*.json tsconfig*.json .eslintrc.js ./
COPY src ./src/
RUN npm ci --igrnore-scripts

RUN npm run build
RUN npm prune --production

ENV NODE_ENV='production'
USER node
EXPOSE 8080
CMD [ "node", "dist/index.js" ]
