#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

if [ "$GPL_ok" = "1" ]; then
    extra_flags="--enable-gpl \
        --enable-version3 \
        --enable-libx264"
        # removed, see https://trac.ffmpeg.org/wiki/CompilationGuide
        # --enable-hardcoded-tables \
else
    extra_flags="--disable-static \
        --disable-gpl \
        --disable-nonfree \
        --disable-openssl"
fi

./configure \
        --prefix="${PREFIX}" \
        --disable-doc \
        --enable-shared \
        --extra-cflags="-fPIC `pkg-config --cflags zlib`" \
        --extra-cxxflags=="-fPIC" \
        --extra-libs="`pkg-config --libs zlib`" \
        --enable-pic \
        --cc=${CC}      \
        --cxx=${CXX}      \
        --enable-avresample \
        --enable-libfreetype \
        --enable-libvpx \
        --enable-libopus \
        --enable-gnutls \
        $extra_flags

make -j${CPU_COUNT}
make install
