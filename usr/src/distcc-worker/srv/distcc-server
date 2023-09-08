#!/bin/bash

cron &

if [ $# -eq 2 ]
then
  if [ "$1" == "--jobs" -o "$1" == "-j" ]
  then
    echo "Starting DistCC with $2 jobs..."
    NPROC=$2

    shift 2
  fi
fi

if [ -z "${NPROC}" ]
then
  NPROC=$(nproc)
fi

if [ $# -ne 0 ]
then
  echo "Overridden start arguments found - executing the command itself." >&2
  exec "$@"
else
  # Create a DistCC daemon.
  distccd \
    --allow 0.0.0.0/0 \
    --daemon \
    --no-detach \
    --pid-file=/var/run/distccd.pid \
    --log-file=/var/log/distccd.log \
    --jobs ${NPROC}
fi
