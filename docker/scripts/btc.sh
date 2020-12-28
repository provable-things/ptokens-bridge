#!/bin/bash 

SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/utils.sh
[ -f "$SCRIPT_UTILS" ] && . "$SCRIPT_UTILS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"

function initialize_btc_fork() {
  local fork
  local native_network

  fork=$1
  #shellcheck disable=SC2153
  native_network=$(capitalize_first_letter "$NATIVE_NETWORK")
  cd "$FOLDER_PROXY" && $EXC_PROXY initializeBtc \
    --fee="$NATIVE_FEE" \
    --difficulty="$NATIVE_DIFFICULTY" \
    --network="$native_network" \
    --confs="$NATIVE_CONFS" \
    --file="$FOLDER_SYNC/${NATIVE_SYMBOL}-init.json" \
  1> "$FOLDER_SYNC/.${NATIVE_SYMBOL}-init-output.json"

  # shellcheck disable=SC2181
  [[ ! $? -eq 0 ]] \
    && loge "Failed to initialize enclave...aborting!" && exit 1 \
    || logi "Initializing ${fork^^} side...done"
}


function initialize_btc() {
  initialize_btc_fork "btc"
}

function get_enclave_public_key() {
  __public_key=$1

  local key
  key=""

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
  local symbol
  local enclave_state
  local enclave_public_key
  local apiserver_sync_file
  local btc_syncer_file
  local btc_broadcaster_file

  symbol=$(echo "$NATIVE_SYMBOL $HOST_SYMBOL" | grep -E -o '(btc|ltc|dash)')

  get_enclave_public_key enclave_public_key

  apiserver_sync_file=$FOLDER_SYNC/api-server.json
  btc_syncer_file=$FOLDER_SYNC/$symbol-syncer.json
  btc_broadcaster_file=$FOLDER_SYNC/$symbol-broadcaster.json
  
  maybe_initialize_json_file "$btc_syncer_file"
  maybe_initialize_json_file "$apiserver_sync_file"
  maybe_initialize_json_file "$btc_broadcaster_file"

  local api_content
  api_content=$(jq ".ENCLAVE_PUBLIC_KEY=\"$enclave_public_key\"" "$apiserver_sync_file")

  logd "$api_content"

  echo "$api_content" > "$apiserver_sync_file"

  touch_start_files "$symbol"

  logi "${symbol^^} configuration material ready"
}