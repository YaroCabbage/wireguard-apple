#!/bin/bash

set -euo pipefail

if [ ! -d lib ]; then
    echo "Please build libwg-go first"
    exit 1
fi

FWNAME=libwg-go
FWROOT=frameworks

if [ -d $FWROOT ]; then
    echo "Removing previous $FWNAME.framework copies"
    rm -rf $FWROOT
fi

function check_bitcode() {
    local FWDIR=$1

    BITCODE_PATTERN="__bitcode"

    if otool -l "$FWDIR/$FWNAME" | grep "${BITCODE_PATTERN}" >/dev/null; then
        echo "INFO: $FWDIR contains Bitcode"
    else
        echo "INFO: $FWDIR doesn't contain Bitcode"
    fi
}

function build_framework_for_platform() {
    local PLATFORM="$1"
    local PLATFORM_DIR="$FWROOT/$PLATFORM"
    local FWDIR="$PLATFORM_DIR/$FWNAME.framework"
    local LIBPATH="lib/$PLATFORM/libwg-go.a"
    if [[ -e "$LIBPATH" ]]; then
        echo "Creating framework for $PLATFORM"
        mkdir -p $FWDIR/Headers
        libtool -static -o $FWDIR/$FWNAME $LIBPATH
        #cp -r include/* $FWDIR/Headers/
        cp -L assets/$PLATFORM/Info.plist $FWDIR/Info.plist
        echo "Created $FWDIR"
        check_bitcode $FWDIR
    else
        echo "Skipped framework for $PLATFORM"
    fi
}

build_framework_for_platform ios
build_framework_for_platform macos    
