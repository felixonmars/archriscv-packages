#!/bin/bash

source /usr/share/makepkg/util/message.sh

ORIGDIR=$PWD
for _dir in $(git diff --merge-base --name-only upstream/master | cut -d / -f 1 | uniq); do
  if [[ ! -e "$_dir"/riscv64.patch ]]; then
    echo "Skipping $_dir..."
    continue
  fi

  echo "Trying to apply patch for $_dir..."

  pushd $_dir
  _tmp=$(mktemp -d)
  cd $_tmp

  PKGBASE=$_dir
  svn checkout svn://svn.archlinux.org/packages/$PKGBASE || svn checkout svn://svn.archlinux.org/community/$PKGBASE || continue

  cd $PKGBASE/trunk

  PKGNAME=$(. PKGBUILD; echo $pkgname)
  for _REPO in core extra community; do
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

  ARCH=$(. PKGBUILD; echo $arch)
  if ! cd ../repos/$REPO-$ARCH; then
    error "Release directory does not exist for $REPO-$ARCH."
    exit 1
  fi

  cp $ORIGDIR/$PKGBASE/* ./
  patch -p0 -i ./riscv64.patch || exit 1
  popd
done

