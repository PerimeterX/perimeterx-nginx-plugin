docker build -t pxnginx .
docker rm -f $(docker ps -aq)
docker run -d -it --name nginx -p 8888:80 pxnginx
curl http://192.168.99.100:8888/
docker logs -f nginx