#!/bin/bash

GODOT_SOURCE_DIR=${GODOT_SOURCE_DIR:-godot}
GODOT_BUILD_DIR=${GODOT_BUILD_DIR:-build/godot}

CACHE_BUILD=${CACHE_BUILD:-yes}
DOWNLOAD_ONLY=${DOWNLOAD_ONLY:-no}
OVERWRITE_EXISTING=${OVERWRITE_EXISTING:-no}

if [ -n "$ARCHIVE_SUFFIX" ]; then
	ARCHIVE_SUFFIX="-$ARCHIVE_SUFFIX"
fi

die() {
	echo "$@" > /dev/stderr
	exit 1
}

if [ "$CACHE_BUILD" != yes -a "$DOWNLOAD_ONLY" = yes ]; then
	die "Cannot set DOWNLOAD_ONLY to yes unless CACHE_BUILD is also yes"
fi

if [ -z "$BUILD_TYPE" ]; then
	die "The BUILD_TYPE environment variable must be set"
fi

if [ "$CACHE_BUILD" = "yes" ]; then
	if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" -o -z "$S3_BUCKET_NAME" ]; then
		die "The AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and S3_BUCKET_NAME environment variables must be set"
	fi
fi

if [ ! -d "$GODOT_SOURCE_DIR" ]; then
	die "No such GODOT_SOURCE_DIR diretory at $GODOT_SOURCE_DIR"
fi

if [ ! -f "$GODOT_SOURCE_DIR/DOWNLOAD_URL" ]; then
	die "Source directory is missing required DOWNLOAD_URL file"
fi

SOURCE_HASH=$(find $GODOT_SOURCE_DIR -type f -print0 | sort -z | xargs -0 md5sum | md5sum | tr -d '[:space:]')
S3_ARCHIVE_KEY="$SOURCE_HASH-$BUILD_TYPE$ARCHIVE_SUFFIX.tar.gz"

#####
# FUNCTIONS:
#####

download_prebuilt_godot() {
	local archive=$(mktemp)
	if aws s3api get-object --bucket "$S3_BUCKET_NAME" --key "$S3_ARCHIVE_KEY" $archive; then
		mkdir -p "$GODOT_BUILD_DIR/bin" \
			|| die "Unable to create GODOT_BUILD_DIR: $GODOT_BUILD_DIR"
		(cd $GODOT_BUILD_DIR/bin && tar -xzvf $archive) \
			|| die "Unable to extract pre-built archive from S3"
		rm -f $archive
		return 0
	fi

	return 1
}

upload_godot() {
	local archive=$(mktemp)
	(cd "$GODOT_BUILD_DIR/bin" && tar -czvf $archive *) \
		|| die "Unable to create archive"
	aws s3api put-object --bucket "$S3_BUCKET_NAME" --key "$S3_ARCHIVE_KEY" --body $archive
	local result=$?
	rm -f $archive
	return $result
}

build_godot() {
	DOWNLOAD_URL=$(cat "$GODOT_SOURCE_DIR/DOWNLOAD_URL")

	if [ ! -d "$GODOT_BUILD_DIR" -o "$OVERWRITE_EXISTNG" = "yes" ]; then
		if [ ! -d "$GODOT_BUILD_DIR" ]; then
			mkdir "$GODOT_BUILD_DIR" \
				|| die "Unable to create GODOT_BUILD_DIR: $GODOT_BUILD_DIR"
		fi

		(cd "$GODOT_BUILD_DIR" && curl -L "$DOWNLOAD_URL" | tar -xz --strip-components=1) \
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
		server-tools|server)
			IMAGE="godot-linux"
			CMD="build-server.sh"
			;;
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

	TOOLS=""
	case "$BUILD_TYPE" in
		*-tools*)
			TOOLS="yes"
			;;
	esac

	SCONS_OPTS=${SCONS_OPTS:-}
	if [ -d "$GODOT_SOURCE_DIR/modules" ]; then
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

	podman run --rm --systemd=false -v "$(realpath $GODOT_BUILD_DIR):/build" -v "$(realpath $GODOT_SOURCE_DIR):/src" -v "$(pwd)/scripts/godot:/scripts" -w /build -e NUM_CORES="$NUM_CORES" -e BITS="$BITS" -e MONO="$MONO" -e TOOLS="$TOOLS" -e "SCONS_OPTS=$SCONS_OPTS" $PODMAN_OPTS "$IMAGE" /scripts/$CMD $BUILD_TYPE
	return $?
}

#####
# MAIN:
#####

if [ "$DOWNLOAD_ONLY" = "yes" ]; then
	download_prebuilt_godot \
		|| die "Unable to download archive"
elif [ "$CACHE_BUILD" = "yes" ]; then
	if ! download_prebuilt_godot; then
		build_godot \
			|| die "Error building Godot"
		upload_godot \
			|| die "Error uploading archive to S3"
	fi
else
	build_godot \
		|| die "Error building Godot"
fi

