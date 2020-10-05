#!/bin/bash

ARCH=$(arch)
if [[ $ARCH == "x86_64" ]]
then
  ARCH="x86_64"
else
  ARCH="i686"
fi

curl -sL http://api.github.com/repos/bootandy/dust/releases/latest \
  | grep "dust-" \
  | grep "\-${ARCH}" \
  | grep "\-linux-gnu.tar.gz" \
  | grep "browser_download_url" \
  | cut -d ":" -f 2,3 \
  | sed -E 's/^ "(.*)",?$/\1/' \
  | wget -O dust.tar.gz -i -

tar xfz ./dust.tar.gz
mv -v ./dust-*/dust ./dust
rm -r ./dust-* ./dust.tar.gz
