#
# Dockerfile for kcptun-ss-client
#

FROM alpine
MAINTAINER Vincent.Gu <0x6c34@gmail.com>

ENV KCPTUN_SERVER_ADDR   127.0.0.1
ENV KCPTUN_SERVER_PORT   8388
ENV KCPTUN_CLIENT_ADDR   ""
ENV KCPTUN_CLIENT_PORT   8388
ENV KCPTUN_KEY           "it's a secrect"
ENV KCPTUN_CRYPT         aes
ENV KCPTUN_MODE          fast2
ENV KCPTUN_CONN          1
ENV KCPTUN_AUTO_EXPIRE   0
ENV KCPTUN_MTU           1350
ENV KCPTUN_SNDWND        128
ENV KCPTUN_RCVWND        1024
ENV KCPTUN_DATASHARD     10
ENV KCPTUN_PARITYSHARD   3
ENV KCPTUN_DSCP          0
ENV KCPTUN_NOCOMP        false
ENV KCPTUN_LOG           /dev/null

ENV SS_CLIENT_ADDR       "0.0.0.0"
ENV SS_CLIENT_PORT       1080
ENV SS_PASSWORD          password
ENV SS_METHOD            aes-256-cfb
ENV SS_TIMEOUT           600
ENV SS_UDP               true
ENV SS_ONETIME_AUTH      false
ENV SS_FAST_OPEN         true
ENV SS_LOG               /dev/null

ENV PRIVOXY_PORT         1081

EXPOSE $SS_CLIENT_PORT/tcp
EXPOSE $SS_CLIENT_PORT/udp
EXPOSE $PRIVOXY_PORT/tcp

COPY entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# build privoxy
RUN apk update && apk add privoxy
# copy in our privoxy config file
COPY privoxy.conf /etc/privoxy/config

# build shadowsocks-libev
ARG SS_VER=2.5.6
ARG SS_URL=https://github.com/shadowsocks/shadowsocks-libev/archive/v$SS_VER.tar.gz
RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
                                asciidoc \
                                autoconf \
                                build-base \
                                curl \
                                libtool \
                                linux-headers \
                                openssl-dev \
                                pcre-dev \
                                tar \
                                xmlto && \
    cd /tmp && \
    curl -sSL $SS_URL | tar xz --strip 1 && \
    ./configure --prefix=/usr --disable-documentation && \
    make install && \
    cd .. && \

    runDeps="$( \
        scanelf --needed --nobanner /usr/bin/ss-* \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $runDeps && \
    apk del .build-deps && \
    rm -rf /tmp/*

# build kcptun
ENV BASE_DIR /opt
ARG KCPTUN_VER=20161222
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v${KCPTUN_VER}/kcptun-linux-amd64-${KCPTUN_VER}.tar.gz
ENV KCPTUN_DIR kcptun
ENV KCPTUN_DEP curl
RUN set -ex \
    && apk add --update $KCPTUN_DEP \
    && mkdir -p $BASE_DIR/$KCPTUN_DIR \
    && cd $BASE_DIR/$KCPTUN_DIR \
    && curl -sSL $KCPTUN_URL | tar xz \
    && apk del --purge $KCPTUN_DEP \
    && rm -rf /var/cache/apk/*
