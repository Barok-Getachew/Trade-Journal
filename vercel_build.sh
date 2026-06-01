#!/bin/bash
set -e

echo "==> Installing Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "==> Flutter version:"
flutter --version

echo "==> Getting dependencies..."
flutter pub get

echo "==> Building Flutter web..."
flutter build web --release --web-renderer canvaskit

echo "==> Build complete. Output in build/web/"
