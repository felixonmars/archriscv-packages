#!/usr/bin/bash

if [[ ! -x ./scripts/config ]]; then
  echo "This script must be executed in Linux source tree!"
  exit 1
fi

if [[ ! -r "$1" ]]; then
  echo "No defconfig file given!"
  exit 1
fi

configs=$(grep -v '^#' "$1" | sed -E 's/^CONFIG_//;s/\s+$//g' |
    awk -F'=' '
      {
        if ($2=="y") {
          print "-e "$1
        } else if ($2=="n") {
          print "-d "$1
        } else if ($2=="m") {
          print "-m "$1
        }
      }
      ')

if [[ -z "$2" ]]; then
  ./scripts/config ${configs[@]}
else
  ./scripts/config --file "$2" ${configs[@]}
fi
