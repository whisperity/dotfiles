#!/bin/bash

ARCH=$(arch)
if [[ $ARCH == "x86_64" ]]
then
  ARCH="amd64"
else
  ARCH="i386"
fi

curl -sL http://api.github.com/repos/dandavison/delta/releases/latest \
  | grep "git-delta_" \
  | grep "_${ARCH}.deb" \
  | grep "browser_download_url" \
  | cut -d ":" -f 2,3 \
  | sed -E 's/^ "(.*)",?$/\1/' \
  | wget -O delta.deb -i -
