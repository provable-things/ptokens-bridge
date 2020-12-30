#!/bin/bash
SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/utils.sh
[ -f "$SCRIPT_UTILS" ] && . "$SCRIPT_UTILS"
# shellcheck source=./scripts/btc.sh
[ -f "$SCRIPT_BTC" ] && . "$SCRIPT_BTC"
# shellcheck source=./scripts/eth.sh
[ -f "$SCRIPT_ETH" ] && . "$SCRIPT_ETH"
# shellcheck source=./scripts/eos.sh
[ -f "$SCRIPT_EOS" ] && . "$SCRIPT_EOS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"
# shellcheck source=./scripts/db.sh
[ -f "$SCRIPT_DB" ] && . "$SCRIPT_DB"

function forget() {
	drop_sync_files
	maybe_uninstall_app
	drop_database
	drop_mongo_database
	drop_logs
}

function deploy() {
	local native_block_init
	local host_block_init
	local smart_contract_bytecode
	
	logi "Recognized p${NATIVE_SYMBOL}-on-${HOST_SYMBOL} deployment"

	native_block_init=$FOLDER_SYNC/$NATIVE_SYMBOL-init.json
	host_block_init=$FOLDER_SYNC/$HOST_SYMBOL-init.json
	smart_contract_bytecode=$FOLDER_SYNC/smart-contract-bytecode

	maybe_install_app
	
	logi "Waiting for init files..."

	wait_file "$native_block_init"
	wait_file "$host_block_init"
	wait_file "$smart_contract_bytecode"

	logi "Init files found!"
	eval "initialize_$HOST_SYMBOL"

	logi "${HOST_SYMBOL^^} initialization succeeded!"
	eval "initialize_$NATIVE_SYMBOL"

	logi "${NATIVE_SYMBOL^^} initialization succeeded!"
}

function sync() {

	logi "Loading components configuration..."

	# outputs something like:
	#   btc
	#   eth
	echo "$NATIVE_SYMBOL $HOST_SYMBOL" \
		| grep -E -o "$REGEX_SUPPORTED_SYMBOLS" \
		| while read -r symbol; do
			case $symbol in
				eth|erc20 )
					prepare_eth_sync_material
					;;
				eos|telos )
					prepare_eos_sync_material
					;;
				btc|ltc|dash )
					prepare_btc_sync_material
					;;
			esac
		done

	add_bridge_info

	initialize_latest_block_nums
	
	touch "$FOLDER_SYNC/api-server.start"
}

function rm_safety_file() {
	rm -f "$FILE_SAFETY"
	logi "Removing safety file...done!"
}

function main() {
	local build_type

	if [[ "$NEW" == "deploy" || "$APK_INSTALL" == "NEW" ]]; then
			check_safetyfile_exists
			build_type=new
	else
		build_type=""
	fi

	case $build_type in
		new )
			forget
			deploy
			sync
			rm_safety_file
			;;
		*) 
			logi "Skipping initialization..."
			;;		
	esac
	logi "Ready to go!"

	exit 0
}

main "$@"