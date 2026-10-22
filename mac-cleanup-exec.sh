#!/bin/bash

set -uo pipefail

launchctl kickstart \
    gui/$(id -u)/local.mac-cleanup