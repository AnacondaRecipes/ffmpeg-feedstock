#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

declare -a _CONFIG_OPTS=()

if [[ ${target_platform} == win-64 ]]
then
  # the target-os and toolchain picked up by default is mingw, so we have to configure
  # these flags ourselves to get it to build properly
  _CONFIG_OPTS+=("--ld=${LD}")
  _CONFIG_OPTS+=("--target-os=win64")
  _CONFIG_OPTS+=("--toolchain=msvc")
  _CONFIG_OPTS+=("--host-cc=${CC}")
  _CONFIG_OPTS+=("--enable-cross-compile")
  # ffmpeg by default attempts to link to libm
  # but that doesn't exist for windows
  _CONFIG_OPTS+=("--host-extralibs=")
  # we don't want pthreads on win, it's not posix compliant
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

else
  # we choose libopenh264 instead of x264 to make this LGPL
  # we don't have these packages for win
  _CONFIG_OPTS+=("--enable-libopenh264")
  _CONFIG_OPTS+=("--enable-libopus")
  _CONFIG_OPTS+=("--enable-libmp3lame")
  # Our win packages don't have .pc files for these
  _CONFIG_OPTS+=("--enable-libopenjpeg")
  _CONFIG_OPTS+=("--enable-libvorbis")
  # we don't want pthreads on win, it's not posix compliant
  _CONFIG_OPTS+=("--enable-pthreads")
fi


if [[ ${target_platform} != linux-s390x ]] && [[ ${target_platform} != win-64 ]]
then
  # we don't have a tesseract or libvpx for win or s390x
  _CONFIG_OPTS+=("--enable-libtesseract")
  _CONFIG_OPTS+=("--enable-libvpx")
fi


if [[ ${target_platform} == osx-64 ]] || [[ ${target_platform} == osx-arm64 ]]
then
  # on other platform pkg-config doesn't find xau which is supposedly in the dependency chain of librsvg
  _CONFIG_OPTS+=("--enable-librsvg")
fi

# common flags to all platforms
# openssl: as of OpenSSL 3, the license is Apache-2.0 so we can enable this
# disable-static: we generally favor shared library binaries than static
# configure AR, RANLIB, STRIP and co. since they are not always automatically detected
./configure \
        --prefix="${PREFIX}" \
        --cc=${CC} \
        --ar=${AR} \
        --nm=${NM} \
        --ranlib=${RANLIB} \
        --strip=${STRIP} \
        --disable-doc \
        --enable-swresample \
        --enable-swscale \
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
        --disable-gpl \
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