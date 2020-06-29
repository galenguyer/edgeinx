#!/usr/bin/env bash
# a script to build nginx against openssl-dev
# includes nginx fancyindex module

# exit on error
set -e
# display last non-zero exit code in a failed pipeline
set -o pipefail
# subshells and functions inherit ERR traps
set -E

# set core count for make
core_count="$(grep -c ^processor /proc/cpuinfo)"

# choose where to put the build files
BUILDROOT="$(mktemp -d)"
cd "$BUILDROOT"

# install build dependencies
apt-get update
apt-get install -y build-essential gcc g++ cmake git gnupg golang libpcre3 libpcre3-dev curl zlib1g-dev libcurl4-openssl-dev

# fetch the pcre library
PCRE="8.44"
mkdir -p "$BUILDROOT/pcre"
cd "$BUILDROOT/pcre"
curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE/pcre-$PCRE.tar.gz"
tar xzf "$BUILDROOT/pcre/pcre-$PCRE.tar.gz"

# fetch the desired version of nginx
mkdir -p "$BUILDROOT/nginx"
cd "$BUILDROOT"/nginx
curl -L -O "http://nginx.org/download/nginx-$NGINX.tar.gz"
tar xzf "nginx-$NGINX.tar.gz"
cd "$BUILDROOT/nginx/nginx-$NGINX"

# fetch the fancy-index module
git clone https://github.com/aperezdc/ngx-fancyindex.git "$BUILDROOT"/ngx-fancyindex

# Fetch Cloudflare Quiche for QUIC support and apply patch
git clone --recursive https://github.com/cloudflare/quiche "$BUILDROOT/quiche"
patch -p01 < "$BUILDROOT/quiche/extras/nginx/nginx-1.16.patch" 

# configure the nginx source to include our added modules
# and to use our newly built openssl library
./configure --prefix=/usr/share/nginx \
	--add-module="$BUILDROOT"/ngx-fancyindex \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/run/nginx.pid \
	--lock-path=/run/lock/subsys/nginx \
	--user=www-data \
	--group=www-data \
	--with-threads \
	--with-file-aio \
	--with-pcre="$BUILDROOT/pcre/pcre-$PCRE" \
	--with-pcre-jit \
	--with-http_addition_module \
	--without-http_fastcgi_module \
	--without-http_uwsgi_module \
	--without-http_scgi_module \
	--without-http_gzip_module \
	--without-select_module \
	--without-poll_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--without-mail_smtp_module \
	--build="quiche-$(git --git-dir=$BUILDROOT/quiche/.git rev-parse --short HEAD)" \
	--with-http_ssl_module \
        --with-http_v2_module \
        --with-http_v3_module \
	--with-quiche="$BUILDROOT/quiche" \
	--with-openssl="$BUILDROOT/quiche/deps/boringssl" \
	--with-cc-opt="-g -O3 -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security" \
	--with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro -L $BUILDROOT/boringssl/.openssl/lib/" \

# build nginx
make -j"$core_count"
make install

# copy the nginx binary to the host volume
cp -fv /usr/sbin/nginx /build/nginx-"$NGINX"-quiche
chmod 777 /build -R
