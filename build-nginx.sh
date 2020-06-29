#!/usr/bin/env bash
# Build a statically linked nginx binary

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# set the nginx version we wish to build
MAINLINE="1.19.0"
STABLE="1.18.0"

# set package version
PKGVER="0.2.0"
PKGBUILD="$(pwd)/build"

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

# copy base files and build packages
if [ -d "$PKGBUILD" ]; then
	rm -r "$PKGBUILD"
fi
mkdir -p "$PKGBUILD"

# build stable noquiche package
cd "$PKGBUILD"
if [ -d "$PKGBUILD"/pkg-debian ]; then
	rm -r "$PKGBUILD"/pkg-debian
fi
cp ../pkg-debian ./ -r
mkdir -p "$PKGBUILD"/pkg-debian/usr/sbin
cp ../artifacts/nginx-"$STABLE" "$PKGBUILD"/pkg-debian/usr/sbin/nginx
cd ./pkg-debian
find . -type f | grep -v 'debian-binary' | grep -v 'DEBIAN' | xargs md5sum > ./DEBIAN/md5sums
sed -i "s/[{][{]PACKAGE[}][}]/edgeinx-stable/g" ./DEBIAN/control
sed -i "s/[{][{]VERSION[}][}]/$PKGVER/g" ./DEBIAN/control
cd ..
dpkg -b pkg-debian/ edgeinx-stable_"$PKGVER"_amd64.deb

# build mainline noquiche package
cd "$PKGBUILD"
if [ -d "$PKGBUILD"/pkg-debian ]; then
	rm -r "$PKGBUILD"/pkg-debian
fi
cp ../pkg-debian ./ -r
mkdir -p "$PKGBUILD"/pkg-debian/usr/sbin
cp ../artifacts/nginx-"$MAINLINE" "$PKGBUILD"/pkg-debian/usr/sbin/nginx
cd ./pkg-debian
find . -type f | grep -v 'debian-binary' | grep -v 'DEBIAN' | xargs md5sum > ./DEBIAN/md5sums
sed -i "s/[{][{]PACKAGE[}][}]/edgeinx-mainline/g" ./DEBIAN/control
sed -i "s/[{][{]VERSION[}][}]/$PKGVER/g" ./DEBIAN/control
cd ..
dpkg -b pkg-debian/ edgeinx-mainline_"$PKGVER"_amd64.deb

# build quiche package
cd "$PKGBUILD"
if [ -d "$PKGBUILD"/pkg-debian ]; then
	rm -r "$PKGBUILD"/pkg-debian
fi
cp ../pkg-debian ./ -r
mkdir -p "$PKGBUILD"/pkg-debian/usr/sbin
cp ../artifacts/nginx-"1.16.1"-quiche "$PKGBUILD"/pkg-debian/usr/sbin/nginx
cd ./pkg-debian
find . -type f | grep -v 'debian-binary' | grep -v 'DEBIAN' | xargs md5sum > ./DEBIAN/md5sums
sed -i "s/[{][{]PACKAGE[}][}]/edgeinx-quiche/g" ./DEBIAN/control
sed -i "s/[{][{]VERSION[}][}]/$PKGVER/g" ./DEBIAN/control
cd ..
dpkg -b pkg-debian/ edgeinx-quiche_"$PKGVER"_amd64.deb

# build stable quiche package
cd "$PKGBUILD"
if [ -d "$PKGBUILD"/pkg-debian ]; then
	rm -r "$PKGBUILD"/pkg-debian
fi
cp ../pkg-debian ./ -r
mkdir -p "$PKGBUILD"/pkg-debian/usr/sbin
cp ../artifacts/nginx-"$STABLE"-quiche "$PKGBUILD"/pkg-debian/usr/sbin/nginx
cd ./pkg-debian
find . -type f | grep -v 'debian-binary' | grep -v 'DEBIAN' | xargs md5sum > ./DEBIAN/md5sums
sed -i "s/[{][{]PACKAGE[}][}]/edgeinx-stable-quiche/g" ./DEBIAN/control
sed -i "s/[{][{]VERSION[}][}]/$PKGVER/g" ./DEBIAN/control
cd ..
dpkg -b pkg-debian/ edgeinx-stable-quiche_"$PKGVER"_amd64.deb

# build mainline quiche package
cd "$PKGBUILD"
if [ -d "$PKGBUILD"/pkg-debian ]; then
	rm -r "$PKGBUILD"/pkg-debian
fi
cp ../pkg-debian ./ -r
mkdir -p "$PKGBUILD"/pkg-debian/usr/sbin
cp ../artifacts/nginx-"$MAINLINE"-quiche "$PKGBUILD"/pkg-debian/usr/sbin/nginx
cd ./pkg-debian
find . -type f | grep -v 'debian-binary' | grep -v 'DEBIAN' | xargs md5sum > ./DEBIAN/md5sums
sed -i "s/[{][{]PACKAGE[}][}]/edgeinx-mainline-quiche/g" ./DEBIAN/control
sed -i "s/[{][{]VERSION[}][}]/$PKGVER/g" ./DEBIAN/control
cd ..
dpkg -b pkg-debian/ edgeinx-mainline-quiche_"$PKGVER"_amd64.deb

# clean up build files
cd "$PKGBUILD"
if [ -d "$PKGBUILD"/pkg-debian ]; then
	rm -r "$PKGBUILD"/pkg-debian
fi
cd ..
if [ -d "$BUILDROOT/artifacts" ]; then
	rm -r "$BUILDROOT/artifacts"
fi
