#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

./configure \
        --prefix="${PREFIX}" \
        --cc=${CC} \
        --disable-doc \
        --enable-shared \
        --enable-static \
        --enable-zlib \
        --enable-pic \
        --enable-gpl \
        --enable-version3 \
        --disable-nonfree \
        --enable-hardcoded-tables \
        --enable-avresample \
        --enable-libfreetype \
        --disable-openssl \
        --disable-gnutls \
        --enable-libvpx \
        --enable-pthreads \
        --enable-libopus \
        --enable-postproc \
        --disable-libx264

make -j${CPU_COUNT} ${VERBOSE_AT}
make install -j${CPU_COUNT} ${VERBOSE_AT}
