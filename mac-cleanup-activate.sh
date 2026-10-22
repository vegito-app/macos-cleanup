#!/bin/bash

set -uo pipefail
#!/bin/bash
set -euo pipefail

LABEL="local.mac-cleanup"
DOMAIN="gui/$(id -u)"
SERVICE="$DOMAIN/$LABEL"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl enable "$SERVICE"

if ! launchctl print "$SERVICE" >/dev/null 2>&1; then
    launchctl bootstrap "$DOMAIN" "$PLIST"
fi

launchctl kickstart "$SERVICE"