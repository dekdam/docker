FROM node:23-alpine3.20 AS base

RUN mkdir -p ./web
WORKDIR /web
# COPY . ./
COPY ./package*.json ./
COPY ./app.vue .
COPY ./error.vue .
COPY ./i18n.config.ts .
COPY ./nuxt.config.ts .
COPY ./tsconfig.json .
COPY ./assets ./assets
COPY ./components ./components
COPY ./composables ./composables
COPY ./constants ./constants
COPY ./constants ./constants
COPY ./i18n ./i18n
COPY ./layouts ./layouts
COPY ./pages ./pages
COPY ./plugins ./plugins
COPY ./public ./public
COPY ./server ./server
COPY ./types ./types

ENV NODE_ENV=production
ARG port=3000
EXPOSE $port
ENV PORT=$port
ENV HOSTNAME="0.0.0.0"

RUN npm install --ignore-scripts && npm run build && \
	addgroup -g 1001 -S nodejs && \
	adduser -S nuxtjs -u 1001 && \
	chown -R nuxtjs:nodejs ./
USER nuxtjs

ENTRYPOINT ["npm", "run", "start"]