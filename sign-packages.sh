#!/usr/bin/env bash
# sign built packages for release

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# gpg is weird
export GPG_TTY=$(tty)

GPGKEY="038CCBF3DAD6946AF5ECC4F9B00B5AAA0E096100"

if [ ! -d ./build ]; then
	echo "No build folder, exiting"
	exit 1
fi

cd ./build
dpkg-sig -k "$GPGKEY" -s builder *.deb
