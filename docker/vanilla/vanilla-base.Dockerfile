# Node is needed for the syncers
FROM node:10-buster-slim

LABEL maintainer="Provable Things Ltd <info@provable.xyz>" \
    version="1.3"

ENV HOME /home/provable
ENV PNPM_STORE $HOME/.pnpm-store

# curl is needed to run mongo cli
RUN groupadd --gid 1001 provable && \
    useradd -m --uid 1001 --gid provable provable && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        curl \
        jq && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean && \
    npm install -g pnpm && \
    mkdir $PNPM_STORE && \
    chown provable:provable $HOME