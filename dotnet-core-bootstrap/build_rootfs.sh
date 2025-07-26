#!/bin/bash
. PKGBUILD
makedepends=( ${makedepends[*]/dotnet-sdk} )
makedepends=( ${makedepends[*]/dotnet-source-built-artifacts} )
makedepends=( ${makedepends[*]/riscv64-linux-gnu-gcc} )

mkdir rootfs
sudo pacstrap -C /usr/share/devtools/pacman.conf.d/extra-riscv64.conf -M rootfs base-devel ${makedepends[*]}
echo -e "y\ny" | sudo pacman --sysroot rootfs -Scc

# dotnet will try to find file in /. A permission denied will lead to failure...
sudo rm -rf rootfs/var/lib/tpm2-tss/system/keystore

sudo bsdtar --acls --xattrs -C rootfs -caf dotnet-core-bootstrap-rootfs-riscv64.tar.zst .
