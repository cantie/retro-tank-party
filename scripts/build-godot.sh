#!/bin/bash

SOURCE_DIR=$1
BUILD_DIR=$2
BUILD_TYPE=$3

die() {
	echo "$@" > /dev/stderr
	exit 1
}

if [ -z "$SOURCE_DIR" -o -z "$BUILD_DIR" -o -z "$BUILD_TYPE" ]; then
	die "Must pass in three arguments: SOURCE_DIR, BUILD_DIR and BUILD_TYPE"
fi

if [ ! -f "$SOURCE_DIR/DOWNLOAD_URL" ]; then
	die "Source directory is missing required DOWNLOAD_URL file"
fi

DOWNLOAD_URL=$(cat "$SOURCE_DIR/DOWNLOAD_URL")

if [ ! -d "$BUILD_DIR" ]; then
	mkdir "$BUILD_DIR" \
		|| die "Unable to create BUILD_DIR: $BUILD_DIR"

	(cd "$BUILD_DIR" && curl -L "$DOWNLOAD_URL" | tar -xz --strip-components=1) \
		|| die "Unable to download Godot source from DOWNLOAD_URL: $DOWNLOAD_URL"
	
	# TODO: apply any patches!
else
	echo " !! WARNING: Reusing existing build directory !! "
fi

NUM_CORES=${NUM_CORES:-4}

IMAGE=""
CMD=""

case "$BUILD_TYPE" in
	linux-32|linux-64)
		IMAGE="godot-linux"
		CMD="build-linux.sh"
		;;
	windows-32|windows-64)
		IMAGE="godot-windows"
		CMD="build-windows.sh"
		;;
	html5)
		IMAGE="godot-javascript"
		CMD="build-html5.sh"
		;;
	*)
		die "Unknown BUILD_TYPE: $BUILD_TYPE"
		;;
esac

BITS=""
case "$BUILD_TYPE" in
	*-32*)
		BITS="32"
		;;
	*-64*)
		BITS="64"
		;;
esac

MONO=""
case "$BUILD_TYPE" in
	*-mono*)
		MONO="yes"
		;;
esac

SCONS_OPTS=${SCONS_OPTS:-}
if [ -d "$SOURCE_DIR/modules" ]; then
	SCONS_OPTS="$SCONS_OPTS custom_modules=/src/modules"
fi

if [ -n "$GODOT_BUILD_REGISTRY" ]; then
	IMAGE="$GODOT_BUILD_REGISTRY/$IMAGE"
fi

podman run --rm --systemd=false -v "$(realpath $BUILD_DIR):/build" -v "$(realpath $SOURCE_DIR):/src" -v "$(pwd)/scripts/godot:/scripts" -w /build -e NUM_CORES="$NUM_CORES" -e BITS="$BITS" -e MONO="$MONO" -e "SCONS_OPTS=$SCONS_OPTS" "$IMAGE" /scripts/$CMD $BUILD_TYPE

