#!/bin/bash
for D in `find bundle -maxdepth 1 -mindepth 1 -type d`
do
  cd $D
  echo "Updating $D..."
  git pull
  cd ../..
done

