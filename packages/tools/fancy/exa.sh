#!/bin/bash

ARCH=$(arch)

curl -sL http://api.github.com/repos/ogham/exa/releases/latest \
  | grep "exa-linux-" \
  | grep "${ARCH}" \
  | grep ".zip" \
  | grep "browser_download_url" \
  | cut -d ":" -f 2,3 \
  | sed -E 's/^ "(.*)",?$/\1/' \
  | wget -O exa.zip -i -

unzip exa.zip
mv exa-* exa

