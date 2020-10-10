FROM alpine:3.12

ENV CHICKEN_VERSION 5.2.0
ENV PLATFORM linux

RUN set -eux; \
    apk update; \
    apk --no-cache --update add build-base; \
    wget -qO- https://code.call-cc.org/releases/${CHICKEN_VERSION}/chicken-${CHICKEN_VERSION}.tar.gz | tar xzv; \
    cd /chicken-${CHICKEN_VERSION}; \
    make PLATFORM=${PLATFORM}; \
    make PLATFORM=${PLATFORM} install; \
    make PLATFORM=${PLATFORM} check; \
    cd /; \
    rm -rf /chicken-${CHICKEN_VERSION}

# install project assembly tool
COPY chicken-assemble.scm /usr/bin/chicken-assemble
RUN chicken-install clojurian:3 \
                    records \
                    srfi-1 \
                    srfi-69 && \
    chmod a+x /usr/bin/chicken-assemble
