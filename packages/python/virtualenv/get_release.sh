#!/bin/bash

curl -s https://api.github.com/repos/pypa/virtualenv/tags \
  | grep "tarball" \
  | head -n 1 \
  | cut -d '"' -f 4 \
  | wget -O virtualenv.tar.gz -i -
