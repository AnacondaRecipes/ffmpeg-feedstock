#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

declare -a _CONFIG_OPTS=()

if [[ ${target_platform} != win-64 ]]
then
  ##### For platforms LINUX-*, OSX-* #####

  # we choose libopenh264 instead of x264 to make this LGPL
  # these codecs are not supported for win-64 at the moment
  _CONFIG_OPTS+=("--enable-libopenh264")
  _CONFIG_OPTS+=("--enable-libopus")
  _CONFIG_OPTS+=("--enable-libopenjpeg")
  _CONFIG_OPTS+=("--enable-libvorbis")
  _CONFIG_OPTS+=("--enable-libmp3lame")
  _CONFIG_OPTS+=("--enable-pthreads")

  ##### For platforms LINUX-64, LINUX-AARCH64
  if [[ ${target_platform} == linux-64 ]] || [[ ${target_platform} == linux-aarch64 ]]
  then
     # libtesseract not supported on s390x and win-64
    _CONFIG_OPTS+=("--enable-libtesseract")
    # libvpx not supported on s390x and win-64
    _CONFIG_OPTS+=("--enable-libvpx")
  fi

  ##### For platforms OSX-*          #####
  if [[ ${target_platform} == osx-64 ]] || [[ ${target_platform} == osx-arm64 ]]
  then
     # on other platform pkg-config doesn't find xau which is supposedly in the dependency chain of librsvg
    _CONFIG_OPTS+=("--enable-librsvg")
    # not supported on osx-*
    _CONFIG_OPTS+=("--enable-libtesseract")
    # libvpx not supported on s390x and win-64
    _CONFIG_OPTS+=("--enable-libvpx")
  fi

##### For platforms WIN-64           #####
else
  _CONFIG_OPTS+=("--ld=${LD}")
  _CONFIG_OPTS+=("--target-os=win64")
  _CONFIG_OPTS+=("--toolchain=msvc")
  _CONFIG_OPTS+=("--host-cc=${CC}")
  _CONFIG_OPTS+=("--enable-cross-compile")
  # ffmpeg by default attempts to link to libm
  # but that doesn't exist for windows
  _CONFIG_OPTS+=("--host-extralibs=")
  # we don't want pthreads on win
  _CONFIG_OPTS+=("--disable-pthreads")
  _CONFIG_OPTS+=("--enable-w32threads")
  # manually include the runtime libs
  _CONFIG_OPTS+=("--extra-libs=ucrt.lib vcruntime.lib oldnames.lib")
  _CONFIG_OPTS+=("--disable-stripping")
  export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
  # unistd.h is included in ${PREFIX}/include/zconf.h
  if [[ ! -f "${PREFIX}/include/unistd.h" ]]; then
      UNISTD_CREATED=1
      touch "${PREFIX}/include/unistd.h"
  fi
fi

# configure AR, RANLIB, STRIP and co. since they are not always automatically detected
_CONFIG_OPTS+=("--ar=${AR}")
_CONFIG_OPTS+=("--nm=${NM}")
_CONFIG_OPTS+=("--ranlib=${RANLIB}")
_CONFIG_OPTS+=("--strip=${STRIP}")

# common flags to all platforms
# openssl: as of OpenSSL 3, the license is Apache-2.0 so we can enable this
# disable-static: we generally favor shared library binaries than static
./configure \
        --prefix="${PREFIX}" \
        --cc=${CC} \
        --disable-doc \
        --enable-swresample \
        --enable-openssl \
        --enable-libxml2 \
        --enable-libtheora \
        --enable-demuxer=dash \
        --enable-postproc \
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-libharfbuzz \
        --enable-libfontconfig \
        --enable-libdav1d \
        --enable-zlib \
        --enable-libaom \
        --enable-pic \
        --enable-shared \
        --disable-static \
        --enable-version3 \
        --disable-sdl2 \
        "${_CONFIG_OPTS[@]}"

make -j${CPU_COUNT} ${VERBOSE_AT}
make install -j${CPU_COUNT} ${VERBOSE_AT}


if [[ "${target_platform}" == win-* ]]; then
  if [[ "${UNISTD_CREATED}" == "1" ]]; then
      rm -f "${PREFIX}/include/unistd.h"
  fi
fi