#!/bin/bash

set -uo pipefail

LABEL="local.mac-cleanup"
DOMAIN="gui/$(id -u)"
SERVICE="$DOMAIN/$LABEL"

PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "=========================================="
echo "Mac Cleanup - Status"
echo "=========================================="

echo
echo "User: $(id -un)"
echo "Service: $SERVICE"
echo "Plist: $PLIST"

echo
echo "=== INSTALLATION ==="

if [[ -f "$PLIST" ]]; then
    echo "LaunchAgent installé."
    plutil -p "$PLIST"
else
    echo "LaunchAgent non installé."
    exit 1
fi

echo
echo "=== LAUNCHD ==="

if launchctl print "$SERVICE" 2>/dev/null; then
    echo
    echo "LaunchAgent chargé."
else
    echo "LaunchAgent non chargé."
fi

echo
echo "=== SCRIPT INSTALLE ==="

INSTALL_DIR="$HOME/Library/Application Support/mac-cleanup"
CLEANUP_SCRIPT="$INSTALL_DIR/mac-cleanup.sh"

if [[ -x "$CLEANUP_SCRIPT" ]]; then
    echo "Script disponible : $CLEANUP_SCRIPT"
else
    echo "Script absent ou non exécutable : $CLEANUP_SCRIPT"
fi