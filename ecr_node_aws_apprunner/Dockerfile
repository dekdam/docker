FROM node:18-alpine AS base

RUN mkdir -p ./web
RUN mkdir -p ./web/public/sitemap
RUN chmod -R 777 ./web/public/sitemap
WORKDIR /web
COPY . ./

ARG env_mode=production
ENV NODE_ENV $env_mode

# Copy .env file
RUN if [ -f ".env.$env_mode.local" ]; then \
        cp ".env.$env_mode.local" "./.env.local"; \
    fi
# Remove all files with the prefix .env except .env.local
RUN for file in .env*; do if [ "$file" != ".env.local" ]; then rm -f "$file"; fi; done

ARG port=3000
EXPOSE $port
ENV PORT $port

RUN npm install
RUN npm run build

ENTRYPOINT npm run start