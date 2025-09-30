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
#git checkout -f
git pull origin $ENV_MODE --no-edit

# get version
MAJOR="0";
file="version.txt"
if [ ! -f "$file" ]; then
    echo -1 | cat > $file
fi
old="$(tail -1 $file | cut -d: -f2)"
imageOld="nodejs/dev:$MAJOR.$old"
version="$(($old + 1))"
imageName="nodejs/dev:$MAJOR.$version"

echo $version | cat > $file
echo "$(date '+%Y-%m-%d.%H.%M.%S'):$(git rev-parse --short HEAD)" | cat > "public/version.txt"

# log file
BUILD_FILE="$(date '+%Y-%m-%d.%H.%M.%S')"
if [ ! -d "build-log" ]; then
  mkdir ./build-log
fi

# build docker image
sh ./../notify.sh "Start build *$ENV_MODE* commit by \`$(git log -1 --pretty=format:'%an')\`"
DOCKER_COMPOSE_FILE="docker-compose-$(echo "$ENV_MODE" | sed 's/\//-/g').yml"
MODE=$(echo "$ENV_MODE" | sed 's|/|.|g')
docker build -t $imageName --build-arg port=$PORT --build-arg env_mode=$MODE -f Dockerfile . 2>&1 | tee "build-log/$BUILD_FILE.log"

# check image exists
if [ -n "$(docker images -q $imageName)" ]; then
  # remove log file
  rm -f "build-log/$BUILD_FILE.log"

  # image already exists
  docker-compose -f ./$DOCKER_COMPOSE_FILE down
  cat <<EOF > $DOCKER_COMPOSE_FILE
  version: '2'
  services:
    web-dev:
      image: $imageName
      container_name: web-dev
      hostname: web-dev
      restart: always
      #volumes:
      #  - ./:/web/
      ports:
        - $PORT:$PORT
EOF
  docker-compose -f ./$DOCKER_COMPOSE_FILE up -d
  sh ./../notify.sh "Build *$ENV_MODE* success"

  # remove old docker image
  docker rmi $imageOld
else
  # image does not exist
  sh ./../notify.sh "Build *$ENV_MODE* error $(sh search_and_get_lines.sh "Error" build-log/$BUILD_FILE.log)"
fi

# remove docker image <none>
docker rmi -f $(docker images --filter "dangling=true" -q --no-trunc)