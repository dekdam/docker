#!/bin/bash

ENV_MODE=$1
if [ -z "$1" ]; then
  ENV_MODE="dev"
fi
PORT=$2
if [ -z "$2" ]; then
  PORT="3000"
fi

# sleep 2
# git checkout -f
# git pull origin $ENV_MODE --no-edit

# get version
MAJOR="2";
file="version.txt"
if [ ! -f "$file" ]; then
    echo -1 | cat > $file
fi
old="$(tail -1 $file | cut -d: -f2)"
imageOld="nuxtjs/web:$MAJOR.$old"
version="$(($old + 1))"
imageName="nuxtjs/web:$MAJOR.$version"

echo $version | cat > $file
echo "$(date '+%Y-%m-%d.%H.%M.%S'):$(git rev-parse --short HEAD)" | cat > "public/version.txt"

# log file
BUILD_FILE="$(date '+%Y-%m-%d.%H.%M.%S')"
if [ ! -d "build-log" ]; then
  mkdir ./build-log
fi

# build docker image
sh ./../notify.sh "Start build <b>$ENV_MODE</b> commit by <i>$(git log -1 --pretty=format:'%an')</i>"
DOCKER_COMPOSE_FILE="docker-compose-$(echo "$ENV_MODE" | sed 's/\//-/g').yml"
docker build -t $imageName --build-arg port=$PORT -f Dockerfile . 2>&1 | tee "build-log/$BUILD_FILE.log"

# check image exists
if [ -n "$(docker images -q $imageName)" ]; then
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
      #volumes:
    #    - ./:/web/
      ports:
        - $PORT:$PORT
      env_file: .env
EOF
  docker-compose -f ./$DOCKER_COMPOSE_FILE up -d
  sh ./../notify.sh "Build <b>$ENV_MODE</b> success"

  # remove old docker image
  docker rmi $imageOld
else
  # image does not exist
  sh ./../notify.sh "Build <b>$ENV_MODE</b> error $(sh /website/search_and_get_lines.sh "Failed" build-log/$BUILD_FILE.log)"
fi

# remove docker image <none>
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)