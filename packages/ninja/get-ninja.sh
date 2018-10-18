#!/bin/bash

curl -sL http://api.github.com/repos/ninja-build/ninja/releases/latest \
  | grep "ninja-linux.zip" \
  | grep "browser_download_url" \
  | cut -d ":" -f 2,3 \
  | sed -E 's/^ "(.*)",?$/\1/' \
  | wget -O ninja-linux.zip -i -
