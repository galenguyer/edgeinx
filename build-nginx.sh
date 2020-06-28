#!/usr/bin/env bash
# Build a statically linked nginx binary

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# set the nginx version we wish to build
MAINLINE="1.19.0"
STABLE="1.18.0"

# choose where to put the build files
# by default this is in a temporary directory
BUILDROOT="$(pwd)"

# run our build script in a docker container
# build stable version without QUIC support
docker run -it --rm -e "NGINX=$STABLE" -v "$BUILDROOT"/artifacts:/build rust:stretch /bin/bash -c "`cat ./scripts/build-nginx-noquiche.sh`"
# build mainline version without QUIC support
docker run -it --rm -e "NGINX=$MAINLINE" -v "$BUILDROOT"/artifacts:/build rust:stretch /bin/bash -c "`cat ./scripts/build-nginx-noquiche.sh`"
# build known supported quiche version
docker run -it --rm -e "NGINX=1.16.1" -v "$BUILDROOT"/artifacts:/build rust:stretch /bin/bash -c "`cat ./scripts/build-nginx-quiche.sh`"
# build stable quiche version with QUIC support
docker run -it --rm -e "NGINX=$STABLE" -v "$BUILDROOT"/artifacts:/build rust:stretch /bin/bash -c "`cat ./scripts/build-nginx-quiche.sh`"
# build mainline quiche version with QUIC support
docker run -it --rm -e "NGINX=$MAINLINE" -v "$BUILDROOT"/artifacts:/build rust:stretch /bin/bash -c "`cat ./scripts/build-nginx-quiche.sh`"
