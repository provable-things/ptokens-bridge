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

function maybe_remove_old_data() {
	drop_sync_files
	maybe_uninstall_app
	drop_database
	drop_mongo_database
	drop_logs
}

function initialize_core() {
	local reduced_host_symbol
	local reduced_native_symbol

	reduced_native_symbol=$1
	reduced_host_symbol=$2

	if eval "initialize_$reduced_native_symbol native $NATIVE_SYMBOL"; then
		logi "${NATIVE_SYMBOL^^} initialization succeeded!"
		sleep 2
	else
		loge "${NATIVE_SYMBOL^^} initialization failed...aborting!"
		exit 1
	fi

	if eval "initialize_$reduced_host_symbol host $HOST_SYMBOL"; then
		logi "${HOST_SYMBOL^^} initialization succeeded!"
		sleep 2
	else
		loge "${HOST_SYMBOL^^} initialization failed...aborting!"
		exit 1
	fi
}

function deploy_new_bridge() {
	local bridge_type
	local host_block_init
	local native_block_init
	local reduced_bridge_type

	bridge_type="$1"
	reduced_bridge_type=$2
	
	logi "Recognized $bridge_type($reduced_bridge_type) deployment"

	reduced_host_symbol=null
	reduced_native_symbol=null

	get_native_symbol_from_bridge_type \
		"$reduced_bridge_type" \
		reduced_native_symbol
	get_host_symbol_from_bridge_type \
		"$reduced_bridge_type" \
		reduced_host_symbol

	logd "Reduced native symbol: $reduced_native_symbol"
	logd "Reduced host symbol: $reduced_host_symbol"

	native_block_init=$FOLDER_SYNC/$NATIVE_SYMBOL-init.json
	host_block_init=$FOLDER_SYNC/$HOST_SYMBOL-init.json

	maybe_install_app
	
	logi "Waiting for init files..."

	wait_file "$native_block_init"
	wait_file "$host_block_init"

	check_enclave_is_ready

	logi "Init files found!"
	
	initialize_core \
		"$reduced_native_symbol" \
		"$reduced_host_symbol"

	logi "Loading components configuration..."

	prepare_sync_material \
		"host" \
		"$HOST_SYMBOL" \
		"$reduced_host_symbol"

	prepare_sync_material \
		"native" \
		"$NATIVE_SYMBOL" \
		"$reduced_native_symbol"

	initialize_latest_block_nums \
		"$reduced_native_symbol" \
		"$reduced_host_symbol"
	
	touch "$FOLDER_SYNC/api-server.start"
}

function prepare_sync_material() {
	local type
	local symbol
	local reduced_symbol

	type=$1
	symbol=$2
	reduced_symbol=$3

	case $reduced_symbol in
		evm|eth|erc20 )
			prepare_eth_sync_material "$type" "$symbol"
			;;
		eos )
			prepare_eos_sync_material "$type" "$symbol"
			;;
		# Note bash cannot expand variables here, so keep it
		btc )
			prepare_btc_sync_material "$type" "$symbol"
			;;
		* )
			loge "Failed to get sync material for $symbol"
			exit 1
			;;
	esac
}

function rm_safety_file() {
	rm -f "$FILE_SAFETY"
	logi "Removing safety file...done!"
}

function main() {
	local build_type
	local bridge_type
	local reduced_bridge_type
	
	bridge_type="p$NATIVE_SYMBOL-on-$HOST_SYMBOL"

	get_reduced_bridge_type "$bridge_type" reduced_bridge_type

	echo -n "$reduced_bridge_type" > "$FILE_REDUCED_BRIDGE_TYPE"
	
	logd "cat $FILE_REDUCED_BRIDGE_TYPE: $(cat "$FILE_REDUCED_BRIDGE_TYPE")"

	if [[ "$NEW" == "deploy" || "$APK_INSTALL" == "NEW" ]]; then
			check_safetyfile_exists
			build_type=new
	else
		build_type=""
	fi

	case $build_type in
		new )
			maybe_remove_old_data
			maybe_install_proxy_deps
			deploy_new_bridge "$bridge_type" "$reduced_bridge_type"
			rm_safety_file
			;;
		*) 
			logi "Skipping initialization..."
			
			maybe_install_proxy_deps
			;;		
	esac
	logi "Ready to go!"

	exit 0
}

main "$@"
