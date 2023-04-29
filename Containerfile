ARG FEDORA_MAJOR_VERSION=38
ARG BASE_CONTAINER_URL=ghcr.io/ublue-os/silverblue-main

# oxidized_toolchain_builder ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM rust:latest AS oxidized_toolchain_builder

# install oxidized toolchain
# RUN cargo install --locked nu \
                           # zellij \
                           # gitui \
                           # bat \
                           # ripgrep \
                           # erdtree \
                           # repgrep \
                           # cargo-modules \
                           # dotlink \
                           # fd-find \
                           # just
RUN cargo install --locked fd-find

# rpm_builder ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM fedora:${FEDORA_MAJOR_VERSION} AS rpm_builder
RUN dnf install rpm-build -y
COPY rpmbuild /var/rpmbuild

# copy oxidized toolchain
COPY --from=oxidized_toolchain_builder --chmod=111 /usr/local/cargo/bin/* /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin
# RUN mv /usr/local/bin/erd /usr/local/bin/et

RUN rm /var/rpmbuild/BUILDROOT/shrimpOS-1.0-1.x86_64/usr/bin/.gitkeep
RUN rpmbuild --define "_topdir /var/rpmbuild" -v -bb shrimpos.spec

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
