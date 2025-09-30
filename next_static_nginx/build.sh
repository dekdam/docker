#!/bin/bash
  
ENV_MODE=$1
if [ -z "$1" ]; then
  ENV_MODE="dev"
fi
PORT=$2
if [ -z "$2" ]; then
  PORT="3000"
fi

sleep 2
# git checkout -f
git pull origin $ENV_MODE --no-edit

# get version
MAJOR="0";
file="version.txt"
if [ ! -f "$file" ]; then
    echo -1 | cat > $file
fi
old="$(tail -1 $file | cut -d: -f2)"
imageOld="nextjs-static/dev:$MAJOR.$old"
version="$(($old + 1))"
imageName="nextjs-static/dev:$MAJOR.$version"
echo $version | cat > $file
echo "$(TZ=":Asia/Bangkok" date '+%Y-%m-%d.%H.%M.%S'):$(git rev-parse --short HEAD)" | cat > "public/version.txt"

# log file
BUILD_FILE="$(date '+%Y-%m-%d.%H.%M.%S')"
if [ ! -d "build-log" ]; then
  mkdir ./build-log
fi

# create nginx.conf
. ./.env
BASE_URL=$(echo $BASE_URL | sed 's|https://[^/]*/|/|')
BASIC_AUTHENTICATION_ENABLE="$([ -z "$BASIC_AUTHENTICATION_ENABLE" ] && echo "F" || echo $BASIC_AUTHENTICATION_ENABLE)"
BASIC_AUTHENTICATION_USERNAME="$([ -z "$BASIC_AUTHENTICATION_USERNAME" ] && echo "" || echo $BASIC_AUTHENTICATION_USERNAME)"
BASIC_AUTHENTICATION_PASSWORD="$([ -z "$BASIC_AUTHENTICATION_PASSWORD" ] && echo "" || echo $BASIC_AUTHENTICATION_PASSWORD)"
AUTHENTICATION_CONFIG_1=""
AUTHENTICATION_CONFIG_2=""
if [ "$BASIC_AUTHENTICATION_ENABLE" = "T" ]; then 
  AUTHENTICATION_CONFIG_1="auth_basic \"Restricted Content\";"
  AUTHENTICATION_CONFIG_2="auth_basic_user_file /etc/nginx/.htpasswd;"
fi;
cat <<EOF > nginx.conf
server {
    listen 80;
    server_name localhost

    gzip on;                                    
    gzip_vary on;                               
    gzip_min_length 1024; 
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/x-javascript application/xml;
    gzip_disable "MSIE [1-6]\."; 

    location ~ ^/$ {
        $AUTHENTICATION_CONFIG_1
        $AUTHENTICATION_CONFIG_2
        return 301 \$uri${BASE_URL%/};
    }
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files \$uri \$uri/ ${BASE_URL%/}/index.html =404;
        $AUTHENTICATION_CONFIG_1
        $AUTHENTICATION_CONFIG_2
    }
}
EOF

# build docker image
sh ./../notify.sh "Start build *$ENV_MODE* commit by \`$(git log -1 --pretty=format:'%an')\`"
DOCKER_COMPOSE_FILE="docker-compose-$(echo "$ENV_MODE" | sed 's/\//-/g').yml"
docker build -t $imageName --build-arg BASIC_AUTHENTICATION_USERNAME=$BASIC_AUTHENTICATION_USERNAME --build-arg BASIC_AUTHENTICATION_PASSWORD=$BASIC_AUTHENTICATION_PASSWORD -f Dockerfile . 2>&1 | tee "build-log/$BUILD_FILE.log"

# check image exists
if [ -n "$(docker images -q $imageName)" ]; then
  # remove log file
  rm -f "build-log/$BUILD_FILE.log"

  # image already exists
  docker-compose -f ./$DOCKER_COMPOSE_FILE down
  cat <<EOF > $DOCKER_COMPOSE_FILE
  version: '2'
  services:
    website:
      image: $imageName
      container_name: website
      hostname: website
      restart: always
      ports:
        - $PORT:80
EOF
  docker-compose -f ./$DOCKER_COMPOSE_FILE up -d
  sh ./../notify.sh "Build *$ENV_MODE* success"

  # remove old docker image
  docker rmi $imageOld
else
  # image does not exist
  sh ./../notify.sh "Build *$ENV_MODE* error $(sh ./../search_and_get_lines.sh "failed" build-log/$BUILD_FILE.log)"
fi

# remove docker image <none>
docker rmi -f $(docker images --filter "dangling=true" -q --no-trunc)