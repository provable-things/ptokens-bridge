#!/bin/bash
SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"

# requires nitro-proxy >= v0.5.0
function ping_nitro() {
	while true; do
		logd "Pinging nitro enclave.."
		if "$FOLDER_PROXY"/nitro ping 2> /dev/null; then
			break
		fi
		sleep 5
	done
}