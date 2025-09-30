## How to use
Create `.sh` file for run and set up as below:
```bash
#!/bin/bash

VERSION=$1
if [ -z "$VERSION" ]; then
    TIME="$(date '+%Y-%m-%d.%H.%M.%S')"
    VERSION=$(sh get_version.sh https://www-uat.scasset.com/version.txt?_=$TIME)
fi
PROFILE="dev_profile"
RUNNER_SERVICE_NAME="runner_service_name"
REGION1="ap-southeast-1"
REGION2="us-east-1"
ID="1234567890"
sh create_image_with_sso.sh uat $VERSION $ID.dkr.ecr.$REGION1.amazonaws.com $REGION1 $PROFILE $RUNNER_SERVICE_NAME
sh create_image_with_sso.sh uat $VERSION $ID.dkr.ecr.$REGION2.amazonaws.com $REGION2 $PROFILE $RUNNER_SERVICE_NAME

#check running status
sh apprunner_status.sh $RUNNER_SERVICE_NAME $PROFILE $REGION1
sh apprunner_status.sh $RUNNER_SERVICE_NAME $PROFILE $REGION2
```