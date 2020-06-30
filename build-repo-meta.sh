#!/usr/bin/env bash
# sign built packages for release

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# gpg is weird
export GPG_TTY=$(tty)

# GPG key to use for signing
GPGKEY="038CCBF3DAD6946AF5ECC4F9B00B5AAA0E096100"
# path to repo
REPOPATH="/data/nginx/packages.galenguyer.com/debian"

if [ ! -d "$REPOPATH" ]; then
	echo "No repo folder, exiting"
	exit 1
fi
if [ ! -d "./build" ]; then
	echo "No build folder, exiting"
	exit 1
fi

cp ./build/* "$REPOPATH" -v
cd "$REPOPATH"
# build Packages file
apt-ftparchive packages . > Packages
bzip2 -kf Packages

# build signed Release file
apt-ftparchive release . > Release
gpg --yes -abs -u "$GPGKEY" -o Release.gpg Release
