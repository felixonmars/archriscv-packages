#!/bin/bash

source /usr/share/makepkg/util/message.sh

if [[ -e riscv64.patch ]]; then
  error "riscv64.patch is found in root directory."
  exit 1
fi

ORIGDIR=$PWD
for _dir in $(git diff --merge-base --name-only upstream/master | cut -d / -f 1 | uniq); do
  if [[ ! -e "$_dir"/riscv64.patch ]]; then
    echo "Skipping $_dir..."
    continue
  fi

  echo "Trying to apply patch for $_dir..."

  pushd $_dir
  _tmp=$(sudo -u nobody mktemp -d)
  cd $_tmp

  PKGBASE=$_dir
  sudo -u nobody git clone https://gitlab.archlinux.org/archlinux/packaging/packages/$PKGBASE.git || continue
  cd $PKGBASE

  PKGNAME=$(. PKGBUILD >/dev/null; echo $pkgname)
  for _REPO in core extra; do
    if pacman -Sql $_REPO | grep "^$PKGNAME$" >/dev/null; then
      REPO=$_REPO
      break
    fi
  done

  if [[ -z "$REPO" ]]; then
    # Actually triggers for rotten packages
    error "Cannot find package in x86 repo."
    exit 1
  fi

  LATEST_VERSION=$(expac -S %v $PKGNAME)
  if ! sudo -u nobody git checkout ${LATEST_VERSION/:/-}; then
    error "Repository does not contain tag of latest non-testing version $LATEST_VERSION."
    exit 1
  fi

  cp $ORIGDIR/$PKGBASE/* ./

  sudo -u nobody patch -p0 -i ./riscv64.patch || exit 1

  sudo -u nobody makepkg --verifysource --skippgpcheck || exit 1

  popd
done
