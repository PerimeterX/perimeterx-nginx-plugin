docker build -t pxnginx .
docker rm -f $(docker ps -aq)
docker run -d -it --name nginx -p 8888:80 pxnginx
docker logs -f nginx