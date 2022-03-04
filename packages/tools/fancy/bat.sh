#!/bin/bash

# ARCH=$(arch)
# if [[ $ARCH == "x86_64" ]]
# then
#   ARCH="amd64"
# else
#   ARCH="i386"
# fi
#
# curl -sL http://api.github.com/repos/sharkdp/bat/releases/latest \
#   | grep "bat_" \
#   | grep "_${ARCH}.deb" \
#   | grep "browser_download_url" \
#   | cut -d ":" -f 2,3 \
#   | sed -E 's/^ "(.*)",?$/\1/' \
#   | wget -O bat.deb -i -

wget -O bat.deb \
  http://github.com/sharkdp/bat/releases/download/v0.20.0/bat_0.20.0_amd64.deb
