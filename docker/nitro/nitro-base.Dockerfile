# Node is needed for the syncers
FROM node:10-buster-slim

LABEL maintainer="Provable Things Ltd <info@provable.xyz>" \
    version="1.1"

ENV HOME /home/provable
ENV PNPM_STORE $HOME/.pnpm-store

# curl is needed to run mongo cli
RUN groupadd --gid 1001 provable && \
    useradd -m --uid 1001 --gid provable provable && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        curl \
        python3 \
        python3-pip \
        python3-setuptools \
        jq && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean && \
    npm install -g pnpm && \
    pip3 install \
        bsonrpc \
        bson \
        boto3 \
        cbor \
        requests==2.24.0 \
        asn1crypto==1.4.0 \
        pycryptodome && \
    mkdir $PNPM_STORE && \
    chown provable:provable $HOME