docker build -t pxe . &\
docker run --net host -d pxe
