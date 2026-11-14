#!/usr/bin/env bash
set -e

# Change to repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== 1. Building Flutter Web release with base-href /secretsantaapp/home/ ==="
flutter build web --release --base-href /secretsantaapp/home/

echo "=== 2. Creating clean deploy/ directory ==="
rm -rf deploy
mkdir -p deploy/home

echo "=== 3. Copying static site files into deploy/ ==="
cp -R site/. deploy/

echo "=== 4. Copying Flutter Web build into deploy/home/ ==="
cp -R build/web/. deploy/home/

echo "=== 5. Contents of deploy/ ==="
if command -v tree >/dev/null 2>&1; then
  tree -L 2 deploy/
else
  find deploy -maxdepth 2 -print | sort
fi

echo "=== Build and packaging complete ==="

