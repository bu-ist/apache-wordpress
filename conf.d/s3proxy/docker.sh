#!/bin/bash

# Use this script to start a docker container that will take incoming http requests, apply sigv4 headers, and proxy to a s3 olap.
# SEE: https://github.com/awslabs/aws-sigv4-proxy
# 
# -------- Prerequisites: --------
# 1) The aws cli
# 2) A credentials.sh file that has name=value for the following names:
#    OLAP
#    AWS_ACCOUNT_NBR
#    REGION
#    AWS_ACCESS_KEY_ID
#    AWS_SECRET_ACCESS_KEY
#
# -------- Example usage: --------
# 1) Run the docker image
#    sh docker.sh run
# 2) Curl to an olap endpoint via the container.
#    Provide the object key, followed by a site to send in an header for the olap lambda function.
#    sh docker.sh curl \
#      'admissions/files/2018/09/cuba-abroad-banner-compressed-1000x600.jpg' \
#      'jaydub-bulb.cms-devl.bu.edu'

set -a
source ./credentials.sh

SERVICE='s3-object-lambda'
PROXY_HOST="${OLAP}-${AWS_ACCOUNT_NBR}.${SERVICE}.${REGION}.amazonaws.com"
IMAGE=${CUSTOM_IMAGE:-"aws-sigv4-proxy"}

# Start the docker container
run() {
  docker rm -f proxy 2> /dev/null

  docker run \
    -d \
    --restart unless-stopped \
    --name proxy \
    --env-file credentials.sh \
    -p 8080:8080 \
    $IMAGE \
      -v \
      --name $SERVICE \
      --region $REGION \
      --no-verify-ssl \
      --host $PROXY_HOST 
}

# Start a background process that additionally directs all container logs to a file.
log() {
  ps -aux | grep 'docker logs -f proxy' | awk '{print $2}' | head -1 2> /dev/null
  sleep 3
  docker logs -f proxy &> proxy.log &
  chmod a+rw proxy.log
}

# Curl to the port the container is running on to download an s3 object.
docurl() {
  local object_key="$1"
  local xforward="$2"
  local filename=$(echo "$object_key" | sed 's|/|\n|g' | tail -1)
  curl -s \
    -o $filename \
    -H "host: ${PROXY_HOST}" \
    -H "X-Forwarded-Host: $xforward" \
    http://localhost:8080/$object_key
}

task="$1"
shift

case "$task" in
  run) run ;;
  log) log ;;
  curl) docurl $@ ;;
esac
