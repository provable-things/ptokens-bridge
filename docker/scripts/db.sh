#!/bin/bash

function drop_database() {
	case $TEE in
		strongbox )
			;;
		vanilla )
			[[ ! $(rm -r "$FOLDER_PROXY/database" 2> /dev/null) ]] \
			  && logi "Failed to drop the core database, maybe it doesn't exists..." \
			  || logi "Dropping core's database...done!"
			;;
		nitro )
			[[ ! $(rm -r "$FOLDER_PROXY/mydb.dat" 2> /dev/null) ]] \
			  && logi "Failed to drop the core database, maybe it doesn't exists..." \
			  || logi "Dropping core's database...done!"
			;;
	esac
}

function drop_mongo_database() {
	local mongo_cmd

	# shellcheck disable=SC2089
	mongo_cmd='db = db.getSiblingDB("'$MONGO_DATABASE_NAME'");db.dropDatabase().ok'

  [[ ! $(mongo --eval "$mongo_cmd" > /dev/null) ]] \
	  && logi "Failed to drop mongo db, maybe it doesn't exists..." \
	  || logi "Dropping mongo db...done!"
}

function get_latest_block_num_for_symbol() {
	local state
	local symbol
	state=$1
	symbol=$2
	__num=$3

	case "$symbol" in
		eth|erc20 )
			num=$(echo "$state" | jq .eth.eth_latest_block_number)
			;;
		btc|dash|ltc )
			num=$(echo "$state" | jq .btc.btc_latest_block_number)
			;;
	esac

	# shellcheck disable=SC2140
	eval "$__num"="'$num'"
}


function initialize_latest_block_nums() {
	local state
	local num
	state=$(cd "$FOLDER_PROXY" && $EXC_PROXY getEnclaveState)

	local native_block_num
	local host_block_num
	get_latest_block_num_for_symbol "$state" "$NATIVE_SYMBOL" native_block_num
	get_latest_block_num_for_symbol "$state" "$HOST_SYMBOL" host_block_num

	# FIXME: native/host ids should be generated dynamically
	id_native=pbtc_enclave-last-processed-btc-block
	id_host=pbtc_enclave-last-processed-eth-block
	mongo_cmd1='db = db.getSiblingDB("'$MONGO_DATABASE_NAME'");db.'$MONGO_COLLECTION_NAME'.insertOne({_id:"'$id_native'", block_num: '$native_block_num' })'
	mongo_cmd2='db = db.getSiblingDB("'$MONGO_DATABASE_NAME'");db.'$MONGO_COLLECTION_NAME'.insertOne({_id:"'$id_host'", block_num: '$host_block_num' })'

	[[ ! $(mongo --eval "$mongo_cmd1" > /dev/null) ]] \
	  && logi "Failed to insert latest native block nums..." \
	  || logi "Native Block nums inserted!"	

	[[ ! $(mongo --eval "$mongo_cmd2" > /dev/null) ]] \
	  && logi "Failed to insert latest host block nums..." \
	  || logi "Host Block nums inserted!"	
}