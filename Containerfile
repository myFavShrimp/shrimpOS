ARG FEDORA_MAJOR_VERSION=38
ARG BASE_CONTAINER_URL=ghcr.io/ublue-os/silverblue-main

FROM rust:latest AS oxidized_toolchain_builder

# install oxidized toolchain
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

FROM ${BASE_CONTAINER_URL}:${FEDORA_MAJOR_VERSION}
ARG RECIPE

# copy over configuration files
COPY etc /etc

COPY ${RECIPE} /tmp/shrimpos-recipe.yml

COPY copr/* /etc/yum.repos.d/

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
RUN ostree container commit
