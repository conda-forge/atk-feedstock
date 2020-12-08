#! /bin/bash

set -ex

# necessary to ensure the gobject-introspection-1.0 pkg-config file gets found
# meson needs this to determine where the g-ir-scanner script is located
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig

meson ${MESON_ARGS} builddir
meson ${MESON_ARGS} configure -D enable_docs=false builddir
ninja -v -C builddir
ninja -C builddir install

cd $PREFIX
find . -type f -name "*.la" -exec rm -rf '{}' \; -print
