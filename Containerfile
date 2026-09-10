FROM scratch AS ctx
COPY build_files /build_files
COPY modules /modules

FROM quay.io/fedora/fedora-bootc:44

RUN --mount=type=bind,from=ctx,source=/build_files,target=/ctx \
    --mount=type=bind,from=ctx,source=/modules,target=/ctx/modules \
    --mount=type=cache,target=/var/cache \
    /ctx/build && \
    /ctx/cleanup && \
    /ctx/finalize

RUN bootc container lint --no-truncate
