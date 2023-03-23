#! /usr/bin/env bash

set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$ROOT/Sources/WireGuardKitGo"

cd "$SRC_ROOT"

BUILD_ROOT="$SRC_ROOT/out/build/"
ARTIFACT_IOS="$ROOT/lib/ios/libwg-go.a"
ARTIFACT_MACOS="$ROOT/lib/macos/libwg-go.a"

rm -rf "$ROOT/lib"
mkdir -p $(dirname "$ARTIFACT_IOS")
mkdir -p $(dirname "$ARTIFACT_MACOS")

rm -rf "$BUILD_ROOT" "$ARTIFACT"
mkdir -p "$BUILD_ROOT"

# Create a patched goroot using patches needed for iOS
GOROOT="$BUILD_ROOT/goroot/" # Not exported yet, still need the original GOROOT to copy
mkdir -p "$GOROOT"
rsync --exclude="pkg/obj/go-build" -a "$(go env GOROOT)/" "$GOROOT/"
export GOROOT
cat goruntime-*.diff | patch -p1 -fN -r- -d "$GOROOT"

BUILD_CFLAGS="-fembed-bitcode -Wno-unused-command-line-argument"

LIPO_IOS_INPUT_LIBS=()
LIPO_MACOS_INPUT_LIBS=()

# Build the library for each target
function build_arch() {
    local ARCH="$1"
    local GOARCH="$2"
    local SDKNAME="$3"
    local GOTAG=""
    if [[ "$SDKNAME" == "iphoneos" ]]; then
        local GOTAG="ios"
    elif [[ "$SDKNAME" == "iphonesimulator" ]]; then
        local GOTAG="ios"
    elif [[ "$SDKNAME" == "macosx" ]]; then
        local GOTAG="darwin"
    fi
    # Find the SDK path
    local SDKPATH
    SDKPATH="$(xcrun --sdk "$SDKNAME" --show-sdk-path)"
    local PLATFORM_CFLAGS=""
    if [[ "$SDKNAME" == "iphoneos" ]]; then
        PLATFORM_CFLAGS="-miphoneos-version-min=15.0"
    elif [[ "$SDKNAME" == "iphonesimulator" ]]; then
        PLATFORM_CFLAGS="-miphonesimulator-version-min=15.0"
    elif [[ "$SDKNAME" == "macosx" ]]; then
        PLATFORM_CFLAGS="-mmacosx-version-min=12.0"
    fi
    local FULL_CFLAGS="$BUILD_CFLAGS -isysroot $SDKPATH -arch $ARCH $PLATFORM_CFLAGS"
    local LIBPATH="$BUILD_ROOT/$SDKNAME/libwg-go-$ARCH.a"

    CGO_ENABLED=1 CGO_CFLAGS="$FULL_CFLAGS" CGO_LDFLAGS="$FULL_CFLAGS" GOOS=darwin GOARCH="$GOARCH" \
        go build -tags $GOTAG -ldflags=-w -trimpath -v -o "$LIBPATH" -buildmode c-archive
    rm -f "$BUILD_ROOT/libwg-go-$ARCH.h"
    if [[ "$SDKNAME" == "iphoneos" ]]; then
        LIPO_IOS_INPUT_LIBS+=($LIBPATH)
    elif [[ "$SDKNAME" == "iphonesimulator" ]]; then
        LIPO_IOS_INPUT_LIBS+=($LIBPATH)
    elif [[ "$SDKNAME" == "macosx" ]]; then
        LIPO_MACOS_INPUT_LIBS+=($LIBPATH)
    fi
}

build_arch x86_64 amd64 iphonesimulator
build_arch arm64 arm64 iphoneos
build_arch arm64 arm64 macosx
build_arch x86_64 amd64 macosx

# Create the fat static library including all architectures

LIPO="${LIPO:-lipo}"
"$LIPO" -create -output "$ARTIFACT_IOS" "${LIPO_IOS_INPUT_LIBS[@]}"

# MacOS
"$LIPO" -create -output "$ARTIFACT_MACOS" "${LIPO_MACOS_INPUT_LIBS[@]}"
