#!/bin/bash

set -euo pipefail

# Identifiants des installations actuelles et historiques.
LABELS=(
    "local.mac-cleanup"
)

DOMAIN="gui/$(id -u)"

LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
INSTALL_DIR="$HOME/Library/Application Support/mac-cleanup"
LOG_DIR="$HOME/Library/Logs/mac-cleanup"

echo "=========================================="
echo "Mac Cleanup - Uninstall"
echo "=========================================="

# Un LaunchAgent utilisateur ne doit pas être désinstallé via sudo.
if [[ "$(id -u)" -eq 0 ]]; then
    echo "ERROR: exécuter sans sudo." >&2
    exit 1
fi

echo
echo "Utilisateur : $(id -un)"
echo "Domaine : $DOMAIN"

for LABEL in "${LABELS[@]}"; do

    SERVICE="$DOMAIN/$LABEL"
    PLIST="$LAUNCHAGENTS_DIR/$LABEL.plist"

    echo
    echo "=== $LABEL ==="

    # Arrêter le service s'il est chargé.
    if launchctl print "$SERVICE" >/dev/null 2>&1; then
        echo "Arrêt du LaunchAgent..."
        launchctl bootout "$SERVICE"
    else
        echo "LaunchAgent non chargé."
    fi

    # Supprimer le plist.
    if [[ -f "$PLIST" ]]; then
        echo "Suppression : $PLIST"
        rm -f "$PLIST"
    fi

done

# Supprimer uniquement les scripts installés localement.
if [[ -d "$INSTALL_DIR" ]]; then
    echo
    echo "Suppression : $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
fi

echo
echo "=========================================="
echo "Désinstallation terminée"
echo "=========================================="

echo
echo "Conservés :"
echo "  - Scripts sources"
echo "  - Journaux : $LOG_DIR"
echo "  - Rapports d'analyse"

echo
echo "Pour réinstaller :"
echo "  ./mac-cleanup-install.sh"