#!/bin/bash

PLATFORM=${1:-all}
BUILD=${2:-both}

RELEASE_URL=https://github.com/godotengine/webrtc-native/releases/download/1.1.0-stable/godot-gdnative-webrtc.zip

download() {
	if `which wget >/dev/null 2>&1`; then
		wget "$1" -O "$2"
	else
		curl -L "$1" -o "$2"
	fi
}

# Since all platforms builds are now in the same download, we aren't using either
# $PLATFORM or $BUILD for anything.

download "$RELEASE_URL" godot-webrtc-native.zip
unzip -o -a godot-webrtc-native.zip
rm godot-webrtc-native.zip
