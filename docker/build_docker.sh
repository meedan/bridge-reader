#!/bin/bash

# change dir to where this script is running
SCRIPT=$(readlink -f "$0")
SDIR=$(dirname "$SCRIPT")
cd $SDIR

# --no-cache or --pull come in handy sometimes
EXTRA=$1

NAME=dreg.meedan.net/bridge/reader

# cd $SDIR/..

# use the current branch name as the container version
VERSION=$(git rev-parse --abbrev-ref HEAD);
VERSION=$(echo $VERSION | sed 's|/|_|g';);
if [ -z "$VERSION" ]; then
	VERSION="develop";
fi	

# fix these paths

docker build ${EXTRA} -t ${NAME}:${VERSION} ../

echo docker build complete: ${NAME}:${VERSION}