#!/bin/bash 

SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/utils.sh
[ -f "$SCRIPT_UTILS" ] && . "$SCRIPT_UTILS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"

function get_btc_init_command() {
  local type
  local symbol
  local bridge_type
  local reduced_symbol

  type=$1
  symbol=$2
  reduced_symbol=$3
  
  __cmd=$4

  local fee
  local confs
  local network
  local difficulty

  get_or_exit "${type^^}_BTC_FEE" fee
  get_or_exit "${type^^}_NETWORK" network
  get_or_exit "${type^^}_BTC_CONFS" confs
  get_or_exit "${type^^}_BTC_DIFFICULTY" difficulty

  network=$(capitalize_first_letter "$network")

  cmd="cd $FOLDER_PROXY && $EXC_PROXY initializeBtc"
  cmd="$cmd --fee=$fee" 
  cmd="$cmd --confs=$confs" 
  cmd="$cmd --network=$network" 
  cmd="$cmd --difficulty=$difficulty" 
  cmd="$cmd --file=$FOLDER_SYNC/$symbol-init.json" 
  cmd="$cmd 1> $FOLDER_SYNC/.$symbol-init-output.json"

  logd "${symbol^^} init command: $cmd"

  # shellcheck disable=SC2140
  eval "$__cmd"="'$cmd'"
}

function btc_init() {
  local type
  local symbol
  local init_command
  local reduced_symbol

  type=$1
  symbol=$2
  reduced_symbol=$3

  get_btc_init_command \
    "$type" \
    "$symbol" \
    "$reduced_symbol" \
    init_command

  eval "$init_command"  
}

function get_enclave_public_key() {

  local key
  local enclave_state

  key=""
  __public_key=$1

  case "$ENV_VERSION" in
    1 )
      key=btc_public_key
      ;;
    2 )
      key=btc.btc_public_key
      ;;
  esac

  get_enclave_state enclave_state

  logd "$enclave_state"

  enclave_public_key=$(echo "$enclave_state" | jq -r ".$key")
  
  logd "enclave_public_key: $enclave_public_key"

  # shellcheck disable=SC2140
  eval "$__public_key"="'$enclave_public_key'"
}

function prepare_btc_sync_material() {
  local type
  local symbol

  local api_content
  local syncer_file
  local apiserver_file
  local broadcaster_file
  local enclave_public_key

  type=$1
  symbol=$2

  logd "type: $type"

  apiserver_file=$FOLDER_SYNC/api-server.json
  syncer_file=$FOLDER_SYNC/$symbol-syncer.json
  broadcaster_file=$FOLDER_SYNC/$symbol-broadcaster.json
  
  maybe_initialize_json_file "$syncer_file"
  maybe_initialize_json_file "$apiserver_file"
  maybe_initialize_json_file "$broadcaster_file"

  get_enclave_public_key enclave_public_key

  api_content=$(jq " \
    .ENCLAVE_PUBLIC_KEY=\"$enclave_public_key\" | \
    .RELATIVE_PATH_TO_ADDRESS_GENERATOR=\"/home/provable/proxy\"" \
    "$apiserver_file" \
  )

  logd "$api_content"

  echo "$api_content" > "$apiserver_file"

  touch_start_files "$symbol"

  logi "${symbol^^} configuration material ready"
}

function initialize_btc() {
  local type
  local symbol
  local reduced_symbol

  type=$1
  symbol=$2
  reduced_symbol=btc

  btc_init "$type" "$symbol" "$reduced_symbol"
}