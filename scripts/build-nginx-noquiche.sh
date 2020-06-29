#!/usr/bin/env bash
# a script to build nginx against openssl-dev
# includes nginx fancyindex module

# exit on error
set -e
# display last non-zero exit code in a failed pipeline
set -o pipefail
# subshells and functions inherit ERR traps
set -E

# select the openssl branch to build
OPENSSL="OpenSSL_1_1_1-stable"

# set core count for make
core_count="$(grep -c ^processor /proc/cpuinfo)"

# choose where to put the build files
BUILDROOT="$(mktemp -d)"

# install build dependencies
apt-get update
apt-get install -y build-essential gcc g++ cmake git gnupg golang libpcre3 libpcre3-dev curl zlib1g-dev libcurl4-openssl-dev

cd "$BUILDROOT"

# check if git supports forced ipv4, added in 2.8
git_version="$(git --version | awk '{print $3}' | cut -d"." -f1-2 )"
ishigher="$(echo -e "$git_version\n2.8" | sort -V | tail -n1)"
if [[ "$git_version" == "$ishigher" ]]; then
        forcev4="-4"
else
        forcev4=""
fi
# clone the desired openssl branch, over ipv4 if supported due to slow ipv6 connectivity
git clone "$forcev4" -b "$OPENSSL" git://git.openssl.org/openssl.git
cd openssl
# use default openssl configurations
./config
# build openssl
make -j"$core_count"

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
	--with-openssl="$BUILDROOT/openssl" \
	--with-cc-opt="-g -O3 -march=native -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security -I $BUILDROOT/openssl" \
	--with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro -L $BUILDROOT/openssl/"

# build nginx
make -j"$core_count"
make install

# copy the nginx binary to the host volume
cp -fv /usr/sbin/nginx /build/nginx-"$NGINX"
chmod 777 /build -R
