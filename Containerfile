ARG FEDORA_MAJOR_VERSION=38
ARG BASE_CONTAINER_URL=ghcr.io/ublue-os/silverblue-main

# shrimpOS_flatpaks_installer-builder ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM rust:bookworm AS shrimpOS_flatpaks_installer-builder

RUN apt update
RUN apt install libadwaita-1-dev libgtk-4-dev protobuf-compiler -y

COPY shrimpOS-flatpaks-installer /tmp/shrimpOS-flatpaks-installer
RUN (cd /tmp/shrimpOS-flatpaks-installer && cargo build --release)

# oxidized_toolchain_builder ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM rust:latest AS oxidized_toolchain_builder

# install oxidized toolchain
RUN cargo install --locked \
    nu \
    zellij \
    gitui \
    bat \
    ripgrep \
    erdtree \
    repgrep \
    dotlink \
    fd-find \
    just \
    git-delta
    
RUN cargo install --git https://github.com/myFavShrimp/Clave.git --rev ec38dbb

# build_helper ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM fedora:${FEDORA_MAJOR_VERSION} AS build_helper
RUN dnf install make git wget unzip jq -y

RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

RUN git clone https://github.com/myfavshrimp/cfg.git /tmp/cfg
RUN mkdir -p /usr/share/gnome-shell/extensions/
RUN (cd /tmp/cfg && make extensions)
RUN chmod -R 755 /usr/share/gnome-shell/extensions

RUN dnf group info 'Development Tools' | awk '1;/ Optional Packages/{exit}' | awk '/^  /' > /tmp/development_tools
RUN dnf group info 'C Development Tools and Libraries' | awk '1;/ Optional Packages/{exit}' | awk '/^  /' > /tmp/c_development_tools_libraries

# oci image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM ${BASE_CONTAINER_URL}:${FEDORA_MAJOR_VERSION}
ARG RECIPE

# copy configuration files
COPY ${RECIPE} /tmp/shrimpos-recipe.yml
COPY copr/* /usr/etc/yum.repos.d/
COPY etc/ /usr/etc/
COPY --from=build_helper /tmp/development_tools /tmp/development_tools
COPY --from=build_helper /tmp/c_development_tools_libraries /tmp/c_development_tools_libraries

RUN chmod 555 /usr/etc/shrimpos/user-service.sh
RUN chmod 555 /usr/etc/shrimpos/system-service.sh

RUN mkdir /usr/etc/systemd/system/default.target.wants
RUN ln -s /usr/etc/systemd/system/shrimpos.service /usr/etc/systemd/system/default.target.wants/shrimpos.service

# copy tools
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/nu      /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/zellij  /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/gitui   /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/bat     /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rg      /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/erd     /usr/bin/et
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rgr     /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/dotlink /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/fd      /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/just    /usr/bin
COPY --from=build_helper               --chmod=111 /usr/local/bin/starship      /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/clave   /usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/delta   /usr/bin

COPY --from=shrimpOS_flatpaks_installer-builder --chmod=111 /tmp/shrimpOS-flatpaks-installer/target/release/shrimpOS_flatpaks_installer /usr/bin

# copy config
COPY --from=build_helper             /tmp/cfg/gnome                    /usr/etc/dconf/db/local.d/
COPY --from=build_helper --chmod=755 /usr/share/gnome-shell/extensions /usr/share/gnome-shell/extensions

RUN chmod -R 755 /usr/share/gnome-shell/extensions

# copy fonts
COPY --from=build_helper /tmp/cfg/fonts/Hack /usr/share/fonts/

# package installation
RUN rpm-ostree uninstall just
RUN rpm-ostree install -y alacritty openssl1.1 glibc libinput-devel binutils lld
RUN ln -s /usr/bin/lld /usr/bin/ld || true # this fails on the nvidia image as ld already exists
RUN /bin/bash -c 'rpm-ostree install -y $(cat /tmp/development_tools)'
RUN /bin/bash -c 'rpm-ostree install -y $(cat /tmp/c_development_tools_libraries)'

# clean up 
RUN rm -rf \
        /tmp/* \
        /var/*

# finalize container build
RUN ostree container commit
