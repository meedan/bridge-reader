#!/bin/bash

# --no-cache or --pull come in handy sometimes
EXTRA=$1

NAME=dreg.meedan.net/bridge/embed

# change to the directory where we are
SDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# cd $SDIR/..

# use the current branch name as the container version
VERSION=$(git rev-parse --abbrev-ref HEAD);
VERSION=$(echo $VERSION | sed 's|/|_|g';);
if [ -z "$VERSION" ]; then
	VERSION="develop";
fi	

# fix these paths

docker build ${EXTRA} -t ${NAME}:${VERSION} ../

