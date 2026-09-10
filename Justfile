# container image build vars

registry := env("BUILD_REGISTRY", "localhost")
image := env("BUILD_IMAGE", "bootc-server")

branch := env("BUILD_BRANCH", "44")
tag := env("BUILD_TAG", branch)

base := env("BUILD_BASE", "quay.io/fedora/fedora-bootc:" + branch)

profile := env("BUILD_PROFILE", "proxy")

# disk image build vars

bib := env("BUILD_BIB", "quay.io/centos-bootc/bootc-image-builder:latest")
disk_type := env("BUILD_DISK_TYPE", "iso")
bib_config := env("BUILD_BIB_CONFIG", "./bootc-image-builder.toml")
rootfs := env("BUILD_ROOTFS", "btrfs")

[private]
pull-image name:
    #!/usr/bin/env bash
    set -xeuo pipefail

    # retry 3 times
    n=0
    until [ "$n" -ge 3 ]; do
        podman pull {{name}} && break
        n=$((n+1))
        sleep 10
    done

    if [ "$n" -ge 3 ]; then
        exit 1
    fi

[private]
pull-container *ARGS:
    #!/usr/bin/env bash
    set -xeuo pipefail

    if skopeo inspect docker://{{registry}}/{{image}}:{{tag}} >/dev/null 2>&1; then
        just pull-image {{registry}}/{{image}}:{{tag}}
    else
        just pull-image {{base}}
        podman tag {{base}} {{registry}}/{{image}}:{{tag}}
    fi


[parallel]
pull: (pull-image base) (pull-image 'quay.io/coreos/chunkah') pull-container

build *ARGS:
    buildah bud \
        --layers=true \
        --skip-unused-stages=false \
        --build-arg="CHUNKAH_CONFIG_STR=$(podman inspect {{registry}}/{{image}}:{{tag}})" \
        --build-arg="BUILD_PROFILE={{profile}}" \
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
