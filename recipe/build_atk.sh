#! /bin/bash

set -ex

# necessary to ensure the gobject-introspection-1.0 pkg-config file gets found
# meson needs this to determine where the g-ir-scanner script is located
export PKG_CONFIG_PATH_FOR_BUILD=$BUILD_PREFIX/lib/pkgconfig

meson ${MESON_ARGS} builddir --prefix=$PREFIX
meson ${MESON_ARGS} configure -D enable_docs=false builddir
ninja -v -C builddir
ninja -C builddir install

cd $PREFIX
find . -type f -name "*.la" -exec rm -rf '{}' \; -print
