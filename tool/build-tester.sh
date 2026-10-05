#!/usr/bin/env bash
# Builds the tester APK: the release build, debug-signed, with the application id
# `com.SanskritStudies.mobile_app.test` and the launcher label
# "Saṃsādhanī Heritage (test)", so it installs beside the app from Google Play.
# The build number is the number of commits, so it rises with every commit and
# a tester's report says which APK it is about; the About page shows the
# commit as well. pubspec.yaml is not changed. Only the arm and arm64 native
# code is included (no phone uses x86_64): still one file for every tester.
# Copies it to build/tester/ and prints the path, size and commit.
#
# Run from anywhere:  tool/build-tester.sh
# It refuses to run with uncommitted changes under lib/ or android/, so every
# tester APK matches a commit.
set -euo pipefail

cd "$(dirname "$0")/.."

dirty="$(git status --porcelain -- lib android)"
if [ -n "$dirty" ]; then
  echo "build-tester: uncommitted changes under lib/ or android/; commit them first," >&2
  echo "so that the APK matches a commit:" >&2
  echo "$dirty" >&2
  exit 1
fi

full="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1 | tr -d '[:space:]')"
if [ -z "$full" ]; then
  echo "build-tester: no version line in pubspec.yaml" >&2
  exit 1
fi
version="${full%%+*}"
build="$(git rev-list --count HEAD)"

commit="$(git rev-parse --short HEAD)"
out="build/tester/samsaadhanii-heritage-test-${version}-${build}-$(date +%Y%m%d).apk"

TESTER_BUILD=1 flutter build apk --release \
  --build-number="$build" \
  --dart-define=BUILD_COMMIT="$commit" \
  --target-platform android-arm,android-arm64

mkdir -p build/tester
cp build/app/outputs/flutter-apk/app-release.apk "$out"

echo
echo "Tester APK: $out"
echo "Size:       $(du -h "$out" | cut -f1) ($(wc -c < "$out" | tr -d ' ') bytes)"
echo "Commit:     $commit"
