#!/bin/bash
SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/utils.sh
[ -f "$SCRIPT_UTILS" ] && . "$SCRIPT_UTILS"


function get_chain_id_flag() {
  __chain_id=$1
  chain_id=null

  case $NATIVE_SYMBOL in
    btc|ltc|dash|doge|rvn )
      chain_id="--chainId"
      ;;
    * )
      chain_id="--eosChainId"
      ;;
  esac

  # shellcheck disable=SC2140
  eval "$__chain_id"="'$chain_id'"
}


function maybe_add_account_name() {
  local account_name
  local reduced_bridge_type

  reduced_bridge_type=$1
  command=$2
  __new_command=$3

  if [[ "$reduced_bridge_type" != "perc20-on-eos" ]]; then
    get_or_exit "${type^^}_EOS_ACCOUNT_NAME" account_name
    command="$command --accountName=$account_name"
  fi

  # shellcheck disable=SC2140
  eval "$__new_command"="'$command'"
}

function maybe_add_token_symbol() {
  local reduced_bridge_type
  local reduced_native_symbol
  local eos_token_symbol

  reduced_bridge_type=$1
  command=$2
  __new_command=$3

  get_native_symbol_from_bridge_type \
    "$reduced_bridge_type" \
    reduced_native_symbol

  if [[ "$reduced_native_symbol" == "btc" ]]; then
    get_or_exit "${type^^}_EOS_TOKEN_SYMBOL" eos_token_symbol 
    command="$cmd --symbol=$eos_token_symbol"
  fi

  # shellcheck disable=SC2140
  eval "$__new_command"="'$command'"
}

function get_eos_init_command() {
  local type
  local symbol
  local bridge_type
  local reduced_symbol
  local reduced_bridge_type
  
  local chain_id

  type=$1
  symbol=$2
  reduced_symbol=$3

  __cmd=$4

  bridge_type="p${NATIVE_SYMBOL}-on-${HOST_SYMBOL}"
    
  get_reduced_bridge_type "$bridge_type" reduced_bridge_type
  
  get_or_exit "${type^^}_EOS_CHAIN_ID" chain_id
  
  cmd="cd $FOLDER_PROXY && $EXC_PROXY initializeEos"
  cmd="$cmd --chainId=$chain_id"

  maybe_add_account_name "$reduced_bridge_type" "$cmd" cmd 

  maybe_add_token_symbol "$reduced_bridge_type" "$cmd" cmd
  
  cmd="$cmd --file=$FOLDER_SYNC/$symbol-init.json"
  cmd="$cmd 1> $FOLDER_SYNC/.$symbol-init-output.json"

  logd "${symbol^^} init command: $cmd"

  # shellcheck disable=SC2140
  eval "$__cmd"="'$cmd'"
}

function eos_init() {
  local type
  local symbol
  local init_command
  local reduced_symbol

  type=$1
  symbol=$2
  reduced_symbol=$3

  get_eos_init_command \
    "$type" \
    "$symbol" \
    "$reduced_symbol" \
    init_command

  eval "$init_command"
}

function initialize_eos() {
  local type
  local symbol
  local reduced_symbol

  type=$1
  symbol=$2
  reduced_symbol=eos
  eos_init "$type" "$symbol" "$reduced_symbol"
}

function prepare_eos_sync_material() {
  local type
  local symbol
  local identity

  type=$1
  symbol=$2

  logd "type: $type"

  syncer_file=$FOLDER_SYNC/$symbol-syncer.json
  broadcaster_file=$FOLDER_SYNC/$symbol-broadcaster.json
  apiserver_file=$FOLDER_SYNC/api-server.json

  maybe_initialize_json_file "$syncer_file"
  maybe_initialize_json_file "$apiserver_file"
  maybe_initialize_json_file "$broadcaster_file"

  get_or_exit "${type^^}_EOS_ACCOUNT_NAME" identity

  api_content=$(jq ".${type^^}_IDENTITY=\"$identity\"" "$apiserver_file")

  touch_start_files "$symbol"

  logi "${symbol^^} configuration material ready"
}
