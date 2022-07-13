# Maintainer: Frederik Schwan <freswa at archlinux dot org>
# Contributor: Jonathon Fernyhough <jonathon+m2x+dev>
# Contributor: Giancarlo Razzolini <grazzolini@archlinux.org>
# Contributor:  Bartłomiej Piotrowski <bpiotrowski@archlinux.org>
# Contributor: Allan McRae <allan@archlinux.org>
# Contributor: Daniel Kozak <kozzi11@gmail.com>

pkgname=(gdmd)
pkgver=11.3.0
_majorver=${pkgver%%.*}
_gdmd_pkgver=0.1.0
pkgrel=4
pkgdesc="D frontend for GCC (11.x.x)"
arch=(riscv64)
license=(GPL LGPL FDL custom)
url='https://gcc.gnu.org'
depends=("gcc11=$pkgver-$pkgrel")
makedepends=(binutils doxygen git libmpc python libisl.so)
options=(!emptydirs !lto staticlibs)
_libdir=usr/lib/gcc/$CHOST/${pkgver%%+*}
source=(https://sourceware.org/pub/gcc/releases/gcc-${pkgver}/gcc-${pkgver}.tar.xz{,.sig}
        gdc_phobos_path.patch
        https://github.com/D-Programming-GDC/gdmd/archive/refs/tags/script-${_gdmd_pkgver}.tar.gz
)

validpgpkeys=(F3691687D867B81B51CE07D9BBE43771487328A9  # bpiotrowski@archlinux.org
              86CFFCA918CF3AF47147588051E8B148A9999C34  # evangelos@foutrelis.com
              13975A70E63C361C73AE69EF6EEB81F8981C74C7  # richard.guenther@gmail.com
              D3A93CAD751C2AF4F8C7AD516C35B99309B5FA62) # Jakub Jelinek <jakub@redhat.com>
b2sums=('7e562d25446ca4ab9fe8cdb714866f66aba3744d78bf84f31bfb097c1a981e4c7f990cb1e6bcfec5ae6671836a4984e2b70eb8fed81dcef5e244f88da8623469'
        'SKIP'
        'b80994d8e43e5466ceb5c085c6ce31439f0965846cb7343a5a506e4e867abb21f35efbe344945b4d0fc2c6dc01357815490081c3a594763c13ceefb1ccce993c'
        'f613c1faf7abb9f72990e21dfdf21e69f4d83fde5d7d6a8a0ccac16a21c0cf39f2d03b2fba7f9b19009b1e2198413c99653635a32cbad48bb8b5dfbf5da1ebab')

prepare() {
  [[ ! -d gcc ]] && ln -s gcc-${pkgver/+/-} gcc
  cd gcc

  # Do not run fixincludes
  sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

  # Arch Linux installs x86_64 libraries /lib
  sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64

  # D hacks
  patch -Np1 -i "$srcdir/gdc_phobos_path.patch"

  mkdir -p "$srcdir/gcc-build"
}

build() {
    local _confflags=(
      --prefix=/usr
      --libdir=/usr/lib
      --libexecdir=/usr/lib
      --mandir=/usr/share/man
      --infodir=/usr/share/info
      --with-bugurl=https://bugs.archlinux.org/
      --with-linker-hash-style=gnu
      --with-system-zlib
      --enable-__cxa_atexit
      --enable-cet=auto
      --disable-checking
      --enable-clocale=gnu
      --enable-default-pie
      --enable-default-ssp
      --enable-gnu-indirect-function
      --enable-gnu-unique-object
      --enable-linker-build-id
      --enable-lto
      --enable-plugin
      --enable-shared
      --enable-threads=posix
      --disable-libssp
      --disable-libstdcxx-pch
      --disable-werror
      --enable-link-serialization=1
      --program-suffix=-${_majorver}
      --enable-version-specific-runtime-libs
      --disable-multilib
      gdc_include_dir=/usr/include/dlang/gdc
)

  cd gcc-build

  CFLAGS=${CFLAGS/-Wp,-D_FORTIFY_SOURCE=2/}
  CXXFLAGS=${CXXFLAGS/-Wp,-D_FORTIFY_SOURCE=2/}

  # Credits @allanmcrae
  # https://github.com/allanmcrae/toolchain/blob/f18604d70c5933c31b51a320978711e4e6791cf1/gcc/PKGBUILD
  # TODO: properly deal with the build issues resulting from this
  CFLAGS=${CFLAGS/-Werror=format-security/}
  CXXFLAGS=${CXXFLAGS/-Werror=format-security/}

  "$srcdir/gcc/configure" \
    --enable-languages=d \
    --disable-bootstrap \
    "${_confflags[@]:?_confflags unset}"

  # see https://bugs.archlinux.org/task/71777 for rationale re *FLAGS handling
  make -O STAGE1_CFLAGS="-O2" \
          BOOT_CFLAGS="$CFLAGS" \
          BOOT_LDFLAGS="$LDFLAGS" \
          LDFLAGS_FOR_TARGET="$LDFLAGS"
}

package() {
  cd gcc-build
  make -C gcc DESTDIR="$pkgdir" d.install-{common,man,info}

  install -Dm755 gcc/gdc "$pkgdir"/usr/bin/gdc
  install -Dm755 gcc/d21 "$pkgdir"/"$_libdir"/d21

  make -C $CHOST/libphobos DESTDIR="$pkgdir" install
  mv "$pkgdir/$_libdir/"lib{gphobos,gdruntime}.so* "$pkgdir/usr/lib/"
  cp "$pkgdir/$_libdir/"libgphobos.spec "$pkgdir/usr/lib/"

  install -d "$pkgdir"/usr/include/dlang
  ln -s /"${_libdir}"/include/d "$pkgdir"/usr/include/dlang/gdc

  # Install Runtime Library Exception
  install -d "$pkgdir/usr/share/licenses/$pkgname/"
  ln -s /usr/share/licenses/gcc11-libs/RUNTIME.LIBRARY.EXCEPTION \
    "$pkgdir/usr/share/licenses/$pkgname/"

  cd "$srcdir"/gdmd-script-${_gdmd_pkgver}
  mkdir -p "$pkgdir"/usr/bin
  mkdir -p "$pkgdir"/usr/share/man/man1
  make DESTDIR="$pkgdir" prefix=/usr install
}
