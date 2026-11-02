#!/bin/sh
set -x
export PATH=/tc/arm-2009q3/bin:$PATH
cd /w/gccbuild
dpkg -x /tc/libgmp10.deb /opt/nl
dpkg -x /tc/libgmp-dev.deb /opt/nl
dpkg -x /tc/libmpfr6.deb /opt/nl
dpkg -x /tc/libmpfr-dev.deb /opt/nl
mkdir -p obj && cd obj
CC="gcc -std=gnu89 -fcommon" /tc/gcc_src/gcc-4.4.1/configure \
  --target=arm-none-linux-gnueabi \
  --prefix=/gnuarm \
  --with-sysroot=/tc/arm-2009q3/arm-none-linux-gnueabi/libc \
  --with-gmp=/opt/nl --with-mpfr=/opt/nl \
  --enable-languages=c --disable-nls --disable-shared --disable-bootstrap \
  --without-ppl --without-cloog --disable-libmudflap --disable-libssp \
  --disable-libgomp --disable-werror \
  CFLAGS="-std=gnu89 -fcommon -O1 -w" > /w/gccbuild/configure.log 2>&1
make -j2 > /w/gccbuild/make.log 2>&1 || make -j1 >> /w/gccbuild/make.log 2>&1
make install > /w/gccbuild/install.log 2>&1
echo BUILD-RC=$? > /w/gccbuild/RC
