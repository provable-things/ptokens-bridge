#!/bin/bash 

export SCRIPT_DB=$HOME/scripts/db.sh
export SCRIPT_LOG=$HOME/scripts/log.sh
export SCRIPT_EOS=$HOME/scripts/eos.sh
export SCRIPT_ETH=$HOME/scripts/eth.sh
export SCRIPT_BTC=$HOME/scripts/btc.sh
export SCRIPT_ADB=$HOME/scripts/adb.sh
export SCRIPT_UTILS=$HOME/scripts/utils.sh
export SCRIPT_NITRO=$HOME/scripts/nitro.sh
export SCRIPT_GET_FEES=$HOME/scripts/get_fees.sh

export FILE_SMART_CONTRACT_BYTECODE=$HOME/sync
export FILE_SAFETY=$FOLDER_PROXY/.new
export FILE_REDUCED_BRIDGE_TYPE=$FOLDER_SYNC/reduced-bridge-type

export EXC_PROXY=./$TEE

export REDUCED_BRIDGE_TYPE_MAPPING='{
	"pbtc-on-eth": "pbtc-on-eth",
	"pltc-on-eth": "pbtc-on-eth",
	"plbc-on-bsc": "pbtc-on-eth",
	"pdoge-on-eth": "pbtc-on-eth",
	"prvn-on-bsc": "pbtc-on-eth",
	"pbtc-on-xdai": "pbtc-on-eth",
	"pbtc-on-bsc": "pbtc-on-eth",
	"pbtc-on-eos": "pbtc-on-eos",
	"pltc-on-eos": "pbtc-on-eos",
	"pbtc-on-telos": "pbtc-on-eos",
	"perc20-on-evm": "perc20-on-evm",
	"perc20-on-bsc": "perc20-on-evm",
	"perc20-on-xdai": "perc20-on-evm",
	"peos-on-eth": "peos-on-eth",
	"ptelos-on-eth": "peos-on-eth",
	"ptelos-on-bsc": "peos-on-eth",
	"perc20-on-telos": "perc20-on-eos",
	"perc20-on-eos": "perc20-on-eos",
	"pultra-on-eth": "peos-on-eth",
	"pbep20-on-eth": "perc20-on-evm",
	"pbep20-on-polygon": "perc20-on-evm",
	"pbtc-on-ultra": "pbtc-on-eos",
	"pbtc-on-polygon": "pbtc-on-eth", 
        "pbtc-on-arbitrum": "pbtc-on-eth",
	"pbtc-on-polygon": "pbtc-on-eth",
	"pore-on-eth": "peos-on-eth"
}'
