#!/bin/bash

die() {
	echo "$@" >/dev/stderr
	exit 1
}

if [ -z "$MACOSX_SIGNATURE_IDENTITY" -o -z "$MACOSX_BUNDLE_ID" -o -z "$MACOSX_APPLE_ID" -o -z "$MACOSX_APPLE_PASSWORD" ]; then
	die "Missing required variable"
fi

XCRUN_NOTARIZE_PROVIDER_ID=""
if [ -n "$MACOSX_APPLE_PROVIDER_ID" ]; then
	XCRUN_NOTARIZE_PROVIDER_ID="--asc-provider $MACOSX_APPLE_PROVIDER_ID"
fi

NAME=$(basename "$1")
WORKDIR=$(dirname "$1")

if [ -n "$2" ]; then
	ENTITLEMENTS="--entitlements $2"
else
	ENTITLEMENTS=""
fi

cd "$WORKDIR"
rm -f /tmp/notarize-*.plist

echo "Signing..."
codesign -vvv --force --deep --strict --sign "$MACOSX_SIGNATURE_IDENTITY" --options runtime $ENTITLEMENTS --timestamp "$NAME" \
	|| die "Failed to sign app"

echo "Uploading for notarization..."
zip -r "$NAME.zip" "$NAME"
xcrun notarytool submit "$NAME.zip" --apple-id "$MACOSX_APPLE_ID" --password "$MACOSX_APPLE_PASSWORD" --team-id "$MACOSX_APPLE_PROVIDER_ID" --output-format plist > /tmp/notarize-app.plist


rm -f "$NAME.zip"
NUUID=`/usr/libexec/PlistBuddy -c 'Print id' /tmp/notarize-app.plist`
if [ -z "${NUUID}" ]; then
    cat /tmp/notarize-app.plist
    die "* error: no RequestUUID found in upload response"
fi
echo "RequestUUID: ${NUUID}"

echo "Waiting for notarization to complete..."
while true; do
    xcrun notarytool info ${NUUID} --apple-id "$MACOSX_APPLE_ID" --password "$MACOSX_APPLE_PASSWORD" --team-id "$MACOSX_APPLE_PROVIDER_ID" --output-format plist > /tmp/notarize-info.plist

    NSTAT=`/usr/libexec/PlistBuddy -c 'Print status' /tmp/notarize-info.plist`
    echo "  `date "+%H:%M:%S"` ${NSTAT}"
    if [ -z "${NUUID}" ]; then
        cat /tmp/notarize-info.plist
        die "* error: no Status found in info response"
    fi

    if [ "${NSTAT}" == "Invalid" ]; then
        cat /tmp/notarize-info.plist
        die "* error: error notarizing app"
    fi

    if [ "${NSTAT}" == "Accepted" ]; then
        break
    fi
    sleep 30s
done

echo "Stapling ticket to app..."
xcrun stapler staple "$NAME"

rm /tmp/notarize-*.plist

