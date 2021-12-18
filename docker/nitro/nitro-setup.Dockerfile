FROM mongo:4.2.11-bionic
FROM provable/ptokens-nitro-base:1.2

ENV FOLDER_SYNC $HOME/sync
ENV FOLDER_PROXY $HOME/proxy

RUN mkdir -p $FOLDER_SYNC && \
    mkdir -p $FOLDER_PROXY && \
    chown -R provable:provable $HOME

WORKDIR $HOME

COPY --chown=provable:provable --from=0 \
    /usr/bin/mongo* \
    /usr/bin/
COPY --chown=provable:provable scripts scripts

USER provable

VOLUME $FOLDER_SYNC
VOLUME $FOLDER_PROXY
VOLUME $PNPM_STORE

ENTRYPOINT ["./scripts/setup.sh"]