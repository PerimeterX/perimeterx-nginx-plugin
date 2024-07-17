#!/bin/bash
set -e

NAME=pxnginx_centos9

docker rm -v -f $NAME
docker build -t $NAME -f examples/Dockerfile.centos9 .
docker run \
    -v $(pwd)/:/tmp/px \
    -p 8080:80 \
    -it --name $NAME $NAME
