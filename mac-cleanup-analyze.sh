#!/bin/bash

set -uo pipefail
export LC_ALL=C

# Ce script analyse les données de l'utilisateur courant.
# Ne pas l'exécuter avec sudo.
if [[ "$(id -u)" -eq 0 ]]; then
    echo "ERROR: exécuter mac-cleanup-analyze.sh sans sudo." >&2
    exit 1
fi

HOME_DIR="$HOME"
REPORT_DIR="$HOME_DIR/Library/Logs/mac-cleanup/analysis"

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT="$REPORT_DIR/analysis-$TIMESTAMP.log"
LATEST="$REPORT_DIR/latest.log"

mkdir -p "$REPORT_DIR"

# Évite deux analyses simultanées.
LOCK_DIR="$REPORT_DIR/.analyze.lock"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "Une analyse est déjà en cours."
    exit 1
fi

trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

# Enregistre également la sortie dans le terminal.
exec > >(tee "$REPORT") 2>&1

section() {
    printf '\n'
    printf '============================================================\n'
    printf '%s\n' "$1"
    printf '============================================================\n'
}

# Taille des sous-répertoires immédiats.
# -x : ne traverse pas les autres systèmes de fichiers.
# -d 1 : profondeur limitée à un niveau.
analyze_tree() {
    local path="$1"
    local title="$2"

    section "$title"

    if [[ ! -d "$path" ]]; then
        echo "Absent : $path"
        return
    fi

    echo "Path: $path"
    echo

    du -xhd 1 "$path" 2>/dev/null | sort -h
}

# Affiche les N éléments les plus volumineux.
analyze_top() {
    local path="$1"
    local title="$2"
    local limit="${3:-30}"

    section "$title"

    if [[ ! -d "$path" ]]; then
        echo "Absent : $path"
        return
    fi

    echo "Path: $path"
    echo

    du -xhd 1 "$path" 2>/dev/null |
        sort -h |
        tail -n "$limit"
}

section "MAC CLEANUP ANALYSIS"

echo "Date: $(date)"
echo "Host: $(hostname)"
echo "User: $(id -un)"
echo "macOS: $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"

# ============================================================
# 1. ESPACE DISQUE
# ============================================================

section "DISK USAGE"

df -h /

echo
echo "Volume Data:"
df -h /System/Volumes/Data

echo
echo "APFS volumes:"
diskutil apfs list

# ============================================================
# 2. SNAPSHOTS APFS
# ============================================================

section "APFS SNAPSHOTS"

echo "System snapshots:"
diskutil apfs listSnapshots / 2>&1 || true

echo
echo "Data snapshots:"
diskutil apfs listSnapshots /System/Volumes/Data 2>&1 || true

echo
echo "Time Machine local snapshots:"
tmutil listlocalsnapshots / 2>&1 || true

# ============================================================
# 3. RÉPARTITION GLOBALE
# ============================================================

analyze_tree \
    "/System/Volumes/Data" \
    "DATA VOLUME ROOT"

analyze_tree \
    "$HOME_DIR" \
    "HOME DIRECTORY"

# ============================================================
# 4. RÉPERTOIRES CACHÉS UTILISATEUR
# ============================================================

section "HOME HIDDEN DIRECTORIES"

# Inclut les fichiers et dossiers cachés.
# Ne suit pas les liens symboliques.
find "$HOME_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -name '.*' \
    -print0 |
while IFS= read -r -d '' path; do
    du -xsh "$path" 2>/dev/null
done | sort -h | tail -n 50

# ============================================================
# 5. LIBRARY
# ============================================================

analyze_tree \
    "$HOME_DIR/Library" \
    "USER LIBRARY"

analyze_top \
    "$HOME_DIR/Library/Caches" \
    "USER CACHES" \
    50

analyze_top \
    "$HOME_DIR/Library/Application Support" \
    "APPLICATION SUPPORT" \
    50

analyze_top \
    "$HOME_DIR/Library/Containers" \
    "APPLICATION CONTAINERS" \
    40

analyze_top \
    "$HOME_DIR/Library/Group Containers" \
    "GROUP CONTAINERS" \
    40

# ============================================================
# 6. VS CODE
# ============================================================

CODE_DIR="$HOME_DIR/Library/Application Support/Code"

analyze_tree \
    "$CODE_DIR" \
    "VS CODE DATA"

analyze_top \
    "$CODE_DIR/WebStorage" \
    "VS CODE WEBSTORAGE" \
    30

analyze_top \
    "$CODE_DIR/User" \
    "VS CODE USER DATA" \
    30

analyze_top \
    "$HOME_DIR/.vscode" \
    "VS CODE EXTENSIONS" \
    30

# ============================================================
# 7. CACHES DE DÉVELOPPEMENT
# ============================================================

analyze_tree \
    "$HOME_DIR/.cache" \
    "DEVELOPMENT CACHES"

analyze_top \
    "$HOME_DIR/.cache/codex-runtimes" \
    "CODEX RUNTIMES" \
    30

analyze_top \
    "$HOME_DIR/.cache/uv" \
    "UV CACHE" \
    30

analyze_top \
    "$HOME_DIR/.local" \
    "LOCAL DATA" \
    30

analyze_top \
    "$HOME_DIR/.codex" \
    "CODEX DATA" \
    30

analyze_top \
    "$HOME_DIR/.continue" \
    "CONTINUE DATA" \
    30

# ============================================================
# 8. GO
# ============================================================

section "GO ENVIRONMENT"

if command -v go >/dev/null 2>&1; then
    echo "Go version:"
    go version

    echo
    echo "Go paths:"

    go env GOPATH GOCACHE GOMODCACHE

    echo
    echo "Go cache sizes:"

    for path in \
        "$(go env GOPATH)" \
        "$(go env GOCACHE)" \
        "$(go env GOMODCACHE)"
    do
        du -xsh "$path" 2>/dev/null || true
    done
else
    echo "Go unavailable"
fi

analyze_top \
    "$HOME_DIR/go" \
    "GO DIRECTORY" \
    30

# ============================================================
# 9. DOCKER
# ============================================================

analyze_tree \
    "$HOME_DIR/.docker" \
    "DOCKER USER DATA"

analyze_tree \
    "$HOME_DIR/Library/Containers/com.docker.docker" \
    "DOCKER DESKTOP DATA"

section "DOCKER SYSTEM DF"

if command -v docker >/dev/null 2>&1; then
    # Timeout macOS : évite un blocage prolongé si le daemon
    # Docker est arrêté ou inaccessible.
    docker system df 2>&1 || true
else
    echo "Docker unavailable"
fi

# ============================================================
# 10. HOMEBREW
# ============================================================

section "HOMEBREW"

if command -v brew >/dev/null 2>&1; then
    echo "Prefix:"
    brew --prefix

    echo
    echo "Cache:"
    BREW_CACHE="$(brew --cache 2>/dev/null)"

    if [[ -n "$BREW_CACHE" ]]; then
        du -xsh "$BREW_CACHE" 2>/dev/null || true
    fi
else
    echo "Homebrew unavailable"
fi

analyze_tree \
    "/opt/homebrew" \
    "HOMEBREW INSTALLATION"

# ============================================================
# 11. APPLICATIONS
# ============================================================

analyze_top \
    "/Applications" \
    "APPLICATIONS" \
    50

# ============================================================
# 12. PRIVATE
# ============================================================

analyze_tree \
    "/private" \
    "PRIVATE"

analyze_top \
    "/private/var" \
    "PRIVATE VAR" \
    40

analyze_top \
    "/private/var/folders" \
    "PRIVATE VAR FOLDERS" \
    30

# ============================================================
# 13. SYSTEM LIBRARY
# ============================================================

analyze_top \
    "/Library" \
    "SYSTEM LIBRARY" \
    40

# ============================================================
# 14. FINAL
# ============================================================

section "FINAL DISK SPACE"

df -h /

section "REPORT"

echo "Report: $REPORT"
echo "Analysis completed."

ln -sfn "$REPORT" "$LATEST"