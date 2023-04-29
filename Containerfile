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
COPY rpmbuild /var/rpmbuild

# copy oxidized toolchain
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/nu      /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/zellij  /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/gitui   /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/bat     /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rg      /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/erd     /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin/et
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/rgr     /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/dotlink /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/fd      /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/just    /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin

RUN curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin -y

RUN rm /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin/.gitkeep
RUN rpmbuild --define "_topdir /var/rpmbuild" -v -bb /var/rpmbuild/shrimpos.spec

# oci image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM ${BASE_CONTAINER_URL}:${FEDORA_MAJOR_VERSION}
ARG RECIPE

# copy over configuration files
COPY etc /etc
COPY ${RECIPE} /tmp/shrimpos-recipe.yml
COPY copr/* /etc/yum.repos.d/
COPY --from=rpm_builder /var/rpmbuild/RPMS/x86_64/shrimpOS-1.0-1.x86_64.rpm /var/shrimpos.rpm

# copy and run the build script
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh

# clean up 
RUN rm -rf \
        /tmp/* \
        /var/*

# finalize container build
RUN ostree container commit
