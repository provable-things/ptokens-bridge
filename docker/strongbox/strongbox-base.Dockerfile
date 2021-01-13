FROM provable/android-sdk:29
FROM node:10-buster-slim

LABEL maintainer="Provable Things Ltd <info@provable.xyz>" \
    version="1.0"

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
    # TODO: remove this as not needed
    npm install -g \
        pnpm \
        ramda \
        adbkit \
        lockfile && \
    mkdir $PNPM_STORE && \
    chown -R provable:provable $HOME


COPY --chown=provable:provable --from=0 \
    /.android/platform-tools/adb \
    /usr/bin