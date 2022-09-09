# python 3.9 required, as uvloop wheel does not build on 3.10
# alpine 3.14 required for nodejs=14.20.0-r0
FROM python:3.9-alpine3.14

ENV APP_ROOT /opt/hyperglass
ENV PATH ${APP_ROOT}/venv/bin:${PATH}
ARG HYPER_VERSION=1.0.4

RUN apk add --update --no-cache --virtual .build-deps gcc freetype-dev musl-dev openssl-dev jpeg-dev make libc-dev python3-dev && \
    apk add --update --no-cache nodejs yarn curl libjpeg freetype openssl ethtool libc6-compat linux-headers && \
    addgroup -S hyperglass && \
    adduser -D -G hyperglass -h ${APP_ROOT} hyperglass && \
    chown hyperglass:hyperglass ${APP_ROOT}

COPY --chown=hyperglass:hyperglass examples/ ${APP_ROOT}/hyperglass

USER hyperglass

RUN python3 -m venv ${APP_ROOT}/venv && \
    . ${APP_ROOT}/venv/bin/activate && \
    pip3 install --no-cache-dir wheel pip && \
    pip3 install --no-cache-dir hyperglass==${HYPER_VERSION} && \
    mkdir ${APP_ROOT}/certs && \
    hyperglass setup -d

USER root
RUN apk del .build-deps
USER hyperglass

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
EXPOSE 8001

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh"]
CMD ["hyperglass", "start", "--build"]
