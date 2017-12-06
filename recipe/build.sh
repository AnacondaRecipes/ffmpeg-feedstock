#!/bin/bash

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

./configure \
        --prefix="${PREFIX}" \
        --disable-doc \
        --enable-shared \
        --extra-cflags="-fPIC `pkg-config --cflags zlib`" \
        --extra-cxxflags=="-fPIC" \
        --extra-libs="`pkg-config --libs zlib`" \
        --enable-pic \
        --disable-static \
        --disable-gpl \
        --disable-nonfree \
        --disable-openssl \
        --enable-libvpx \
        --cc=${CC}      \
        --cxx=${CXX}      \
        --enable-libopus

make -j${CPU_COUNT}
make install
