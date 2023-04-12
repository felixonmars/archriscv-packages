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
  _tmp_svn=$(sudo -u felix mktemp -d)
  cd $_tmp_svn

  PKGBASE=$_dir
  sudo -u felix svn checkout svn://svn.archlinux.org/packages/$PKGBASE || \
  sudo -u felix svn checkout svn://svn.archlinux.org/community/$PKGBASE || continue

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

  if [ "${ARCH}" == "any" ] && ! cd ../repos/$REPO-any; then
    error "Release directory does not exist for $REPO-any."
    exit 1
  elif [ "${ARCH}" != "any" ] && ! cd ../repos/$REPO-x86_64; then
    error "Release directory does not exist for $REPO-x86_64."
    exit 1
  fi

  _tmp_trunk=$(sudo -u felix mktemp -d)
  cp $ORIGDIR/$PKGBASE/* $_tmp_trunk
  cp -r . $_tmp_trunk
  cd $_tmp_trunk

  sudo -u felix patch -p0 -i ./riscv64.patch || exit 1

  sudo -u felix makepkg --verifysource --skippgpcheck || exit 1

  popd
done

