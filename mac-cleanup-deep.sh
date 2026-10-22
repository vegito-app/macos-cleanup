#!/bin/bash

set -uo pipefail

echo "=== Nettoyage approfondi ==="

echo
echo "=== Go build cache ==="

if command -v go >/dev/null 2>&1; then
    go clean -cache
fi

echo
echo "=== Homebrew ==="

if command -v brew >/dev/null 2>&1; then
    brew cleanup -s
fi

echo

echo "=== VS Code cache ==="

CODE_DIR="$HOME/Library/Application Support/Code"

if ! pgrep -x "Code" >/dev/null; then
    rm -rf "$CODE_DIR/Cache"
    rm -rf "$CODE_DIR/CachedData"
else
    echo "VS Code actif : nettoyage ignoré"
fi

echo
echo "=== Espace disque ==="

df -h /