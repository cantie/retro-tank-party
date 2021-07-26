#!/bin/bash

SOURCE_DIR=${SOURCE_DIR:-godot}
BUILD_DIR=${SOURCE_DIR:-build/godot}

die() {
	echo "$@" > /dev/stderr
	exit 1
}

if [ -z "$BUILD_TYPE" ]; then
	die "The BUILD_TYPE environment variable must be set"
fi

if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" -o -z "$S3_BUCKET_NAME" ]; then
	die "The AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and S3_BUCKET_NAME environment variables must be set"
fi

if [ ! -d "$SOURCE_DIR" ]; then
	die "No such SOURCE_DIR diretory at $SOURCE_DIR"
fi

if [ ! -f "$SOURCE_DIR/DOWNLOAD_URL" ]; then
	die "Source directory is missing required DOWNLOAD_URL file"
fi

SOURCE_HASH=$(find godot -type f -print0 | sort -z | xargs -0 md5sum | md5sum)
S3_ARCHIVE_KEY="$SOURCE_HASH-$BUILD_TYPE.tar.gz"

# Main:
if ! download_prebuilt_godot; then
	build_godot \
		|| die "Error building Godot"
	upload_godot \
		|| die "Error uploading archive to S3"
fi

#####
# FUNCTIONS:
#####

download_prebuilt_godot() {
	local archive=$(mktemp)
	if aws s3api get-object --bucket "$S3_BUCKET_NAME" --key "$S3_ARCHIVE_KEY" $archive; then
		mkdir -p "$BUILD_DIR/bin" \
			|| die "Unable to create BUILD_DIR: $BUILD_DIR"
		(cd $BUILD_DIR/bin && tar -xzvf $archive) \
			|| die "Unable to extract pre-built archive from S3"
		rm -f $archive
		return 0
	fi

	return 1
}

upload_godot() {
	local archive=$(mktemp)
	(cd "$BUILD_DIR/bin" && tar -czvf $archive) \
		|| die "Unable to create archive"
	aws s3api put-object --bucket "$S3_BUCKET_NAME" --key "$S3_ARCHIVE_KEY" -linux --body $archive
	local result=$?
	rm -f $archive
	return $result
}

build_godot() {
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

	if [ -z "$NUM_CORES" ]; then
		NUM_CORES=$(nproc --all)
	fi

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
		# In the registry, godot-linux becomes godot/linux.
		IMAGE=$(echo "$IMAGE" | sed -e 's,-,/,')
		IMAGE="$GODOT_BUILD_REGISTRY/$IMAGE"
	fi
	if [ -n "$GODOT_BUILD_TAG" ]; then
		IMAGE="$IMAGE:$GODOT_BUILD_TAG"
	fi

	PODMAN_OPTS=${PODMAN_OPTS:-}

	return podman run --rm --systemd=false -v "$(realpath $BUILD_DIR):/build" -v "$(realpath $SOURCE_DIR):/src" -v "$(pwd)/scripts/godot:/scripts" -w /build -e NUM_CORES="$NUM_CORES" -e BITS="$BITS" -e MONO="$MONO" -e "SCONS_OPTS=$SCONS_OPTS" $PODMAN_OPTS "$IMAGE" /scripts/$CMD $BUILD_TYPE
}

