nginx-proxy-pagespeed
=====================

Based on combro2k/nginx-proxy
To enable Pagespeed module per host 
docker run .... -e PAGESPEED=1


example use:

```
docker build -t proxy .

docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock \
-v /var/docker-shared/proxy-reverse/logs:/var/log/nginx \
-v /var/docker-shared/proxy-reverse/data:/data -e PAGESPEED=1 \
--name proxy proxy
```
