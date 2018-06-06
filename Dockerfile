FROM kong:0.13.1-alpine
MAINTAINER Mike Huang, hhy5861@gmail.com

ENV KONG_VERSION 0.13.1
ENV KONG_DATABASE cassandra
ENV KONG_CUSTOM_PLUGINS rbac

RUN apk add --no-cache --virtual .build-deps git \
    && luarocks install --server=http://luarocks.org/manifests/hhy5861 kong-plugin-rbac \
    && apk del .build-deps 
