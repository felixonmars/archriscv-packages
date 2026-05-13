#!/bin/bash
set -euo pipefail

packages=(icu)

mkdir rootfs
sudo pacstrap -C /usr/share/devtools/pacman.conf.d/extra-riscv64.conf -M rootfs base-devel ${packages[*]}
echo -e "y\ny" | sudo pacman --sysroot rootfs -Scc

# rustup will try to find file in /. A permission denied will lead to failure...
sudo rm -rf rootfs/var/lib/tpm2-tss/system/keystore

sudo bsdtar --acls --xattrs -C rootfs -caf bun-bootstrap-rootfs-riscv64.tar.zst .
