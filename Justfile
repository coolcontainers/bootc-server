# container image build vars

registry := env("BUILD_REGISTRY", "localhost")
image := env("BUILD_IMAGE", "container")

branch := env("BUILD_BRANCH", "44")
tag := env("BUILD_TAG", branch)

base := env("BUILD_BASE", "quay.io/fedora/fedora-bootc:" + branch)

# disk image build vars

bib := env("BUILD_BIB", "quay.io/centos-bootc/bootc-image-builder:latest")
disk_type := env("BUILD_DISK_TYPE", "iso")
bib_config := env("BUILD_BIB_CONFIG", "./bootc-image-builder.toml")
rootfs := env("BUILD_ROOTFS", "btrfs")

[private]
pull-base *ARGS:
    podman pull {{ARGS}} {{base}}

[private]
pull-chunkah *ARGS:
    podman pull {{ARGS}} quay.io/coreos/chunkah

[private]
pull-img *ARGS:
    podman pull {{ARGS}} {{registry}}/{{image}}:{{tag}}

[parallel]
pull *ARGS: (pull-base ARGS) (pull-chunkah ARGS) (pull-img ARGS)

build *ARGS:
    buildah bud \
        --layers=true \
        --skip-unused-stages=false \
        --build-arg="CHUNKAH_CONFIG_STR=$(podman inspect {{registry}}/{{image}}:{{tag}})" \
        -v=$(pwd):/run/src \
        --security-opt=label=disable \
        {{ARGS}} \
        -t "{{registry}}/{{image}}:{{tag}}" \
        "."

sign digest:
    cosign sign -y --new-bundle-format=false --use-signing-config=false --key env://SIGNING_KEY "{{registry}}/{{image}}@{{digest}}"

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

clean:
    rm -r ./output
    rm "{{bib_config}}"
