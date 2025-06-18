#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [--release] [--unit] [--integration] [--clean]"
    echo "  --release       Build only the module; clone Valkey for valkeymodule.h"
    echo "  --unit          Run unit tests (clones Valkey for header)"
    echo "  --integration   Run integration tests"
    echo "  --clean         Remove build artifacts and exit"
    exit 1
}

SCRIPT_DIR=$(pwd)
BUILD_DIR="$SCRIPT_DIR/build"
RUN_UNIT=1
RUN_INTEGRATION=1
RELEASE_BUILD=0
CLEAN_BUILD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release)
            RELEASE_BUILD=1
            RUN_UNIT=0
            RUN_INTEGRATION=0
            ;;
        --unit)
            RUN_UNIT=1
            RUN_INTEGRATION=0
            RELEASE_BUILD=1
            ;;
        --integration)
            RUN_UNIT=0
            RUN_INTEGRATION=1
            ;;
        --clean)
            CLEAN_BUILD=1
            RUN_UNIT=0
            RUN_INTEGRATION=0
            ;;
        *)
            usage
            ;;
    esac
    shift
done

if [ $CLEAN_BUILD -eq 1 ]; then
    echo "Cleaning build artifacts..."
    rm -rf "$BUILD_DIR" tst/integration/valkeytests tst/integration/.build src/include
    echo "Clean completed"
    exit 0
fi

if [ -z "$SERVER_VERSION" ]; then
    echo "SERVER_VERSION environment variable is not set. Defaulting to \"unstable\"."
    export SERVER_VERSION="unstable"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

CMAKE_FLAGS=""
if [ -n "${ASAN_BUILD}" ]; then
    CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON"
else
    CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release"
fi

if [ $RELEASE_BUILD -eq 1 ]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DRELEASE_BUILD=ON"
else
    CMAKE_FLAGS="$CMAKE_FLAGS -DRELEASE_BUILD=OFF"
fi

if [ -z "${CFLAGS}" ]; then
    cmake .. -DVALKEY_VERSION=${SERVER_VERSION} ${CMAKE_FLAGS}
else
    cmake .. -DVALKEY_VERSION=${SERVER_VERSION} -DCFLAGS="${CFLAGS}" ${CMAKE_FLAGS}
fi

make -j

if [ $RELEASE_BUILD -eq 1 ] && [ $RUN_UNIT -eq 0 ] && [ $RUN_INTEGRATION -eq 0 ]; then
    echo "Release build completed"
    exit 0
fi

if [ $RUN_UNIT -eq 1 ]; then
    echo "Running unit tests..."
    make -j unit
fi

cd "$SCRIPT_DIR"

if [ $RUN_INTEGRATION -eq 1 ]; then
    REQUIREMENTS_FILE="requirements.txt"
    if command -v pip > /dev/null 2>&1; then
        pip install -r "$SCRIPT_DIR/$REQUIREMENTS_FILE"
    elif command -v pip3 > /dev/null 2>&1; then
        pip3 install -r "$SCRIPT_DIR/$REQUIREMENTS_FILE"
    else
        echo "Error: Neither pip nor pip3 is available."
        exit 1
    fi
    export MODULE_PATH="$BUILD_DIR/src/libjson.so"
    echo "Running integration tests..."
    cd "$BUILD_DIR"
    make -j test
fi

echo "Build script completed"
