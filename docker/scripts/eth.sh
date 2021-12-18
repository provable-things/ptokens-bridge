#!/bin/bash

SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/utils.sh
[ -f "$SCRIPT_UTILS" ] && . "$SCRIPT_UTILS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"
# shellcheck source=./scripts/adb.sh
[ -f "$SCRIPT_ADB" ] && . "$SCRIPT_ADB"

function maybe_push_smartcontract_bytecode() { 
  case $TEE in
    strongbox )
      if [[ $(adb_push_smart_contract_bytecode) -ne 0 ]]; then
        loge "Failed to push the file...aborting!"
        exit 1
      else
        logi "Smart contract bytecode pushed...done!"
      fi
      ;;
  esac
}

function is_eos_related_bridge() {
  local bridge_type
  local reduced_bridge_type

  bridge_type="p$NATIVE_SYMBOL-on-$HOST_SYMBOL"

  get_reduced_bridge_type "$bridge_type" reduced_bridge_type

  grep -E 'eos' <<< "$reduced_bridge_type" 1> /dev/null
}

function get_command_name() {
  local reduced_symbol
  reduced_symbol=$1
  __command_name=$2

  command_name=null
  case $reduced_symbol in
    eth|erc20 )
      command_name=initializeEth
      ;;
    evm )
      command_name=initializeEvm
      ;;
    * )
      loge "Couldn't find command name for reduced symbol: $reduced_symbol!"
      exit 1
  esac

  logd "Command name is $command_name"

  # shellcheck disable=SC2140
  eval "$__command_name"="'$command_name'"
}

function get_eth_init_command() {
  local type
  local symbol
  local bridge_type
  local reduced_symbol

  local confs
  local chain_id
  local gasprice

  type=$1
  symbol=$2
  reduced_symbol=$3
  
  __cmd=$4

  get_or_exit "${type^^}_ETH_CONFS" confs
  get_or_exit "${type^^}_ETH_CHAIN_ID" chain_id
  get_or_exit "${type^^}_ETH_GASPRICE" gasprice

  get_command_name "$reduced_symbol" command_name

  cmd="cd $FOLDER_PROXY && $EXC_PROXY $command_name"
  cmd="$cmd --confs=$confs"
  cmd="$cmd --gasPrice=$gasprice"
  cmd="$cmd --chainId=$chain_id"
  cmd="$cmd --file=$FOLDER_SYNC/$symbol-init.json"
  cmd="$cmd 1> $FOLDER_SYNC/.$symbol-init-output.json"

  logd "${symbol^^} init command: $cmd"

  # shellcheck disable=SC2140
  eval "$__cmd"="'$cmd'"
}

function maybe_set_contract_address() {
  local set_contract_address_cmd 
  logd "heeeeeere"  
  case $TEE in
    nitro )
      set_contract_address_cmd="cd $FOLDER_PROXY && $EXC_PROXY addErc777ContractAddress 0x0000000000000000000000000000000000000000"
      if eval "$set_contract_address_cmd"; then
        logi "Erc777 contract address set!"
      else
	loge "Failed to set the contract address!"
	logd "This command failed: $set_contract_address_cmd"
	exit 1
      fi
      ;;
  esac
}

function eth_init() {
  local type
  local symbol
  local init_command
  local reduced_symbol

  type=$1
  symbol=$2
  reduced_symbol=$3

  maybe_push_smartcontract_bytecode
  
  get_eth_init_command \
    "$type" \
    "$symbol" \
    "$reduced_symbol" \
    init_command
  
  eval "$init_command"

  maybe_set_contract_address
}

function get_smart_contract_address() {
  init_file=$1
  __smart_contract_address=$2

  smart_contract_address=null

  logd "Checking init file $init_file"

  smart_contract_address=$(jq -r .smart_contract_address "$init_file")
  if [ "$smart_contract_address" == "null" ]; then
    exit_if_empty "Variable SMART_CONTRACT_ADDRESS is required for this bridge type!"
    # shellcheck disable=SC2153
    smart_contract_address=$SMART_CONTRACT_ADDRESS
    logd "Smart contract address is $smart_contract_address"    
  fi

  # shellcheck disable=SC2140
  eval "$__smart_contract_address"="'$smart_contract_address'"
}

function prepare_eth_sync_material() {
  local type
  local symbol
  local eth_address
  local initialization_file
  local smart_contract_address
  local syncer_file
  local apiserver_file
  local broadcaster_file

  type=$1
  symbol=$2

  initialization_file=$FOLDER_SYNC/.$symbol-init-output.json
  
  eth_address=$(jq -r '.eth_address' "$initialization_file")

  # If peos-on-eth or erc20 bridge the value must be manually submitted with
  # through SMART_CONTRACT_ADDRESS in the .env file
  # shellcheck disable=SC2153
  get_smart_contract_address "$initialization_file" smart_contract_address

  logd "type: $type"
  logd "eth_address: $eth_address"
  logd "smart_contract_address: $smart_contract_address"

  syncer_file=$FOLDER_SYNC/$symbol-syncer.json
  broadcaster_file=$FOLDER_SYNC/$symbol-broadcaster.json
  apiserver_file=$FOLDER_SYNC/api-server.json

  maybe_initialize_json_file "$syncer_file"
  maybe_initialize_json_file "$apiserver_file"
  maybe_initialize_json_file "$broadcaster_file"

  local api_content
  local broadcaster_content

  broadcaster_content=$(jq \
    ".ENCLAVE_ADDRESS=\"$eth_address\"" \
    "$broadcaster_file" \
  )

  api_content=$(jq "\
    .SMART_CONTRACT_ADDRESS=\"$smart_contract_address\" | \
    .${type^^}_IDENTITY=\"$eth_address\"" \
    "$apiserver_file" \
  )

  echo "$broadcaster_content" > "$broadcaster_file"
  echo "$api_content" > "$apiserver_file"

  touch_start_files "$symbol"

  logi "${symbol^^} configuration material ready"
}

function maybe_generate_smartcontract_bytecode() {
  local smart_contract_generator_start
  local smart_contract_bytecode
  smart_contract_bytecode=$FOLDER_SYNC/smart-contract-bytecode
  smart_contract_generator_start=$FOLDER_SYNC/smart-contract-generator.start

  # State machine
  #   state 0: file has never been created or has been corrupted
  #   state 1: bytecode as been generated properly
  #   state 2: bytecode as been initialized with 00
  #
  # new: is a request to generate a new bytecode
  # stop: is a request to exit immediately because
  #       the bytecode is not needed
  if [[ ! -s "$smart_contract_bytecode" ]]; then
    # file doesn't exist or is empty
    # state 0
    if [[ -z "$SKIP_SMART_CONTRACT_BYTECODE_GENERATION" ]]; then
      # go to state 1
      echo "new" > "$smart_contract_generator_start"
    else
      # go to state 2
      echo "00" > "$smart_contract_bytecode"
      echo "stop" > "$smart_contract_generator_start"
    fi
  else
    if [[ $(wc -m "$smart_contract_bytecode" | awk '{print $1}') -le 3 ]]; then
      # state 2
      if [[ -z "$SKIP_SMART_CONTRACT_BYTECODE_GENERATION" ]]; then
        # go to state 1
        echo "new" > "$smart_contract_generator_start"
      else
        # do nothing
        echo "stop" > "$smart_contract_generator_start"
      fi
    else
      # state 1
      if [[ -z "$SKIP_SMART_CONTRACT_BYTECODE_GENERATION" ]]; then
        # go to state 1
        echo "new" > "$smart_contract_generator_start"
      else
        # do nothing
        echo "stop" > "$smart_contract_generator_start"
      fi
    fi
  fi
}

function initialize_eth() {
  local side
  local symbol
  local reduced_symbol

  side=$1
  symbol=$2
  reduced_symbol="eth"

  eth_init "$side" "$symbol" "$reduced_symbol"
}

function initialize_evm() {
  local side
  local symbol
  local reduced_symbol

  side=$1
  symbol=$2
  reduced_symbol="evm"

  eth_init "$side" "$symbol" "$reduced_symbol"
}

function initialize_erc20() {
  local side
  local symbol
  local reduced_symbol

  side=$1
  symbol=$2
  reduced_symbol="erc20"

  eth_init "$side" "$symbol" "$reduced_symbol"
}

