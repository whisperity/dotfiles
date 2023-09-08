#!/bin/bash

NO_CACHE=""

if [[ $1 == "-f" ]]
then
	NO_CACHE="--no-cache=true"
fi

docker build ${NO_CACHE} --tag distcc .

echo "REMEMBER! To use this image, you **MUST** set your projects up with the" >&2
echo "*EXPLICIT* version of the compiler, e.g., CC='gcc-7' CXX='g++-7' make" >&2
echo "Otherwise, the tooling will not find the appropriate binary to spawn " >&2
echo "on the remote end!" >&2
