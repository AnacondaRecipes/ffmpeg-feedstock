#!/bin/bash
set -eox pipefail

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$BUILD_PREFIX/lib/pkgconfig"

# unset the SUBDIR variable since it changes the behavior of make here
unset SUBDIR

# unset the sdl2 environment variable (set to 2 by conda-build) as somehow interferes
# with the ffmpeg's configure script, see https://github.com/conda-forge/ffmpeg-feedstock/pull/308#issuecomment-2644150512
unset sdl2
unset svt_av1

extra_args=""
if [[ "$ARCH" == "64" ]]; then
  ARCH=x86_64
fi
case "$target_platform" in
  linux-*)
    OS=linux
    ;;
  osx-*)
    OS=darwin
    ;;
  win-64)
    OS=win64
    ;;
  *)
    echo "unknown OS for cross compile"
    exit 1
    ;;
esac
extra_args="${extra_args} --arch=$ARCH --target-os=$OS --cross-prefix=$HOST- --host-cc=$CC_FOR_BUILD"

if [[ "${target_platform}" == "win-64" ]]; then
  # 2022/07 hmaarrfk
  # Specifying these extra flags for osx and linux
  # seems to cause things to fail since FFmpeg
  # expects cc to be the ld
  # # https://github.com/FFmpeg/FFmpeg/blob/master/configure#L4894
  # the LDFLAGs on Unix contain the -Wl, prefix, and thus
  # are incompatible with the direct ld command
  # Thus we avoid specifying ld for the unix platforms
  extra_args="${extra_args} --ld=${LD}"

  extra_args="${extra_args} --toolchain=msvc"
  extra_args="${extra_args} --host-cc=${CC}"
  extra_args="${extra_args} --extra-libs=ucrt.lib --extra-libs=vcruntime.lib --extra-libs=oldnames.lib"
  extra_args="${extra_args} --strip=llvm-strip"
  extra_args="${extra_args} --disable-pthreads"
  extra_args="${extra_args} --enable-w32threads"
  # Through, locally, I get
  #    This app can't run on your PC
  # and access denied on the terminal
  # I cannot even run llvm-strip on the terminal
  extra_args="${extra_args} --disable-stripping"

  # ffmpeg by default attempts to link to libm
  # but that doesn't exist for windows
  extra_args="${extra_args} --host-extralibs="

  # Delete line that includes unistd.h from zconf. we should patch this
  # better for LLVM compatibility
  # I submitted a ticket upstream
  # https://github.com/madler/zlib/issues/674
  # cp ${PREFIX}/include/zconf.h zconf.h.backup
  # sed -i "/unistd/d" ${PREFIX}/include/zconf.h
  if [[ ! -f "${PREFIX}/include/unistd.h" ]]; then
      UNISTD_CREATED=1
      touch "${PREFIX}/include/unistd.h"
  fi

  # Add pkgconfig from the prefix to search through it correctly
  export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
  PKG_CONFIG="${BUILD_PREFIX}/Library/bin/pkg-config"

  # I'm not sure, but it seems like
  # their hacky way of silencing things is messing with the AR command
  # Especially as it is called in compat/windows/makedef
  # https://github.com/FFmpeg/FFmpeg/blob/master/ffbuild/common.mak#L21
  # I think their hacky silence is corrupting later on AR commands invoked
  # from shells with a @printf statement
  # To avoid hacky patches, I'm just going to make it verbose, always.
  # maybe related to https://trac.ffmpeg.org/ticket/6620
  export V=1
  # spirv/shaderc is disabled when Vulkan is unavailable; do not pull shaderc in meta on Windows
  extra_args="${extra_args} --disable-libshaderc"
elif [[ "${target_platform}" == linux-* ]]; then
  PKG_CONFIG="${BUILD_PREFIX}/bin/pkg-config"
  extra_args="${extra_args} --disable-gnutls"
  extra_args="${extra_args} --enable-libvpx"
  extra_args="${extra_args} --enable-pthreads"
  extra_args="${extra_args} --enable-alsa"
  extra_args="${extra_args} --enable-libpulse"
  extra_args="${extra_args} --enable-libdrm"
  if [[ "${target_platform}" == "linux-64" ]]; then
    extra_args="${extra_args} --enable-libvpl"
    extra_args="${extra_args} --enable-vaapi"
  fi
elif [[ "${target_platform}" == osx-* ]]; then
  if [[ "${target_platform}" == osx-arm64 ]]; then
    extra_args="${extra_args} --enable-neon"
  else
    extra_args="${extra_args} --enable-videotoolbox"
  fi
  extra_args="${extra_args} --disable-gnutls"
  extra_args="${extra_args} --enable-libvpx"
  extra_args="${extra_args} --enable-pthreads"
  extra_args="${extra_args} --disable-libdrm"
  extra_args="${extra_args} --disable-librsvg"
  # See https://github.com/conda-forge/ffmpeg-feedstock/pull/115
  # why this flag needs to be removed.
  sed -i.bak s/-Wl,-single_module// configure
  PKG_CONFIG="${BUILD_PREFIX}/bin/pkg-config"
fi

if [[ ${target_platform} != win-64 ]]
then
  extra_args="${extra_args} --enable-libtesseract"
  extra_args="${extra_args} --enable-libvpx"
  extra_args="${extra_args} --enable-libass"
  extra_args="${extra_args} --enable-librsvg"
  extra_args="${extra_args} --enable-libshaderc"
fi

./configure \
        --prefix="${PREFIX}" \
        --cc=${CC} \
        --cxx=${CXX} \
        --nm=${NM} \
        --ar=${AR} \
        --enable-openssl \
        --enable-demuxer=dash \
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-libharfbuzz \
        --enable-libfontconfig \
        --enable-libopenh264 \
        --enable-libdav1d \
        --enable-libmp3lame \
        --enable-libaom \
        --enable-libsvtav1 \
        --enable-libxml2 \
        --enable-pic \
        --enable-shared \
        --enable-version3 \
        --enable-zlib \
        --enable-libvorbis \
        --enable-libopus \
        --enable-libwebp \
        --disable-ffplay \
        --disable-static \
        --disable-gpl \
        --disable-doc \
        --pkg-config=${PKG_CONFIG} \
        ${extra_args}

if [[ "${target_platform}" == win-* ]]; then
  # Don't install the def files, but intall the lib files instead
  sed -i 's/SLIB_INSTALL_EXTRA_LIB=$(SLIBNAME_WITH_MAJOR:$(SLIBSUF)=.def)/SLIB_INSTALL_EXTRA_LIB=$(SLIBNAME:$(SLIBSUF)=.lib)/' ffbuild/config.mak
  # install the lib files in the lib directory, not bin
  sed -i 's/SLIB_INSTALL_EXTRA_SHLIB=$(SLIBNAME:$(SLIBSUF)=.lib)/SLIB_INSTALL_EXTRA_SHLIB=/' ffbuild/config.mak

  # Their default DLLs include the version in the dll name
  # If we want to, we can uncomment the lines below to remove the version from the dll name
  # we don't need those version numbers because conda is our package manager
  # sed -i 's/SLIB_INSTALL_NAME=$(SLIBNAME_WITH_MAJOR)/SLIB_INSTALL_NAME=$(SLIBNAME)/' ffbuild/config.mak
  # sed -i 's/SLIBNAME_WITH_VERSION=$(SLIBPREF)$(FULLNAME)-$(LIBVERSION)$(SLIBSUF)/SLIBNAME_WITH_VERSION=$(SLIBNAME)/' ffbuild/config.mak
  # sed -i 's/SLIBNAME_WITH_MAJOR=$(SLIBPREF)$(FULLNAME)-$(LIBMAJOR)$(SLIBSUF)/SLIBNAME_WITH_MAJOR=$(SLIBNAME)/' ffbuild/config.mak
fi

make -j${CPU_COUNT}
make install

if [[ "${target_platform}" == win-* ]]; then
  if [[ "${UNISTD_CREATED}" == "1" ]]; then
      rm -f "${PREFIX}/include/unistd.h"
  fi
  if [[ "${LIBX264_LIB_CREATED}" == "1" ]]; then
    rm -f ${PREFIX}/lib/libx264.lib
  fi
fi
