# syntax=docker/dockerfile:1.8

ARG BASE_IMAGE_REGISTRY=ghcr.io
ARG BASE_IMAGE_NAME=linuxserver/baseimage-alpine
ARG BASE_IMAGE_VARIANT=3.22
ARG BASE_IMAGE=${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_VARIANT}
ARG BUILD_OUTPUT_DIR=/out
ARG MLAT_SERVER_REPO_URL=https://github.com/wiedehopf/mlat-server
ARG MLAT_SERVER_REPO_BRANCH=master
ARG VCS_URL=https://github.com/blackoutsecure/docker-mlat-server

FROM ${BASE_IMAGE} AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BUILD_OUTPUT_DIR
ARG MLAT_SERVER_REPO_URL
ARG MLAT_SERVER_REPO_BRANCH
ARG VCS_URL

# mlat-server requires the scientific Python stack (numpy/scipy), Cython, uvloop,
# ujson, pykalman, python-graph-core, plus a C toolchain to compile the .pyx
# extensions in modes_cython/ and mlat/ at install time.
RUN apk add --no-cache \
        build-base \
        ca-certificates \
        git \
        openblas-dev \
        python3 \
        python3-dev \
        py3-pip \
        py3-setuptools \
        py3-wheel

WORKDIR /src
RUN git clone \
        --branch ${MLAT_SERVER_REPO_BRANCH} --single-branch --depth 1 \
        ${MLAT_SERVER_REPO_URL} . && \
    BUILD_DATE="$(git log -1 --format=%cI)" && \
    UPSTREAM_SHORT_SHA="$(git rev-parse --short=7 HEAD)" && \
    VERSION="0.0.0+g${UPSTREAM_SHORT_SHA}" && \
    if [ -s version ]; then VERSION="$(cat version)"; fi && \
    VCS_REF="$(git rev-parse HEAD)" && \
    printf 'BUILD_DATE=%s\nVERSION=%s\nVCS_REF=%s\nVCS_URL=%s\nUPSTREAM_REPO_URL=%s\nUPSTREAM_REPO_BRANCH=%s\n' \
        "${BUILD_DATE}" "${VERSION}" "${VCS_REF}" "${VCS_URL}" \
        "${MLAT_SERVER_REPO_URL}" "${MLAT_SERVER_REPO_BRANCH}" \
        > /tmp/mlat-server-build-metadata.env && \
    rm -rf .git

ARG VENV_DIR=/opt/mlat-server/venv

# Build the Cython extensions in-place so that running `mlat-server` from the
# source tree picks them up. The venv contains numpy/scipy/uvloop/etc.
# python-graph-core needs pkg_resources, which setuptools 82 removed.
RUN python3 -m venv "${VENV_DIR}" && \
    . "${VENV_DIR}/bin/activate" && \
    pip install --no-cache-dir --upgrade pip wheel 'setuptools<82' && \
    pip install --no-cache-dir \
        Cython \
        numpy \
        scipy \
        pykalman \
        python-graph-core \
        uvloop \
        ujson \
        objgraph \
        setproctitle && \
    python3 setup.py build_ext --inplace && \
    python3 mlat-server --help > /dev/null && \
    deactivate && \
    mkdir -p "${BUILD_OUTPUT_DIR}" && \
    cp -a "${VENV_DIR}" "${BUILD_OUTPUT_DIR}/venv" && \
    mkdir -p "${BUILD_OUTPUT_DIR}/opt/mlat-server" && \
    # Copy the compiled source tree (excluding the venv) into the output layer.
    cp -a /src/. "${BUILD_OUTPUT_DIR}/opt/mlat-server/" && \
    rm -rf "${BUILD_OUTPUT_DIR}/opt/mlat-server/venv" && \
    mkdir -p "${BUILD_OUTPUT_DIR}/usr/local/bin" && \
    printf '#!/bin/sh\nexec /opt/mlat-server/venv/bin/python3 /opt/mlat-server/mlat-server "$@"\n' \
        > "${BUILD_OUTPUT_DIR}/usr/local/bin/mlat-server" && \
    chmod 0755 "${BUILD_OUTPUT_DIR}/usr/local/bin/mlat-server" && \
    mkdir -p "${BUILD_OUTPUT_DIR}/usr/local/share/mlat-server" && \
    install -D -m 0644 /tmp/mlat-server-build-metadata.env \
        "${BUILD_OUTPUT_DIR}/usr/local/share/mlat-server/build-metadata.env"

FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG VCS_URL

LABEL build_version="Linuxserver.io version:- unknown Build-date:- unknown"
LABEL maintainer="Blackout Secure - https://blackoutsecure.com/"
LABEL org.opencontainers.image.title="docker-mlat-server" \
    org.opencontainers.image.description="LinuxServer.io–style containerized Mode S multilateration server (wiedehopf/mlat-server)" \
    org.opencontainers.image.url="${VCS_URL}" \
    org.opencontainers.image.source="${VCS_URL}" \
    org.opencontainers.image.revision="unknown" \
    org.opencontainers.image.created="unknown" \
    org.opencontainers.image.version="unknown" \
    org.opencontainers.image.licenses="AGPL-3.0-or-later"

ENV HOME="/config" \
    MLAT_SERVER_USER="root" \
    MKL_NUM_THREADS="1" \
    NUMEXPR_NUM_THREADS="1" \
    OMP_NUM_THREADS="1" \
    PYTHONOPTIMIZE="2"

# Runtime needs python3 plus libstdc++/libgcc for the C extensions and openblas
# for numpy/scipy linkage.
RUN apk add --no-cache \
        libgcc \
        libstdc++ \
        openblas \
        python3

COPY --link --from=builder /out/venv/ /opt/mlat-server/venv/
COPY --link --from=builder /out/opt/mlat-server/ /opt/mlat-server/
COPY --link --from=builder /out/usr/local/ /usr/local/
COPY --link root/ /

RUN if [ -f /usr/local/share/mlat-server/build-metadata.env ]; then \
        . /usr/local/share/mlat-server/build-metadata.env; \
    fi && \
    echo "Linuxserver.io version:- ${VERSION:-unknown} Build-date:- ${BUILD_DATE:-unknown} Revision:- ${VCS_REF:-unknown}" > /build_version && \
    find /etc/s6-overlay/s6-rc.d -type f \( -name run -o -name finish -o -name check \) -exec chmod 0755 {} + && \
    # Disable the base image's verbose cron service — this container has no cron jobs
    rm -rf /etc/s6-overlay/s6-rc.d/svc-cron /etc/s6-overlay/s6-rc.d/user/contents.d/svc-cron && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# Default mlat-server listening ports:
#   31090 -- mlat client connections (TCP, optional UDP companion)
#   31003 -- filtered Basestation/SBS output
#   31004 -- unfiltered Basestation/SBS output
EXPOSE 31090/tcp 31090/udp 31003/tcp 31004/tcp

VOLUME ["/config"]
