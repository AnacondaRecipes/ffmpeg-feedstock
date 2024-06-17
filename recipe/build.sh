#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

declare -a _CONFIG_OPTS=()

# We choose the following flags because we don't enable NON-FREE features
# We do not care what the defaults are as they could change. Be explicit
# about every flag.
_CONFIG_OPTS+=("--disable-nonfree")
_CONFIG_OPTS+=("--enable-gpl")
_CONFIG_OPTS+=("--disable-gnutls")
# As of OpenSSL 3, the license is Apache-2.0 so we can enable this
_CONFIG_OPTS+=("--enable-openssl")
# The Cisco GPL-compliant wrapper (you need to get your own binaries for this)
_CONFIG_OPTS+=("--enable-libopenh264")

# enable other codecs and formats
_CONFIG_OPTS+=("--enable-libopenjpeg")
# temporarily disabling librsvg because of pkg-config not finding librsvg
if [[ ${target_platform} != linux-64 ]]
then
  _CONFIG_OPTS+=("--enable-librsvg")
fi
_CONFIG_OPTS+=("--enable-libtheora")
_CONFIG_OPTS+=("--enable-libvorbis")
_CONFIG_OPTS+=("--enable-libxml2")
if [[ ${target_platform} != linux-s390x ]]
then
  _CONFIG_OPTS+=("--enable-libtesseract")
  _CONFIG_OPTS+=("--enable-gcrypt")
fi

# GPL-3.0
if [[ ${target_platform} != linux-s390x ]]
then
  _CONFIG_OPTS+=("--enable-libx264")
  _CONFIG_OPTS+=("--enable-libvpx")
fi

# configure AR, RANLIB, STRIP and co. since they are not always automatically detected
_CONFIG_OPTS+=("--ar=${AR}")
_CONFIG_OPTS+=("--nm=${NM}")
_CONFIG_OPTS+=("--ranlib=${RANLIB}")
_CONFIG_OPTS+=("--strip=${STRIP}")

./configure \
        --prefix="${PREFIX}" \
        --cc=${CC} \
        --disable-doc \
        --enable-swresample \
        --enable-gmp \
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-pthreads \
        --enable-libopus \
        --enable-postproc \
        --enable-pic \
        --enable-pthreads \
        --enable-shared \
        --enable-version3 \
        --enable-zlib \
      	--enable-libmp3lame \
        --disable-sdl2 \
        "${_CONFIG_OPTS[@]}"

make -j${CPU_COUNT} ${VERBOSE_AT}
make install -j${CPU_COUNT} ${VERBOSE_AT}
