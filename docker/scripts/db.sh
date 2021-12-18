#!/bin/bash
# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"

function drop_database() {
	case $TEE in
		strongbox )
			;;
		vanilla )
			if [[ $(rm -r "$FOLDER_PROXY/database" 2> /dev/null) -ne 0 ]]; then
			  logi "Failed to drop the core database, maybe it doesn't exists..."
			else
			  logi "Dropping core's database...done!"
			fi
			;;
		nitro )
			# TODO: put in a loop
			if [[ $(rm -r "$FOLDER_PROXY/mydb.dat" 2> /dev/null) -ne 0 ]]; then
			  logi "Failed to drop the core database, maybe it doesn't exists..."
			else
			  logi "Dropping core's database...done!"
			fi
			if [[ $(rm -r "$FOLDER_PROXY/kms_alias_prefix.txt" 2> /dev/null) -ne 0 ]]; then
				logi "Failed to drop kms_alias_prefix.txt, maybe it doesn't exists..."
			else
			  logi "Dropping kms_alias_prefix.txt...done!"
			fi
			;;
	esac
}

function drop_mongo_database() {
	local mongo_cmd

	# shellcheck disable=SC2089
	mongo_cmd='db = db.getSiblingDB("'$MONGO_DATABASE_NAME'");db.dropDatabase().ok'

  if [[ $(mongo --eval "$mongo_cmd" > /dev/null) -ne 0 ]]; then
	  logi "Failed to drop mongo db, maybe it doesn't exists..."
	else
	  logi "Dropping mongo db...done!"
	fi
}

function mongo_get_latest_block_num_for_symbol() {
	local state
	local symbol
	
	symbol=$1
	state=$2
	__num=$3
	num=null
	case "$symbol" in
		btc )
			num=$(echo "$state" | jq .btc.btc_latest_block_number)
			;;
		eos )
			num=$(echo "$state" | jq .eos.eos_last_seen_block_num)
			;;
		erc20|eth )
			num=$(echo "$state" | jq .eth.eth_latest_block_number)
			;;
		evm )
			num=$(echo "$state" | jq .evm.evm_latest_block_number)
			;;
		 * )
			loge "Couldn't find latest block number for symbol $symbol"
			;;
	esac

	# shellcheck disable=SC2140
	eval "$__num"="'$num'"
}

function mongo_get_blocknum_id_for_symbol() {
	reduced_symbol=$1
	__id=$2
	id=null
	case $reduced_symbol in
		btc|eos|evm )
			id=pbtc_enclave-last-processed-$reduced_symbol-block
			;;
		erc20|eth )
			id=pbtc_enclave-last-processed-eth-block
			;;
		* )
			loge "Couldn't find any valid mongo ID matching symbol $reduced_symbol!"
			exit 1
	esac

	# shellcheck disable=SC2140
	eval "$__id"="'$id'"
}

function mongo_insert() {
	local cmd
	local err_msg
	local new_report
	local success_msg

	new_report=$1
	success_msg=$2
	err_msg=$3
	cmd='db = db.getSiblingDB("'$MONGO_DATABASE_NAME'");db.'$MONGO_COLLECTION_NAME'.insertOne('$new_report')'
	if mongo --eval "$cmd" > /dev/null; then
	  logi "$success_msg"	
	else
	  logi "$err_msg"
	fi
}

function initialize_latest_block_nums() {
	local reduced_host_symbol
	local reduced_native_symbol

	reduced_native_symbol=$1
	reduced_host_symbol=$2

	local state
	local id_host
	local id_native
	local host_block_num
	local native_block_num
		
	mongo_get_blocknum_id_for_symbol "$reduced_host_symbol" id_host
	mongo_get_blocknum_id_for_symbol "$reduced_native_symbol" id_native

	state=$(cd "$FOLDER_PROXY" && $EXC_PROXY getEnclaveState)

	mongo_get_latest_block_num_for_symbol "$reduced_host_symbol" "$state" host_block_num
	mongo_get_latest_block_num_for_symbol "$reduced_native_symbol" "$state" native_block_num
	
	if [[ "$id_native" != "null" ]]; then
		# $native_block_num would have already double quotes in it
		mongo_insert "{_id:\"$id_native\", block_num: $native_block_num }" \
			"Native latest block number set!" \
			"Failed to set the latest native block number in mongo!"
	fi

	if [[ "$id_native" != "null" ]]; then
		# $host_block_num would have already double quotes in it
		mongo_insert "{_id:\"$id_host\", block_num: $host_block_num }" \
			"Host latest block number set!" \
			"Failed to set the latest host block number in mongo!"
	fi
}
