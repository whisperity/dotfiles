#!/bin/bash

# curl -sL http://api.github.com/repos/pypa/virtualenv/tags \
#   | grep "tarball" \
#   | head -n 1 \
#   | cut -d ":" -f 2,3 \

echo "https://api.github.com/repos/pypa/virtualenv/tarball/16.7.7" \
  | sed -E 's/^ "(.*)",?$/\1/' \
  | wget -O virtualenv.tar.gz -i -
