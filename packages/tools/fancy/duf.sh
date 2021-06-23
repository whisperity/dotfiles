#!/bin/bash

ARCH=$(arch)
if [[ $ARCH == "x86_64" ]]
then
  ARCH="amd64"
else
  ARCH="i386"
fi

curl -sL http://api.github.com/repos/muesli/duf/releases/latest \
  | grep "duf_" \
  | grep "_linux_${ARCH}.deb" \
  | grep "browser_download_url" \
  | cut -d ":" -f 2,3 \
  | sed -E 's/^ "(.*)",?$/\1/' \
  | wget -O duf.deb -i -
