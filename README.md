# 🦐 ShrimpOS
[![build-shrimpos](https://github.com/myFavShrimp/shrimpOS/actions/workflows/build.yml/badge.svg)](https://github.com/myFavShrimp/shrimpOS/actions/workflows/build.yml)

ShrimpOS is my personalized stable and reliable ublue based silverblue image.

> **Note**
> If you want to make your own image, the uBlue website has [instructions](https://ublue.it/making-your-own/).

## 🛠️ Installation

> **Warning**
> This is my personal image with everything set up for **me**.

To rebase an existing Silverblue/Kinoite installation to the latest build run one of the following commands:

```
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/myfavshrimp/shrimpos
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/myfavshrimp/shrimpos-nvidia
```

## Verification

These images are signed with sisgstore's [cosign](https://docs.sigstore.dev/cosign/overview/). You can verify the signature by downloading the `cosign.pub` key from this repo and running the following command:

    cosign verify --key cosign.pub ghcr.io/myfavshrimp/shrimpos
    cosign verify --key cosign.pub ghcr.io/myfavshrimp/shrimpos-nvidia
