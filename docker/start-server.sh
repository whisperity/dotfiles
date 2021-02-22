#!/bin/bash
# Starts a dummy HTTP server for a directory on a given port.

if [ $# -ne 2 ];
then
    echo "Usage: server directory port" >&2
    exit 1
fi

echo "Starting server on port $2 for '$1'..." >&2

python3 \
    -m http.server \
    --directory "$1" &>> /var/log/httpd/access-$2.log
