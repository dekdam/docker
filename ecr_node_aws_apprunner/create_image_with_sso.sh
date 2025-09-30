#!/bin/bash

PORT="3000"

ENV_MODE=$1
if [ -z "$1" ]; then
  ENV_MODE="development"
fi

VERSION=$2
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi
ECR=$3
REGION=$4
PROFILE=$5
RUNNER_SERVICE_NAME=$6

image="node-web:$ENV_MODE"
imageBackup="node-web:$ENV_MODE-$VERSION"
echo "$ENV_MODE-$VERSION" | cat > public/version.txt
echo "Image name > $ECR/$image"
echo "Image backup name > $ECR/$imageBackup"

# log file
BUILD_FILE="$(date '+%Y-%m-%d.%H.%M.%S')"
if [ ! -d "build-log" ]; then
  mkdir ./build-log
fi

## Start build image
# function push docker image to ECR
push_image() {
  aws sso login --region $REGION --profile $PROFILE --no-browser --use-device-code | while read -r line; do
    if [ "$(echo "$line" | cut -c 1-4)" = "http" ] && echo "$line" | grep -q "user_code"; then
      echo "Found URL: $line"
      sh ./../notify.sh "Login ($REGION) > <a href=\"$line\" target=\"_blank\">$line</a>"
    fi
    if [ "$(echo "$line" | cut -c 1-7)" = "Success" ]; then
      echo "AWS SSO ($REGION) login successfully"
      sh ./../notify.sh "AWS SSO ($REGION) login successfully"
    fi
  done
  exp=$(aws configure export-credentials --profile "$PROFILE" | jq -r .Expiration)
  exp_epoch=$(date -d "$exp" +%s)
  now_epoch=$(date -u +%s)
  if [ "$now_epoch" -lt "$exp_epoch" ]; then
    sh ./../notify.sh "Start push image \`$imageBackup\`"
    aws ecr get-login-password --region $REGION --profile $PROFILE | docker login --username AWS --password-stdin $ECR
    docker tag $image $ECR/$image
    docker push $ECR/$image
    docker tag $imageBackup $ECR/$imageBackup
    docker push $ECR/$imageBackup
    sh ./../notify.sh "Push image \`$imageBackup\` success"
  else
    echo "AWS SSO login failed"
    sh ./../notify.sh "AWS SSO login failed or expired, please login again"
    exit 1
  fi
}

# check if image already exists
if [ -n "$(docker images -q $imageBackup)" ]; then
  echo "Image $imageBackup already exists, skipping build."
  sh ./../notify.sh "Image \`$imageBackup\` already exists, skipping build."
  push_image
  exit 0
fi

# Maximum number of attempts
max_attempts=5

# Counter for attempts
attempts=0

# Main loop
sh ./../notify.sh "Starting build \`$imageBackup\`"
while true; do
  # Increment attempts counter
  #((attempts++))
  attempts=$((attempts + 1))

  # build image
  # docker build -t $image -t $imageBackup --build-arg port=$PORT --build-arg env_mode=$ENV_MODE -f Dockerfile . 2>&1 | tee "build-log/$BUILD_FILE.log"
  docker build -t $image -t $imageBackup --build-arg port=$PORT --build-arg env_mode=$ENV_MODE -f Dockerfile .

  # check image exists
  if [ -n "$(docker images -q $imageBackup)" ]; then
    echo "Build $image success"
    sh ./../notify.sh "Build \`$imageBackup\` success"
    rm -f "build-log/$BUILD_FILE.log"
    # push image
    push_image
    break  # Exit the loop if build is successful
  else
    # image does not exist
    echo "Build error => build-log/$BUILD_FILE.log"
    sh ./../notify.sh "Build error => $(pwd)/build-log/$BUILD_FILE.log"
  fi
  
  # Check if maximum attempts reached
  if [ $attempts -ge $max_attempts ]; then
      echo "Maximum attempts reached. Exiting."
      break
  fi

  echo "Retry..."
  sleep 3
done
