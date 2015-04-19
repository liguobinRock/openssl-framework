#!/bin/bash

###############################################################################
##                                                                           ##
## Build and package OpenSSL static libraries for OSX/iOS                    ##
##                                                                           ##
## This script is in the public domain.                                      ##
## Creator     : Laurent Etiemble                                            ##
##                                                                           ##
###############################################################################

## --------------------
## Parameters
## --------------------

VERSION=1.0.2a
OSX_SDK=10.10
MIN_OSX=10.6
IOS_SDK=8.3

FWNAME="openssl"

# These values are used to avoid version detection
FAKE_NIBBLE=0x102031af
FAKE_TEXT="OpenSSL 0.9.8y 5 Feb 2013"

## --------------------
## Variables
## --------------------

DEVELOPER_DIR=`xcode-select -print-path`
if [ ! -d $DEVELOPER_DIR ]; then
  echo "Please set up Xcode correctly. '$DEVELOPER_DIR' is not a valid developer tools folder."
  exit 1
fi
if [ ! -d "$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX$OSX_SDK.sdk" ]; then
  echo "The OS X SDK $OSX_SDK was not found."
  exit 1
fi
if [ ! -d "$DEVELOPER_DIR/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOS_SDK.sdk" ]; then
  echo "The iPhoneOS SDK $IOS_SDK was not found."
  exit 1
fi

if [ ! -d "$DEVELOPER_DIR/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$IOS_SDK.sdk" ]; then
  echo "The iPhoneSimulator SDK $IOS_SDK was not found."
  exit 1
fi

BASE_DIR=`pwd`
BUILD_DIR="$BASE_DIR/build"
DIST_DIR="$BASE_DIR/dist"
FILES_DIR="$BASE_DIR/files"

OPENSSL_NAME="openssl-$VERSION"
OPENSSL_FILE="$OPENSSL_NAME.tar.gz"
OPENSSL_URL="http://www.openssl.org/source/$OPENSSL_FILE"
OPENSSL_PATH="$FILES_DIR/$OPENSSL_FILE"

## --------------------
## Main
## --------------------

_unarchive() {
  # Expand source tree if needed
  if [ ! -d "$SRC_DIR" ]; then
    echo "Unarchive sources for $PLATFORM-$ARCH..."
    (cd "$BUILD_DIR"; tar -zxf "$OPENSSL_PATH"; mv "$OPENSSL_NAME" "$SRC_DIR";)
  fi
}

_configure() {
  # Configure
  if [ "x$DONT_CONFIGURE" == "x" ]; then
    echo "Configuring $PLATFORM-$ARCH..."
    (cd "$SRC_DIR"; CROSS_TOP="$CROSS_TOP" CROSS_SDK="$CROSS_SDK" CC="$CC" ./Configure --prefix="$DST_DIR" -no-apps "$COMPILER" > "$LOG_FILE" 2>&1)
  fi
}

_build() {
  # Build
  if [ "x$DONT_BUILD" == "x" ]; then
    echo "Building $PLATFORM-$ARCH..."
    (cd "$SRC_DIR"; CROSS_TOP="$CROSS_TOP" CROSS_SDK="$CROSS_SDK" CC="$CC" make -j >> "$LOG_FILE" 2>&1)
  fi
}

build_osx() {
  ARCHS="x86_64"
  for ARCH in $ARCHS; do
    PLATFORM="MacOSX"
    COMPILER="darwin-i386-cc"
    SRC_DIR="$BUILD_DIR/$PLATFORM-$ARCH"
    DST_DIR="$DIST_DIR/$PLATFORM-$ARCH"
    LOG_FILE="$BASE_DIR/$PLATFORM$OSX_SDK-$ARCH.log"

    if [ -d "$DST_DIR" ]; then
      continue
    fi

    # Select the compiler
    if [ "$ARCH" == "i386" ]; then
      COMPILER="darwin-i386-cc"
    else
      COMPILER="darwin64-x86_64-cc"
    fi

    CROSS_TOP="$DEVELOPER_DIR/Platforms/$PLATFORM.platform/Developer"
    CROSS_SDK="$PLATFORM$OSX_SDK.sdk"
    CC="$DEVELOPER_DIR/usr/bin/gcc -arch $ARCH"

    _unarchive
    _configure

    # Patch Makefile
    sed -ie "s/^CFLAG= -/CFLAG=  -mmacosx-version-min=$MIN_OSX -/" "$SRC_DIR/Makefile"
    # Patch versions
    sed -ie "s/^#define OPENSSL_VERSION_NUMBER.*$/#define OPENSSL_VERSION_NUMBER  $FAKE_NIBBLE/" "$SRC_DIR/crypto/opensslv.h"
    sed -ie "s/^#define OPENSSL_VERSION_TEXT.*$/#define OPENSSL_VERSION_TEXT  \"$FAKE_TEXT\"/" "$SRC_DIR/crypto/opensslv.h"

    _build
  done
}

build_iphoneos() {
  echo "building"
  ARCHS="armv7 armv7s arm64"
  for ARCH in $ARCHS; do
    PLATFORM="iPhoneOS"
    COMPILER="iphoneos-cross"
    SRC_DIR="$BUILD_DIR/$PLATFORM-$ARCH"
    DST_DIR="$DIST_DIR/$PLATFORM-$ARCH"
    LOG_FILE="$BASE_DIR/$PLATFORM$IOS_SDK-$ARCH.log"

    if [ -d "$DST_DIR" ]; then
      continue
    fi

    # Select the compiler
    if [ "$ARCH" == "arm64" ]; then
      MIN_IOS="7.0"
    else
      MIN_IOS="4.0"
    fi

    CROSS_TOP="$DEVELOPER_DIR/Platforms/$PLATFORM.platform/Developer"
    CROSS_SDK="$PLATFORM$IOS_SDK.sdk"
    CC="clang -arch $ARCH"

    _unarchive
    _configure

    # Patch Makefile
    sed -ie "s/^CFLAG= -/CFLAG=  -miphoneos-version-min=$MIN_IOS -/" "$SRC_DIR/Makefile"
    # Patch versions
    sed -ie "s/^#define OPENSSL_VERSION_NUMBER.*$/#define OPENSSL_VERSION_NUMBER  $FAKE_NIBBLE/" "$SRC_DIR/crypto/opensslv.h"
    sed -ie "s/^#define OPENSSL_VERSION_TEXT.*$/#define OPENSSL_VERSION_TEXT  \"$FAKE_TEXT\"/" "$SRC_DIR/crypto/opensslv.h"

    _build
  done
}

build_iphonesimulator() {
  ARCHS="x86_64"
  for ARCH in $ARCHS; do
    PLATFORM="iPhoneSimulator"
    COMPILER="iphoneos-cross"
    SRC_DIR="$BUILD_DIR/$PLATFORM-$ARCH"
    DST_DIR="$DIST_DIR/$PLATFORM-$ARCH"
    LOG_FILE="$BASE_DIR/$PLATFORM$IOS_SDK-$ARCH.log"

    if [ -d "$DST_DIR" ]; then
      continue
    fi

    # Select the compiler
    if [ "$ARCH" == "x86_64" ]; then
      MIN_IOS="7.0"
    else
      MIN_IOS="4.0"
    fi

    CROSS_TOP="$DEVELOPER_DIR/Platforms/$PLATFORM.platform/Developer"
    CROSS_SDK="$PLATFORM$IOS_SDK.sdk"
    CC="clang -arch $ARCH"

    _unarchive
    _configure

    # Patch Makefile
    sed -ie "s/^CFLAG= -/CFLAG=  -miphoneos-version-min=$MIN_IOS -/" "$SRC_DIR/Makefile"
    # Patch versions
    sed -ie "s/^#define OPENSSL_VERSION_NUMBER.*$/#define OPENSSL_VERSION_NUMBER  $FAKE_NIBBLE/" "$SRC_DIR/crypto/opensslv.h"
    sed -ie "s/^#define OPENSSL_VERSION_TEXT.*$/#define OPENSSL_VERSION_TEXT  \"$FAKE_TEXT\"/" "$SRC_DIR/crypto/opensslv.h"

    _build
  done
}

distribute_osx() {
  PLATFORM="MacOSX"
  NAME="$OPENSSL_NAME-$PLATFORM"
  DIR="$DIST_DIR/$NAME"
  FILES="libcrypto.a libssl.a"
  mkdir -p "$DIR/include"
  mkdir -p "$DIR/lib"

  echo "$VERSION" > "$DIR/VERSION"
  cp "$BUILD_DIR/MacOSX-x86_64/LICENSE" "$DIR"
  cp -LR "$BUILD_DIR/MacOSX-x86_64/include/" "$DIR/include"

  # Alter rsa.h to make Swift happy
  sed -i .bak 's/const BIGNUM \*I/const BIGNUM *i/g' "$DIR/include/openssl/rsa.h"

  for f in $FILES; do
    lipo -create \
\    "$BUILD_DIR/MacOSX-x86_64/$f" \
    -output "$DIR/lib/$f"
  done
}

distribute_iphoneos() {
  PLATFORM="iPhoneOS"
  NAME="$OPENSSL_NAME-$PLATFORM"
  DIR="$DIST_DIR/$NAME"
  FILES="libcrypto.a libssl.a"
  mkdir -p "$DIR/include"
  mkdir -p "$DIR/lib"

  echo "$VERSION" > "$DIR/VERSION"
  cp "$BUILD_DIR/iPhoneOS-armv7/LICENSE" "$DIR"
  cp -LR "$BUILD_DIR/iPhoneOS-armv7/include/" "$DIR/include"

  # Alter rsa.h to make Swift happy
  sed -i .bak 's/const BIGNUM \*I/const BIGNUM *i/g' "$DIR/include/openssl/rsa.h"

  for f in $FILES; do
    lipo -create \
    "$BUILD_DIR/iPhoneOS-arm64/$f" \
    "$BUILD_DIR/iPhoneOS-armv7/$f" \
    "$BUILD_DIR/iPhoneOS-armv7s/$f" \
    -output "$DIR/lib/$f"
  done
}

distribute_iphonesimulator() {
  PLATFORM="iPhoneSimulator"
  NAME="$OPENSSL_NAME-$PLATFORM"
  DIR="$DIST_DIR/$NAME"
  FILES="libcrypto.a libssl.a"
  mkdir -p "$DIR/include"
  mkdir -p "$DIR/lib"

  echo "$VERSION" > "$DIR/VERSION"
  cp "$BUILD_DIR/iPhoneSimulator-x86_64/LICENSE" "$DIR"
  cp -LR "$BUILD_DIR/iPhoneSimulator-x86_64/include/" "$DIR/include"

  # Alter rsa.h to make Swift happy
  sed -i .bak 's/const BIGNUM \*I/const BIGNUM *i/g' "$DIR/include/openssl/rsa.h"

  for f in $FILES; do
    lipo -create \
    "$BUILD_DIR/iPhoneSimulator-x86_64/$f" \
    -output "$DIR/lib/$f"
  done

}

have_not_framework() {
  [[ -e "$FWNAME.framework" ]] && return 1 || return 0
}

make_framework() {
  FWLIBS=""
  PLATFORM=iPhoneOS
  NAME="$OPENSSL_NAME-$PLATFORM"
  FILES="libssl.a libcrypto.a"
  mkdir -p $FWNAME.framework/Headers
  find build -type d -maxdepth 1 -mindepth 1 \
  | while read SRC_DIR; do
    echo $(basename $SRC_DIR) \
    | rev \
    | cut -f1 -d- \
    | rev
  done \
  | sort \
  | uniq \
  | while read ARCH; do
    find build -type d -maxdepth 1 -mindepth 1 -name "*-$ARCH" \
    | head -n1
  done \
  | while read ARCH_DIR; do
    for f in $FILES; do
      FWLIBS="$(find $ARCH_DIR -name "$f" -type f) $FWLIBS"
    done
    libtool -no_warning_for_no_symbols -static -o $FWNAME.framework/$FWNAME $FWLIBS
  done
  find $DIST_DIR/$NAME/include -type f | while read HEADER_FILE; do
    cp $HEADER_FILE $FWNAME.framework/Headers/$(basename $HEADER_FILE)
  done

}

# Create folders
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$FILES_DIR"

# Retrieve OpenSSL tarbal if needed
if [ ! -e "$OPENSSL_PATH" ]; then
  curl "$OPENSSL_URL" -o "$OPENSSL_PATH"
fi

#if $(have_not_framework); then
#  build_osx
  build_iphoneos
  build_iphonesimulator

#  distribute_osx
  distribute_iphoneos
  distribute_iphonesimulator
  make_framework
#fi
