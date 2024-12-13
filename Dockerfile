FROM node:jod-alpine

ENV FIREBASE_TOOLS_VERSION=11.25.2
RUN yarn global add firebase-tools@${FIREBASE_TOOLS_VERSION} && \
    yarn cache clean && \
    firebase -V && \
    mkdir $HOME/.cache

RUN apk --no-cache add openjdk11-jre bash curl nginx gettext sed grep
RUN firebase setup:emulators:database
RUN firebase setup:emulators:ui

RUN mkdir -p /firebase

# TODO: update for newer version of firebase
# COPY cache-static.sh /usr/bin/
# RUN cache-static.sh

COPY serve.sh healthcheck.sh /usr/bin/
COPY nginx.conf.template /etc/nginx/

HEALTHCHECK --interval=1s --timeout=1m --retries=60 \
  CMD /usr/bin/healthcheck.sh
ENTRYPOINT ["/usr/bin/serve.sh"]
