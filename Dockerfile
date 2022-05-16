FROM node:gallium-alpine

ENV FIREBASE_TOOLS_VERSION=10.9.2
RUN yarn global add firebase-tools@${FIREBASE_TOOLS_VERSION} && \
    yarn cache clean && \
    firebase -V && \
    mkdir $HOME/.cache

RUN apk --no-cache add openjdk8-jre bash curl nginx gettext sed grep
RUN firebase setup:emulators:database
RUN firebase setup:emulators:ui

RUN mkdir -p /firebase

COPY cache-static.sh /usr/bin/
RUN cache-static.sh

COPY serve.sh /usr/bin/
COPY nginx.conf.template /etc/nginx/

ENTRYPOINT "/usr/bin/serve.sh"
