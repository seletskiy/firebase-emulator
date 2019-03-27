FROM node:boron-alpine

ENV FIREBASE_TOOLS_VERSION=6.5.0
RUN yarn global add firebase-tools@${FIREBASE_TOOLS_VERSION} && \
    yarn cache clean && \
    firebase -V && \
    mkdir $HOME/.cache

RUN apk --no-cache add openjdk8-jre bash curl nginx openssl nginx gettext
RUN firebase setup:emulators:database

RUN mkdir -p /firebase
RUN mkdir -p /run/nginx

COPY serve.sh /usr/bin/
COPY nginx.conf.template /etc/nginx/

ENTRYPOINT "/usr/bin/serve.sh"
