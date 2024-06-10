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

if [[ ${target_platform} != linux-s390x ]]
then
  # GPL-3.0
  _CONFIG_OPTS+=("--enable-libx264")
  _CONFIG_OPTS+=("--enable-libvpx")
else
  # disable x86 asm optimizations explicitly to avoid error about missing nasm
  _CONFIG_OPTS+=("--disable-x86asm")
fi

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
        --enable-static \
        --enable-version3 \
        --enable-zlib \
      	--enable-libmp3lame \
        --disable-sdl2 \
        "${_CONFIG_OPTS[@]}"

make -j${CPU_COUNT} ${VERBOSE_AT}
make install -j${CPU_COUNT} ${VERBOSE_AT}
