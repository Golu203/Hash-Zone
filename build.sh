#!/bin/bash

# Exit on error
set -e

echo "=== System Info ==="
uname -a

echo "=== Installing Flutter SDK ==="
# We place the flutter directory in the build cache or temporary area
# To speed up subsequent builds, we check if it already exists
FLUTTER_DIR="$(pwd)/.flutter-sdk"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter stable branch..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
else
  echo "Using cached Flutter SDK."
fi

# Add Flutter to PATH
export PATH="$PATH:$FLUTTER_DIR/bin"

echo "=== Verifying Flutter Installation ==="
flutter --version

echo "=== Configuring Flutter Web ==="
flutter config --enable-web

echo "=== Running flutter pub get ==="
flutter pub get

echo "=== Building Flutter Web (Release) ==="
flutter build web --release --no-wasm-dry-run

echo "=== Preparing Vercel Output ==="
# Clean old public directory
rm -rf public
mkdir -p public

# Copy build files to public folder
cp -R build/web/* public/

echo "=== Build Complete ==="
