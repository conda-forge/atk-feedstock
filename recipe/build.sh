#! /bin/bash

set -ex

if [[ $(uname) == Darwin ]]; then
  export CC=clang
  export CXX=clang++
  export CPPFLAGS="$CPPFLAGS -I$PREFIX/include"
  export LDFLAGS="$LDFLAGS -L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -headerpad_max_install_names"
  export LIBRARY_SEARCH_VAR=DYLD_FALLBACK_LIBRARY_PATH
  export MACOSX_DEPLOYMENT_TARGET="10.9"
  export CXXFLAGS="-stdlib=libc++ $CXXFLAGS"
elif [ "$(uname)" == "Linux" ] ; then
  export CPPFLAGS="-I${PREFIX}/include $CPPFLAGS"
  export LDFLAGS="-L${PREFIX}/lib $LDFLAGS"
fi

meson builddir --prefix=$PREFIX --libdir=$PREFIX/lib
meson configure -D enable_docs=false builddir
ninja -v -C builddir
ninja -C builddir install

cd $PREFIX
find . -type f -name "*.la" -exec rm -rf '{}' \; -print
