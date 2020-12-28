#!/bin/bash 

# shellcheck disable=SC2034
SCRIPT_DB=$HOME/scripts/db.sh
# shellcheck disable=SC2034
# shellcheck disable=SC2034
SCRIPT_LOG=$HOME/scripts/log.sh
# shellcheck disable=SC2034
SCRIPT_EOS=$HOME/scripts/eos.sh
# shellcheck disable=SC2034
SCRIPT_ETH=$HOME/scripts/eth.sh
# shellcheck disable=SC2034
SCRIPT_BTC=$HOME/scripts/btc.sh
# shellcheck disable=SC2034
SCRIPT_TELOS=$HOME/scripts/telos.sh
# shellcheck disable=SC2034
SCRIPT_UTILS=$HOME/scripts/utils.sh
# shellcheck disable=SC2034
SCRIPT_ERC20=$HOME/scripts/erc20.sh

# shellcheck disable=SC2034
FILE_SMART_CONTRACT_BYTECODE=$HOME/sync
# shellcheck disable=SC2034
FILE_SAFETY=$FOLDER_PROXY/.new

# shellcheck disable=SC2034
EXC_PROXY=./$TEE
# shellcheck disable=SC2034
EXC_ADB=/usr/bin/adb

# shellcheck disable=SC2034
REGEX_SUPPORTED_SYMBOLS="(eth|erc20|eos|telos|btc|ltc|dash)"