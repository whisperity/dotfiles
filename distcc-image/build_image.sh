#!/bin/bash

NO_CACHE=""

if [[ $1 == "-f" ]]
then
	NO_CACHE="--no-cache=true"
fi

docker build ${NO_CACHE} --tag distcc .

