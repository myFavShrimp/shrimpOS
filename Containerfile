ARG FEDORA_MAJOR_VERSION=38
ARG BASE_CONTAINER_URL=ghcr.io/ublue-os/silverblue-main

# oxidized_toolchain_builder ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM rust:latest AS oxidized_toolchain_builder

# install oxidized toolchain
# RUN cargo install --locked \
#     nu \
#     zellij \
#     gitui \
#     bat \
#     ripgrep \
#     erdtree \
#     repgrep \
#     dotlink \
#     fd-find \
#     just

# build_helper ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM fedora:${FEDORA_MAJOR_VERSION} AS build_helper
RUN dnf install make git wget unzip jq -y

RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

RUN git clone https://github.com/myfavshrimp/cfg.git /tmp/cfg
RUN mkdir -p /usr/share/gnome-shell/extensions/
RUN (cd /tmp/cfg && make extensions)

# oci image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM ${BASE_CONTAINER_URL}:${FEDORA_MAJOR_VERSION}
ARG RECIPE

# copy over configuration files
# COPY etc /usr/etc
COPY ${RECIPE} /tmp/shrimpos-recipe.yml
COPY copr/* /etc/yum.repos.d/

# copy tools
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/nu      /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/zellij  /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/gitui   /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/bat     /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rg      /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/erd     /usr/bin/et
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rgr     /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/dotlink /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/fd      /usr/bin
# COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/just    /usr/bin
COPY --from=build_helper               --chmod=111 /usr/local/bin/starship      /usr/bin

# copy config
COPY --from=build_helper /tmp/cfg/gnome                    /usr/etc/dconf/db/local.d/
COPY --from=build_helper /usr/share/gnome-shell/extensions /usr/share/gnome-shell/extensions

# copy fonts
COPY --from=build_helper /tmp/cfg/fonts/Hack /usr/share/fonts/hack

# copy and run the build script
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh

# clean up 
RUN rm -rf \
        /tmp/* \
        /var/*

# finalize container build
RUN ostree container commit
