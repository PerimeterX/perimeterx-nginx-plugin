docker build -t pxnginx .
docker run --rm --name nginx -p 8888:80 pxnginx