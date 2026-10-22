#!/bin/bash
set -euo pipefail

LABEL="local.mac-cleanup"
SERVICE="gui/$(id -u)/$LABEL"

launchctl disable "$SERVICE"

if launchctl print "$SERVICE" >/dev/null 2>&1; then
    launchctl bootout "$SERVICE"
fi