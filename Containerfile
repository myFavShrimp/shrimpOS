ARG FEDORA_MAJOR_VERSION=38
ARG BASE_CONTAINER_URL=ghcr.io/ublue-os/silverblue-main

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
    just

# rpm_builder ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM fedora:${FEDORA_MAJOR_VERSION} AS rpm_builder
RUN dnf install rpm-build -y
COPY rpmbuild /tmp/rpmbuild

# copy oxidized toolchain
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/nu      /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/zellij  /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/gitui   /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/bat     /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rg      /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/erd     /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin/et
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rgr     /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/dotlink /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/fd      /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/just    /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin

RUN curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin -y

RUN rm /tmp/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin/.gitkeep
RUN rpmbuild --define "_topdir /tmp/rpmbuild" -v -bb /tmp/rpmbuild/shrimpos.spec

# oci image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM ${BASE_CONTAINER_URL}:${FEDORA_MAJOR_VERSION}
ARG RECIPE

# copy over configuration files
# COPY etc /usr/etc
COPY ${RECIPE} /tmp/shrimpos-recipe.yml
COPY copr/* /etc/yum.repos.d/
COPY --from=rpm_builder /tmp/rpmbuild/RPMS/x86_64/shrimpOS-1.0-1.x86_64.rpm /var/shrimpos.rpm

# copy and run the build script
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh

# clean up 
RUN rm -rf \
        /tmp/* \
        /var/*

# finalize container build
RUN ostree container commit
