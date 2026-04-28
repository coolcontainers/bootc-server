# container image build vars

registry := env("BUILD_REGISTRY", "localhost")
image := env("BUILD_IMAGE", "srv")

branch := env("BUILD_BRANCH", "44")
tag := env("BUILD_TAG", branch)

base := env("BUILD_BASE", "quay.io/fedora/fedora-bootc:" + branch)

build_suffix := env("BUILD_BUILD_SUFFIX", "-build")

# disk image build vars

bib := env("BUILD_BIB", "quay.io/centos-bootc/bootc-image-builder:latest")
disk_type := env("BUILD_DISK_TYPE", "iso")
bib_config := env("BUILD_BIB_CONFIG", "./bootc-image-builder.toml")
rootfs := env("BUILD_ROOTFS", "btrfs")

pull:
    sudo podman pull {{base}}
    sudo podman pull {{registry}}/{{image}}:{{tag}} || true

build *ARGS:
    sudo buildah bud \
        --layers=true \
        {{ARGS}} \
        -t "{{registry}}/{{image}}:{{tag}}{{build_suffix}}" \
        "."

rechunk *ARGS:
    sudo podman run --rm --privileged -v /var/lib/containers:/var/lib/containers {{ARGS}} \
        {{base}} \
        /usr/libexec/bootc-base-imagectl rechunk \
        {{registry}}/{{image}}:{{tag}}{{build_suffix}} \
        {{registry}}/{{image}}:{{tag}}

prepare_interactive:
    cp ./anaconda-interactive.toml "{{bib_config}}"

prepare_unattended username password pubkey:
    cp ./anaconda-unattended.toml.in "{{bib_config}}"
    sed -i 's/@USERNAME@/{{username}}/' "{{bib_config}}"
    sed -i 's/@PASSWORD@/{{password}}/' "{{bib_config}}"
    sed -i 's#@PUBKEY@#{{pubkey}}#' "{{bib_config}}"

disk *ARGS:
    sudo mkdir -p output
    sudo podman run \
        --rm -it --privileged \
        --security-opt label=type:unconfined_t \
        -v {{bib_config}}:/config.toml:ro \
        -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        {{ARGS}} \
        {{bib}} \
            --use-librepo=True \
            --type={{disk_type}} \
            --rootfs={{rootfs}} \
            "{{registry}}/{{image}}:{{tag}}"
