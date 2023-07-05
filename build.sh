#!/bin/bash

git_clean=1 # SEE README
MJ="j4" # For parallel compilation
dist_name="dist" # Where all binaries will be installed.

cd $(dirname "$0")

set -euo pipefail

source ./utils.sh

FFMPEG_PKG_CONFIG_PATH=""
FFMPEG_CFLAGS=""
FFMPEG_LDFLAGS=""

autotools_options=""
cmake_options=""

source ./xcomp.sh

dist_relative_path=$dist_name/$target_os/$target_arch/
dist=${PWD}/$dist_relative_path
mkdir -p $dist

#FIXME: skipping xvid
mods="aom jpeg ocamr ogg openssl opus sdl theora voamrwbenc vorbis vpx webp x264 x265 zlib ffmpeg"

for mod in $mods; do

  source recipes/$mod.sh

  pushd modules/$mod > /dev/null

  # If the submodule hasn't been pull, pull it.
  if test -n "$(find ./ -maxdepth 0 -empty)" ; then
    echo "Pulling $mod …"
    git submodule update --init .
  fi

  if [ ! -d $dist/$mod ]; then
    maybe_clean_module
    if [ $cross_compiling -eq 1 ]; then
      setup_cross $mod
    fi
    echo "Compiling ${mod}… "
    build $mod
    # Cleanup some exports after modules
    unset_toolchain_bins
    # Ensure that no shared library are installed.
    rm_dll $mod
    maybe_clean_module
  else
    echo "$mod already built (rm -rf $dist_relative_path/$mod to rebuild). Skipped."
  fi

  post $mod

  popd > /dev/null

done

echo "Packaging…"

cd $dist_name
tmpdir=ffmpeg-$target
rm -rf $tmpdir
mkdir -p $tmpdir/presets
cp $dist/ffmpeg/bin/* $tmpdir
cp $dist/ffmpeg/share/ffmpeg/*.ffpreset $tmpdir/presets
tar -cjvf ffmpeg-$target.tar.bz2 $tmpdir
rm -rf $tmpdir
cd ..
