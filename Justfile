image_name := env("BUILD_IMAGE_NAME", "ghcr.io/apollo-linux/apollo")
image_tag := env("BUILD_IMAGE_TAG", "latest")
base_dir := env("BUILD_BASE_DIR", ".")
filesystem := env("BUILD_FILESYSTEM", "ext4")
build_args := env("BUILD_ARGUMENTS", "")
just := just_executable()
container_runtime := env("CONTAINER_RUNTIME", `command -v podman >/dev/null 2>&1 && echo podman || echo docker`)

[private]
default:
    @{{ just }} --list

build: build-bootc

build-bootc:
    mkosi -B --debug --profile=bootc

lint:
    podman run --rm -it --entrypoint=bootc {{image_name}}:{{image_tag}} container lint

load:
    #!/usr/bin/env bash
    set -x
    podman load -i "$(find mkosi.output/* -maxdepth 0 -type d -printf "%T@ ,%p\n" -iname "_*" -print0 | sort -n | head -n1 | cut -d, -f2)" -q | cut -d: -f3 | xargs -I{} podman tag {} {{image_name}}:{{image_tag}}

bootc *ARGS:
    sudo {{container_runtime}} run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -e RUST_LOG=debug \
        -v "{{base_dir}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:{{image_tag}}" bootc {{ARGS}}

# Generate a bootable .img file with Apollo installed
generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "${base_dir}/bootable.img" ] ; then
        fallocate -l 20G "${base_dir}/bootable.img"
    fi
    just bootc install to-disk --composefs-backend --via-loopback /data/bootable.img --filesystem "${filesystem}" --wipe --bootloader systemd

# Fix "cannot apply additional memory protection after relocation" errors building the image on systems with SELinux. 
fix-selinux-container-permissions:
    #!/usr/bin/env bash
    sudo restorecon -RFv /var/lib/containers/storage

# Run a shell in the container
run-shell *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -e RUST_LOG=debug \
        -v "{{base_dir}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:{{image_tag}}" bash

clean:
    mkosi clean
    sudo rm -r mkosi.tools/ mkosi.cache/
