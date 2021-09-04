#!/bin/bash
ORIGDIR=$PWD
for _dir in git diff --name-only upstream/master | cut -d / -f 1 | uniq; do
  if [[ ! -e "$dir"/riscv64.patch ]]; then
    echo "Skipping $_dir..."
    continue
  fi

  echo "Trying to apply patch for $_dir..."

  pushd $_dir
  _tmp=$(mktemp -d)
  cd $_tmp
  asp checkout $_dir
  cd $_dir/trunk
  cp $ORIGDIR/$_dir/* ./
  patch -p0 -i ./riscv64.patch
  popd
done

