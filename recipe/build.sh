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
if [[ ${target_platform} != win-64 ]]
then
_CONFIG_OPTS+=("--enable-libopenh264")
_CONFIG_OPTS+=("--enable-libopus")
_CONFIG_OPTS+=("--enable-libopenjpeg")
_CONFIG_OPTS+=("--enable-libvorbis")
_CONFIG_OPTS+=("--enable-pthreads")
fi

# enable other codecs and formats depending on platform
# temporarily disabling librsvg because pkg-config doesn't find xau which is supposedly in the dependency chain of librsvg
if [[ ${target_platform} != linux-64 ]] && [[ ${target_platform} != linux-aarch64 ]] && [[ ${target_platform} != linux-s390x ]]
then
  _CONFIG_OPTS+=("--enable-librsvg")
fi
_CONFIG_OPTS+=("--enable-libtheora")

_CONFIG_OPTS+=("--enable-libxml2")
if [[ ${target_platform} != linux-s390x ]] && [[ ${target_platform} != win-64 ]]
then
  _CONFIG_OPTS+=("--enable-libtesseract")
  _CONFIG_OPTS+=("--enable-gcrypt")
fi
if [[ ${target_platform} != win-64 ]]
then
  _CONFIG_OPTS+=("--enable-libmp3lame")
  _CONFIG_OPTS+=("--enable-gmp")
fi

# GPL-3.0
if [[ ${target_platform} != linux-s390x ]] && [[ ${target_platform} != win-64 ]]
then
  _CONFIG_OPTS+=("--enable-libx264")
  _CONFIG_OPTS+=("--enable-libvpx")
fi

if [[ ${target_platform} == win-64 ]]
then
  _CONFIG_OPTS+=("--ld=${LD}")
  _CONFIG_OPTS+=("--target-os=win64")
  _CONFIG_OPTS+=("--toolchain=msvc")
  _CONFIG_OPTS+=("--host-cc=${CC}")
  _CONFIG_OPTS+=("--enable-cross-compile")
  # ffmpeg by default attempts to link to libm
  # but that doesn't exist for windows
  _CONFIG_OPTS+=("--host-extralibs=")
  export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
  PKG_CONFIG="${BUILD_PREFIX}/Library/bin/pkg-config"
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
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-postproc \
        --enable-pic \
        --enable-shared \
        --enable-version3 \
        --enable-zlib \
        --disable-sdl2 \
        "${_CONFIG_OPTS[@]}"

make -j${CPU_COUNT} ${VERBOSE_AT}
make install -j${CPU_COUNT} ${VERBOSE_AT}
