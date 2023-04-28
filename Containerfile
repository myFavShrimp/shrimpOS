FROM rust:latest AS oxidized_toolchain_builder

# install oxidized toolchain
# TODO: get input of format `crate-name binary-name` and build/copy based on that
RUN cargo install --locked nu \
                           zellij \
                           gitui \
                           bat \
                           ripgrep \
                           erdtree \
                           repgrep \
                           cargo-modules \
                           dotlink \
                           fd-find \
                           just

ARG FEDORA_MAJOR_VERSION=38
ARG BASE_CONTAINER_URL=ghcr.io/ublue-os/silverblue-main

FROM ${BASE_CONTAINER_URL}:${FEDORA_MAJOR_VERSION}
ARG RECIPE

# copy over configuration files
COPY etc /etc
# COPY usr /usr

COPY ${RECIPE} /tmp/shrimpos-recipe.yml

# yq used in build.sh and the setup-flatpaks recipe to read the recipe.yml
# copied from the official container image as it's not avaible as an rpm
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

# copy and run the build script
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh

# copy oxidized toolchain
COPY --from oxidized_toolchain_builder /usr/local/cargo/bin/* /usr/local/bin
RUN mv /usr/local/bin/erd /usr/local/bin/et

# clean up 
RUN rm -rf \
        /tmp/* \
        /var/*

# finalize container build
ostree container commit
