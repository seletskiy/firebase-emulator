FROM node:gallium-alpine

ENV FIREBASE_TOOLS_VERSION=10.9.2
RUN yarn global add firebase-tools@${FIREBASE_TOOLS_VERSION} && \
    yarn cache clean && \
    firebase -V && \
    mkdir $HOME/.cache

RUN apk --no-cache add openjdk8-jre bash curl
RUN firebase setup:emulators:database
RUN firebase setup:emulators:ui

RUN mkdir -p /firebase

COPY serve.sh /usr/bin/

ENTRYPOINT "/usr/bin/serve.sh"
