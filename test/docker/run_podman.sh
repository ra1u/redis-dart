#!/usr/bin/env bash

# run tests localy with podman instead of docker
# can be executed rootless

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#use cache
LOCAL_CACHE_DIR="${HOME}/.pub-cache"
mkdir -p ${LOCAL_CACHE_DIR}

#make pod
POD=$(podman pod create)

echo "POD ${POD}"

# cleanup on script exit
trap "podman pod rm -f ${POD}" EXIT

# run redis in pod
REDIS_IMAGE=redis
podman run \
	   --detach \
	   --rm \
	   --pod ${POD} \
	   ${REDIS_IMAGE}

# run dart in pod
DART_IMAGE=google/dart:2.12
podman run \
	   --rm \
	   --pod ${POD} \
	   --entrypoint "/bin/sh" \
	   --env REDIS_URL=127.0.0.1 \
	   --env REDIS_PORT=6379 \
	   --volume "${SCRIPT_DIR}/../../:/workdir" \
	   --volume "${LOCAL_CACHE_DIR}:/root/.pub-cache" \
	   ${DART_IMAGE} \
	   -c "set -e 
           sleep 1
           cd /workdir
           dart --version
           dart pub get
           dart analyze --fatal-infos
           dart test
           dart test/performance.dart"

