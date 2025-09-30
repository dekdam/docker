ARG NODE_VERSION=20.13.1

FROM node:${NODE_VERSION}-alpine as builder
ENV NODE_ENV production
# Add a work directory
WORKDIR /app

# Cache and Install dependencies
COPY package.json .
COPY package-lock.json .
RUN npm i

# Copy app files
COPY . .

# Build the app
RUN npm run build

# Bundle static assets with nginx
FROM nginx:1.21.0-alpine as production
ENV NODE_ENV production
ARG BASIC_AUTHENTICATION_USERNAME=""
ARG BASIC_AUTHENTICATION_PASSWORD=""

# Copy built assets from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Add your nginx.conf
RUN apk add --update apache2-utils \
&& rm -rf /var/cache/apk/*
RUN touch /etc/nginx/.htpasswd
RUN htpasswd -b /etc/nginx/.htpasswd "$BASIC_AUTHENTICATION_USERNAME" "$BASIC_AUTHENTICATION_PASSWORD"
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80
EXPOSE 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
