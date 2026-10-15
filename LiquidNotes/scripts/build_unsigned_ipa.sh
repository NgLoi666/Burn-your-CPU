#!/usr/bin/env bash
#
# Build an UNSIGNED .ipa from the LiquidNotes Xcode project.
#
# Requirements: macOS with Xcode (iOS 26 SDK) and xcodebuild on PATH.
#
# Usage:
#   scripts/build_unsigned_ipa.sh [scheme] [configuration]
#   scripts/build_unsigned_ipa.sh LiquidNotes Release
#
# Output:
#   build/LiquidNotes-unsigned.ipa
#
set -euo pipefail

SCHEME="${1:-LiquidNotes}"
CONFIG="${2:-Release}"
# Optional override; useful when the toolchain lacks the iOS 26 SDK.
DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE="$BUILD_DIR/$SCHEME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP="$ARCHIVE/Products/Applications/$SCHEME.app"
IPA="$BUILD_DIR/$SCHEME-unsigned.ipa"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found. Run this on macOS with Xcode installed." >&2
  exit 1
fi

echo "==> Cleaning $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$EXPORT_DIR"

EXTRA_ARGS=()
if [ -n "$DEPLOYMENT_TARGET" ]; then
  echo "==> Overriding IPHONEOS_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET"
  EXTRA_ARGS+=("IPHONEOS_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET")
fi

echo "==> Archiving $SCHEME ($CONFIG) for generic iOS"
xcodebuild \
  -project "$PROJECT_DIR/$SCHEME.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} \
  clean archive

if [ ! -d "$APP" ]; then
  echo "error: expected app not found at $APP" >&2
  exit 1
fi

echo "==> Packaging Payload/ into an IPA"
mkdir -p "$EXPORT_DIR/Payload"
cp -R "$APP" "$EXPORT_DIR/Payload/"

# Best-effort: strip any signature that may have been embedded.
codesign --remove-signature "$EXPORT_DIR/Payload/$SCHEME.app" 2>/dev/null || true
rm -rf "$EXPORT_DIR/Payload/$SCHEME.app/_CodeSignature"

( cd "$EXPORT_DIR" && zip -qry "$IPA" Payload )
rm -rf "$EXPORT_DIR/Payload"

echo "==> Done: $IPA"
echo
echo "This IPA is NOT signed. To install it on a device you must re-sign it"
echo "with your own certificate (Xcode, AltStore, Sideloadly, etc.)."
