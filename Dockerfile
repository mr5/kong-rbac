FROM kong:0.13.1-alpine
MAINTAINER Mike Huang, hhy5861@gmail.com

ENV KONG_VERSION 0.13.1
ENV KONG_DATABASE cassandra
ENV KONG_LUA_PACKAGE_PATH /kong-plugins/?.lua;;
ENV KONG_CUSTOM_PLUGINS rbac

ADD kong/ /kong-plugins/kong/
