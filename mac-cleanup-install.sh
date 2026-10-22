#!/bin/bash

set -euo pipefail

LABEL="local.mac-cleanup"

# Répertoire d'installation local à l'utilisateur.
INSTALL_DIR="$HOME/Library/Application Support/mac-cleanup"

# Répertoire contenant les scripts distribués (NAS, SFTP, Git...).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_CLEANUP_SCRIPT="$SCRIPT_DIR/mac-cleanup.sh"

# Script réellement exécuté par launchd.
CLEANUP_SCRIPT="$INSTALL_DIR/mac-cleanup.sh"

LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST="$LAUNCHAGENTS_DIR/$LABEL.plist"

LOG_DIR="$HOME/Library/Logs/mac-cleanup"

DOMAIN="gui/$(id -u)"
SERVICE="$DOMAIN/$LABEL"

echo "=========================================="
echo "Mac Cleanup - Installation"
echo "=========================================="

# Ne pas installer un LaunchAgent utilisateur via sudo.
if [[ "$(id -u)" -eq 0 ]]; then
    echo "ERROR: exécuter sans sudo."
    exit 1
fi

if [[ ! -f "$SOURCE_CLEANUP_SCRIPT" ]]; then
    echo "ERROR: script introuvable : $SOURCE_CLEANUP_SCRIPT"
    exit 1
fi

# Préparer les répertoires locaux.
mkdir -p "$LAUNCHAGENTS_DIR" "$LOG_DIR" "$INSTALL_DIR"

# Installer tous les scripts de la suite.
for SOURCE in "$SCRIPT_DIR"/mac-cleanup*.sh; do
    [[ -f "$SOURCE" ]] || continue

    DEST="$INSTALL_DIR/$(basename "$SOURCE")"

    cp "$SOURCE" "$DEST"
    chmod 755 "$DEST"

    echo "Installed: $DEST"
done

echo
echo "Script : $CLEANUP_SCRIPT"
echo "LaunchAgent : $PLIST"

# Arrêter l'ancienne version si elle est chargée.
if launchctl print "$SERVICE" >/dev/null 2>&1; then
    echo
    echo "Arrêt de l'ancien LaunchAgent..."
    launchctl bootout "$SERVICE"
fi

# Générer le plist avec les chemins absolus.
# PlistBuddy évite les problèmes d'échappement XML.
PLIST_BUDDY="/usr/libexec/PlistBuddy"

rm -f "$PLIST"

"$PLIST_BUDDY" -c "Add :Label string $LABEL" "$PLIST"
"$PLIST_BUDDY" -c "Add :ProgramArguments array" "$PLIST"
"$PLIST_BUDDY" -c "Add :ProgramArguments:0 string /bin/bash" "$PLIST"
"$PLIST_BUDDY" -c "Add :ProgramArguments:1 string $CLEANUP_SCRIPT" "$PLIST"

# Exécuter au chargement de la session.
"$PLIST_BUDDY" -c "Add :RunAtLoad bool true" "$PLIST"

# Réexécuter environ toutes les 24 heures.
"$PLIST_BUDDY" -c "Add :StartInterval integer 86400" "$PLIST"

# Ne pas maintenir le processus actif en permanence.
"$PLIST_BUDDY" -c "Add :KeepAlive bool false" "$PLIST"

# Fichiers de sortie pour les erreurs de lancement.
"$PLIST_BUDDY" -c \
    "Add :StandardOutPath string $LOG_DIR/launchd.stdout.log" \
    "$PLIST"

"$PLIST_BUDDY" -c \
    "Add :StandardErrorPath string $LOG_DIR/launchd.stderr.log" \
    "$PLIST"

chmod 644 "$PLIST"

echo
echo "Validation du plist..."

plutil -lint "$PLIST"

echo
echo "Activation du LaunchAgent..."

launchctl bootstrap "$DOMAIN" "$PLIST"

# Autoriser son exécution.
launchctl enable "$SERVICE"

echo
echo "=========================================="
echo "Installation terminée"
echo "=========================================="

echo
echo "Service : $SERVICE"
echo "Fréquence : ouverture de session + 24 heures"
echo "Logs : $LOG_DIR"
echo
echo "Statut :"

launchctl print "$SERVICE" | head -40