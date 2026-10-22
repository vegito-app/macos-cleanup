#!/bin/bash

set -uo pipefail

HOME_DIR="$HOME"
LOG_DIR="$HOME_DIR/Library/Logs/mac-cleanup"

mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/cleanup.log"

exec >> "$LOG_FILE" 2>&1

echo
echo "=========================================="
echo "Mac cleanup: $(date)"
echo "=========================================="

echo
echo "=== Espace avant nettoyage ==="
df -h /

clean_directory() {
    local path="$1"
    local label="$2"

    if [[ ! -e "$path" ]]; then
        return
    fi

    echo
    echo "Cleaning: $label"

    du -sh "$path" 2>/dev/null || true

    rm -rf -- "$path"

    if [[ $? -eq 0 ]]; then
        echo "OK"
    else
        echo "WARNING: nettoyage incomplet"
    fi
}

# ==========================================
# Journaux VS Code
# ==========================================

# Conserver les journaux récents et supprimer
# uniquement les fichiers de plus de 14 jours.

CODE_LOGS="$HOME_DIR/Library/Application Support/Code/logs"

if [[ -d "$CODE_LOGS" ]]; then
    find "$CODE_LOGS" \
        -type f \
        -mtime +14 \
        -delete
fi

# ==========================================
# Logs utilisateur anciens
# ==========================================

find "$HOME_DIR/Library/Logs" \
    -type f \
    -name "*.log" \
    -mtime +30 \
    ! -path "$LOG_DIR/*" \
    -delete 2>/dev/null || true

echo
echo "=== Espace après nettoyage ==="
df -h /

echo
echo "Cleanup terminé: $(date)"

