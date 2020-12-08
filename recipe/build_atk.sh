#! /bin/bash

set -ex

# necessary to ensure the gobject-introspection-1.0 pkg-config file gets found
# meson needs this to determine where the g-ir-scanner script is located
export PKG_CONFIG="${BUILD_PREFIX}/bin/pkg-config"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH_FOR_BUILD=$PKG_CONFIG_PATH

if [ "${CONDA_BUILD_CROSS_COMPILATION}" = "1" ]; then
    # We're not actually building any Python bindings and this interfers with meson itself
    unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
fi

meson ${MESON_ARGS} builddir --prefix=$PREFIX
meson ${MESON_ARGS} configure -D enable_docs=false builddir
ninja -v -C builddir
ninja -C builddir install

cd $PREFIX
find . -type f -name "*.la" -exec rm -rf '{}' \; -print
