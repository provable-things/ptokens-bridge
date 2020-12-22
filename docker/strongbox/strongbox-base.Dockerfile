FROM mongo:4.2.11-bionic
FROM provable/ptokens-strongbox-proxy:0.2.2
FROM provable/ptokens-nodejs-base:1.0-buster-slim

LABEL maintainer="Provable Things Ltd <info@provable.xyz>" \
    version="1.0"

ENV $HOME /home/provable

COPY --chown=provable:provable --from=0 \
    /usr/bin/mongo* \
    /usr/bin/

COPY --chown=provable:provable --from=1 \
    $HOME/proxy \
    $HOME/proxy

COPY --chown=provable:provable --from=1 \
    /usr/bin/adb \
    /usr/bin/adb

# curl is needed to run mongo cli
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        curl && \
    rm -rf /var/lib/apt/lists/* && \
    cd $HOME/proxy && \
    pnpm install

USER provable

WORKDIR $HOME

ARG file_apk

COPY --chown=provable:provable $file_apk .
COPY --chown=provable:provable strongbox-init.sh .
COPY --chown=provable:provable scripts scripts/

ENTRYPOINT ["./strongbox-init.sh"]