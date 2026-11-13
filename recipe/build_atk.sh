#! /bin/bash

set -exuo pipefail

# get meson to find pkg-config when cross compiling
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

# need to find gobject-introspection-1.0 as a "native" (build) pkg-config dep
# meson uses PKG_CONFIG_PATH to search when not cross-compiling and
# PKG_CONFIG_PATH_FOR_BUILD when cross-compiling,
# so add the build prefix pkgconfig path to the appropriate variables
export PKG_CONFIG_PATH_FOR_BUILD=$BUILD_PREFIX/lib/pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$BUILD_PREFIX/lib/pkgconfig

meson_config_args=(
    -Ddocs=false
)

# Follow the pattern of https://github.com/conda-forge/gdk-pixbuf-feedstock/pull/28/
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
    unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
    (
        mkdir -p native-build

        export CC=$CC_FOR_BUILD
        export AR=($CC_FOR_BUILD -print-prog-name=ar)
        export NM=($CC_FOR_BUILD -print-prog-name=nm)
        export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}
        export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig
        export host_alias=$build_alias

        # Unset them as we're ok with builds that are either slow or non-portable
        unset CFLAGS
        unset CPPFLAGS

        meson setup native-build \
            "${meson_config_args[@]}" \
            --buildtype=release \
            --prefix=$BUILD_PREFIX \
            -Dintrospection=true \
            -Dlibdir=lib \
            --wrap-mode=nofallback

        export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-save.sh
        ninja -j ${CPU_COUNT} -C native-build -v
        ninja -j ${CPU_COUNT} -C native-build install

        # Store generated introspection information
        mkdir -p introspection/gir introspection/typelib
        cp -vap $BUILD_PREFIX/lib/girepository-1.0/Atk*.typelib introspection/typelib/
        cp -vap $BUILD_PREFIX/share/gir-1.0/Atk*.gir introspection/gir/
    )

    export GI_CROSS_LAUNCHER=$BUILD_PREFIX/libexec/gi-cross-launcher-load.sh
    meson_config_args+=(-Dintrospection=false)
else
    meson_config_args+=(-Dintrospection=true)
fi

meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --wrap-mode=nofallback
ninja -j ${CPU_COUNT} -C builddir -v
ninja -j ${CPU_COUNT} -C builddir install

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  # Install GIR/typelib files from the native build
  mkdir -p $PREFIX/lib/girepository-1.0 $PREFIX/share/gir-1.0
  cp -vap introspection/typelib/* $PREFIX/lib/girepository-1.0/
  cp -vap introspection/gir/* $PREFIX/share/gir-1.0/
fi
