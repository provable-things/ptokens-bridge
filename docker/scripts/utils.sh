#!/bin/bash
SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"

function wait_file() {
  local file
  local count
  file=$1
  count=0
  while [[ ! -f "$file" ]]; do
    logd "waiting for $file..."
    sleep 5;
    count=$((count + 1))
    [[ $count -ge 50 ]] \
      && loge "Waited too long, aborting..." && exit 1 \
      || :
  done
}

function wait_for_one() {
  file1=$1
  file2=$2
  while [[ ! -f "$file1" && ! -f "$file2" ]]; do
    logd "waiting for $file..."
    sleep 3;
  done
}

function exit_if_empty() {
  [ -z "$1" ] && loge "$2" && exit 1 || :
}

function remove_sync_files() {
  rm -rf "${FOLDER_SYNC:?}/*"
}

function safety_check() {
  if [[ -f $FILE_SAFETY ]]; then
    rm "$FILE_SAFETY "
  else
    loge "Safety enabled, run \`touch ${FOLDER_SYNC}/.new\`"
    exit 1
  fi
}

function capitalize_first_letter() {
  local ret 
  ret=$(tr '[:lower:]' '[:upper:]' <<< "${1:0:1}")${1:1}
  echo "$ret"
}

function maybe_uninstall_app() {
  local package_name
  package_name=io.ptokens.p${NATIVE_SYMBOL}on${HOST_SYMBOL}
  case $TEE in
    strongbox )
      
      [[ ! $($EXC_ADB uninstall "$package_name" 1>> /dev/null) ]] \
        && logi "Failed to uninstall $package_name: maybe app doesn't exist..." \
        || logi "Uninstalling $package_name...done!"
      ;;
  esac
}

function maybe_install_app() {
  local apk_name=$HOME/p${NATIVE_SYMBOL}on${HOST_SYMBOL}-debug.apk
  case $TEE in
    strongbox )
      [[ ! $($EXC_ADB install "$apk_name" >> /dev/null) ]] \
        && loge "Failed to install $apk_name: abort!" && exit 1 \
        || logi "Installing $apk_name...done!"

      maybe_set_write_storage_permissions
      ;;
  esac

}

function drop_logs() {
  case $TEE in
    vanilla )
      [[ ! $(rm -r "$FOLDER_PROXY/logs" 2> /dev/null) ]] \
        && logi "Failed to drop the logs, maybe folder doesn't exist..." \
        || logi "Dropping logs...done!"
      ;;
  esac 
}

function drop_sync_files() {
  rm "$FOLDER_SYNC"/*.json 2> /dev/null
  rm "$FOLDER_SYNC"/*.start 2> /dev/null

  [[ "$SKIP_SMART_CONTRACT_BYTECODE_GENERATION" -ne "1" ]] \
    && rm -f "$FOLDER_SYNC/smart-contract-bytecode" \
    || :

  logi "Removing sync files...done!"
}

function grant_permission() {
  local package_name
  local permission

  package_name=$1
  permission=$2

  $EXC_ADB shell pm grant "$package_name" "$permission" >> /dev/null 
}

function maybe_set_write_storage_permissions() {
  local package_name
  local permission
  package_name=io.ptokens.p${NATIVE_SYMBOL}on${HOST_SYMBOL}
  permission=android.permission.WRITE_EXTERNAL_STORAGE
  case $TEE in
    strongbox )
      if [[ $(grant_permission "$package_name" "$permission") ]]; then
        logi "WRITE_EXTERNAL_STORAGE permission set!"
      else
        loge "Failed to set the permission...aborting!"
      fi
      ;;
  esac
}

function maybe_initialize_json_file() {
  local file
  file=$1
  
  if [[ ! -f "$file" ]]; then
    logd "initialize $file"
    echo "{}" > "$file"
  fi
}

function get_enclave_state() {
  enclave_state=$(cd "$FOLDER_PROXY" && $EXC_PROXY getEnclaveState)
  __enclave_state=$1

  # shellcheck disable=SC2140
  eval "$__enclave_state"="'$enclave_state'"
}

function touch_start_files() {
  local symbol
 
  symbol=$1
  
  touch "$FOLDER_SYNC/$symbol-broadcaster.start"
  touch "$FOLDER_SYNC/$symbol-syncer.start"
}

function check_safetyfile_exists() {
  [[ ! -f $FILE_SAFETY ]] \
    && loge "Safety file not defined, aborting!" \
    && exit 1 \
    || :
}

function is_native() {
  local symbol

  [[ "$NATIVE_SYMBOL" == "$symbol" ]] \
    && return 0 \
    || return 1
}

function is_host() {
  local symbol

  [[ "$HOST_SYMBOL" == "$symbol" ]] \
    && return 0 \
    || return 1
}

function add_bridge_info() {
  local public_key
  local api_server_file
  local smart_contract_address
  
  api_server_file=$FOLDER_SYNC/api-server.json

  # TODO: this supports pbtc-on-eth only

  if [[ -f "$api_server_file" ]]; then
    # native_address=$(jq -r '.ENCLAVE_PUBLIC_KEY' "$api_server_file")
    smart_contract_address=$(jq -r '.SMART_CONTRACT_ADDRESS' "$api_server_file")

    bridge='{
      "p'$NATIVE_SYMBOL'-on-'$HOST_SYMBOL'": {
        "NATIVE_TOKEN_ADDRESS": "'$public_key'",
        "HOST_TOKEN_ADDRESS": "'$smart_contract_address'",
        "NATIVE_SYMBOL": "'$NATIVE_SYMBOL'",
        "HOST_SYMBOL": "'$HOST_SYMBOL'"
      }
    }'
    
    new_api_json=$(jq ".BRIDGES=$bridge" "$api_server_file")

    logd "$new_api_json"
    echo "$new_api_json" > "$api_server_file"
  fi
}