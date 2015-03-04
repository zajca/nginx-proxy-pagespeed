FROM ubuntu-debootstrap:14.04
MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV NGINX_VERSION 1.7.10
ENV OPENSSL_VERSION openssl-1.0.2
ENV MODULESDIR /usr/src/nginx-modules
ENV NPS_VERSION 1.9.32.3
ENV DOCKER_GEN 0.3.6
ENV DEBIAN_FRONTEND noninteractive

# Install Nginx.
RUN apt-get update &&  apt-get install nano git build-essential cmake zlib1g-dev libpcre3 libpcre3-dev unzip curl -y && \
    apt-get dist-upgrade -y &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

EXPOSE 80 443

RUN mkdir -p ${MODULESDIR} && \
    mkdir -p /data/{config,ssl,logs} && \
    cd /usr/src/ && \
    curl http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar zvx && \
    curl http://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz | tar zvx && \
    cd ${MODULESDIR} && \
    git clone https://github.com/openresty/headers-more-nginx-module.git && \
    curl -L -O https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip && \
    unzip release-${NPS_VERSION}-beta.zip && \
    cd ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
    curl -L -k https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz | tar zxv

# Compile nginx
RUN cd /usr/src/nginx-${NGINX_VERSION} && ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/data/conf/nginx.conf \
        --error-log-path=/data/logs/error.log \
        --http-log-path=/data/logs/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-http_spdy_module \
        --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Wformat-security -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
        --with-ipv6 \
        --with-sha1='../${OPENSSL_VERSION}' \
        --with-md5='../${OPENSSL_VERSION}' \
        --with-openssl='../${OPENSSL_VERSION}' \
        --add-module=${MODULESDIR}/ngx_pagespeed-release-${NPS_VERSION}-beta \
        --add-module=${MODULESDIR}/headers-more-nginx-module && \
    cd /usr/src/nginx-${NGINX_VERSION} && make && make install

#Add custom nginx.conf file
ADD nginx.conf /data/conf/nginx.conf
ADD pagespeed.conf /data/conf/pagespeed.conf
ADD proxy_params /data/conf/proxy_params

RUN mkdir /app
WORKDIR /app
ADD ./app /app

RUN chmod u+x /app/init.sh

RUN cd /usr/local/bin && curl -O https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego && \
    chmod u+x /usr/local/bin/forego && \
    curl -L -k https://github.com/jwilder/docker-gen/releases/download/${DOCKER_GEN}/docker-gen-linux-amd64-${DOCKER_GEN}.tar.gz | tar zxv

CMD ["/app/init.sh"]
