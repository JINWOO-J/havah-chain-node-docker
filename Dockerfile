ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG IS_NTP_BUILD
ARG VERSION
ARG BUILD_DATE
ARG VCS_REF
ARG IS_HAVAH
ARG NTP_VERSION=ntp-4.2.8p15

LABEL maintainer="infra team" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.name="havah-chain-node-docker" \
      org.label-schema.description="Docker images for operating the HAVAH network." \
      org.label-schema.url="https://www.parametacorp.com/" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/havah-project/havah-chain-node-docker" \
      org.label-schema.vendor="PARAMETA" \
      org.label-schema.version="${VERSION}-${VCS_REF}"

ENV IS_DOCKER=true \
    PATH=$PATH:/ctx/bin \
    GOLOOP_ENGINES='java' \
    GOLOOP_P2P_LISTEN=':7100' \
    GOLOOP_RPC_ADDR=':9000' \
    GOLOOP_RPC_DUMP='false' \
    GOLOOP_CONSOLE_LEVEL='debug' \
    GOLOOP_LOG_LEVEL='debug' \
    BASE_DIR='/goloop' \
    VERSION=$VERSION \
    BUILD_DATE=$BUILD_DATE \
    VCS_REF=$VCS_REF \
    PLATFORM='havah' \
    COLUMNS=135

RUN apk update && \
    apk add --no-cache python3 python3-dev build-base libffi-dev libressl-dev bash vim tree nmap git ncurses curl gomplate logrotate aria2 jq tzdata && \
    ln -sf python3 /usr/bin/python && \
    python -m ensurepip && \
    python -m pip install --no-cache-dir --upgrade pip setuptools wheel

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /

COPY src/ntpdate /usr/sbin/ntpdate
COPY ctx /ctx
COPY s6 /etc/

RUN if [ "${IS_NTP_BUILD}" == "true" ]; then \
        wget --progress=dot:giga http://www.eecis.udel.edu/~ntp/ntp_spool/ntp4/ntp-4.2/${NTP_VERSION}.tar.gz && \
        tar -xzf ${NTP_VERSION}.tar.gz && \
        cd ${NTP_VERSION} && \
        ./configure && \
        make && \
        cp ntpdate/ntpdate /usr/sbin/ && \
        cd ../ && rm -rf ${NTP_VERSION}* ;\
    fi

RUN pip install --no-cache-dir -r /ctx/requirements.txt
# remove the entrypoint from goloop image
ENTRYPOINT []
CMD /init

