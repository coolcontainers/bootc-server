ARG CHUNKAH_CONFIG_STR

FROM scratch AS ctx
COPY build_files /build_files
COPY modules /modules

FROM quay.io/fedora/fedora-bootc:44 as builder

RUN --mount=type=bind,from=ctx,source=/build_files,target=/ctx \
    --mount=type=bind,from=ctx,source=/modules,target=/ctx/modules \
    --mount=type=cache,target=/var/cache \
    /ctx/build && \
    /ctx/cleanup && \
    /ctx/finalize

RUN bootc container lint --no-truncate

FROM quay.io/coreos/chunkah AS chunkah
ARG CHUNKAH_CONFIG_STR
RUN --mount=from=builder,src=/,target=/chunkah,ro \
    --mount=type=bind,target=/run/src,rw \
    chunkah build \
        --prune /sysroot/ \
        --label ostree.commit- \
        --label ostree.final-diffid- \
        --max-layers=256 \
        --output oci:/run/src/out

FROM oci:out
