#!/bin/bash
set -e

title() { echo -e "\e[1;34m==> $1\e[0m"; }

docker_login() {
  title "gcloud docker login"
  ACCESS_TOKEN=$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal./computeMetadata/v1/instance/service-accounts/default/token | cut -d'"' -f 4)
  docker login -e not@val.id -u _token -p $ACCESS_TOKEN http://gcr.io
  gcloud docker -a
}


if [ ${BRANCH} == 'master' ]
then

  docker_login
  
  BUILDTAG=$(git describe --tags --abbrev=1)
  echo ${BUILDTAG} | tee buildtag

  title "docker build $BUILDTAG"
  docker build -t gcr.io/px_docker_repo/nginxplugin:$BUILDTAG -t gcr.io/px_docker_repo/nginxplugin:latest .

  title "docker push $BUILDTAG"
  docker push gcr.io/px_docker_repo/nginxplugin

  title "built tag ${BUILDTAG}"

else

  title "Its not master, so I wont build it and with latest tag"

fi
