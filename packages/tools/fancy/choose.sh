#!/bin/bash

curl -sL http://api.github.com/repos/theryangeary/choose/releases/latest \
  | grep "choose" \
  | grep "browser_download_url" \
  | cut -d ":" -f 2,3 \
  | sed -E 's/^ "(.*)",?$/\1/' \
  | wget -O choose -i -

chmod -v +x ./choose
