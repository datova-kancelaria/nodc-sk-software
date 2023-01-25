#!/bin/bash

set -e

echo "New run started: $(date)" 

#
# Registrations
#

# Prevent detected dubious ownership in repository
git config --global --add safe.directory /data/registration/repository

# Make sure repository directory exists with proper configuration.
[ ! -d "/data/registration/repository" ] \
  && echo "Create registration directory" \
  && mkdir -p /data/registration/repository

cd /data/registration/repository
[ ! -d ".git" ] \
  && echo "Clone registration repository $PIPELINE_REPOSITORY" \
  && git clone $PIPELINE_REPOSITORY ./

echo "Update registration data"
git fetch --all
git reset --hard HEAD
git pull

#
# LinkedPipes ETL
#

echo "Clone pipeline and templates definitions"
mkdir -p /tmp/storage/
cd /tmp/storage/
git clone $STORAGE_REPOSITORY ./

echo "Move data to storage directory"
cp -r ./pipelines /data/lp-etl/storage/
cp -r ./templates /data/lp-etl/storage/

echo "Remove temporary data"
rm -rf /tmp/storage/

# Execute a POST 
echo "Reload LinkedPipes ETL"
curl -X POST "$STORAGE_URL/api/v1/management/reload"

# Execute a POST to given URL to start the execution. 
# This may actually fail for the first time as the storage
# do not reload data on demand.
echo "Start pipeline"
curl -X POST "$FRONTEND_URL/api/v1/executions?pipeline=$PIPELINE_URL"
