#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

if [ "${target_platform}" == 'linux-aarch64' ] || [ "${target_platform}" == "linux-ppc64le" ]; then
    x264libs=""
else
    x264libs="--enable-libopenh264 --enable-libx264"
fi

./configure \
        --prefix="${PREFIX}" \
        --cc=${CC} \
        --disable-doc \
        --enable-gpl \
        --enable-avresample \
        --disable-gnutls \
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-openssl \
        --enable-libvpx \
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
        --enable-nonfree \
        ${x264libs}

make -j${CPU_COUNT} ${VERBOSE_AT}
make install -j${CPU_COUNT} ${VERBOSE_AT}
