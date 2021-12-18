#!/bin/bash
SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

# shellcheck source=./scripts/constants.sh
[ -f "$SCRIPT_CONSTANTS" ] && . "$SCRIPT_CONSTANTS"
# shellcheck source=./scripts/log.sh
[ -f "$SCRIPT_LOG" ] && . "$SCRIPT_LOG"
# shellcheck source=./scripts/adb.sh
[ -f "$SCRIPT_ADB" ] && . "$SCRIPT_ADB"
# shellcheck source=./scripts/nitro.sh
[ -f "$SCRIPT_NITRO" ] && . "$SCRIPT_NITRO"

function wait_file() {
  local file
  local count
  file=$1
  count=0
  while [[ ! -f "$file" ]]; do
    logd "waiting for $file..."
    sleep 5;
    count=$((count + 1))
    if [[ "$count" -ge 50 ]]; then
      loge "Waited too long, aborting..."
      exit 1
    fi
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
  if [ -z "$1" ]; then loge "$2"; exit 1; fi
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
  case $TEE in
    strongbox )
      adb_uninstall
      ;;
  esac
}

function maybe_install_app() {
  case $TEE in
    strongbox )
      adb_install
      ;;
  esac

}

function drop_logs() {
  case $TEE in
    vanilla )
      if rm -r "$FOLDER_PROXY/logs" 2> /dev/null; then
        logi "Dropping logs...done!"
      else
        logi "Failed to drop the logs, maybe folder doesn't exist..."
      fi
      ;;
  esac 
}

function drop_sync_files() {
  if [[ -z "$SKIP_INIT_BLOCK" ]]; then
    rm "$FOLDER_SYNC"/*.json 2> /dev/null  
  fi
  rm "$FOLDER_SYNC"/*.start 2> /dev/null

  logi "Removing sync files...done!"
}

function grant_permission() {
  local package_name
  local permission

  package_name=$1
  permission=$2

  logd "Permissions to $package_name $permission"
  
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
  if [[ ! -f $FILE_SAFETY ]]; then
    loge "Safety file not defined, aborting!"
    exit 1
  fi
}

function is_native() {
  local regex
  regex=$1
  echo "$NATIVE_SYMBOL" | grep -E -o "$regex"
}

function is_host() {
  local regex
  regex=$1
  echo "$HOST_SYMBOL" | grep -E -o "$regex"
}


function maybe_install_proxy_deps() {
  case $TEE in
    strongbox )
      logi "Installing node dependencies into $FOLDER_PROXY"
      pnpm install -C "$FOLDER_PROXY" 1> /dev/null
      ;;
    vanilla )
      ;;
    nitro )
      ;;
    *)
      loge "Unknown TEE, aborting!"
      exit 1
      ;;
  esac
}

function check_enclave_is_ready() {
  case $TEE in
    strongbox )
      ;;
    vanilla )
      ;;
    nitro )
      ping_nitro
      logi "Nitro enclave is listening!"
      ;;
  esac 
}

function get_symbol() {
  local regexp
  regexp=$1
  __symbol=$2
  
  symbol=$(echo "$NATIVE_SYMBOL $HOST_SYMBOL" | grep -E -o "$regexp")

  if [[ -z "$symbol" ]]; then
    loge "Failed to get the symbol using this regexp: $regexp"
    exit 1
  fi

  # shellcheck disable=SC2140
  eval "$__symbol"="'$symbol'"
}

function get_type() {
  local symbol
  symbol=$1
  __type=$2

  type=null
  if [[ "$NATIVE_SYMBOL" == "$symbol" ]]; then
    type=native
  elif [[ "$HOST_SYMBOL" == "$symbol" ]]; then
    type=host
  else
    loge "Unable to find the type for $symbol"
    exit 1
  fi

  # shellcheck disable=SC2140
  eval "$__type"="'$type'"
}

function get_reduced_bridge_type() {
  local bridge_type
  bridge_type=$1

  __reduced_bridge_type=$2

  reduced_bridge_type=$(jq -r ".\"$bridge_type\"" <<< "$REDUCED_BRIDGE_TYPE_MAPPING")

  # shellcheck disable=SC2140
  eval "$__reduced_bridge_type"="'$reduced_bridge_type'"
}

function get_native_symbol_from_bridge_type() {
  local bridge_type
  bridge_type=$1
  __native_symbol=$2

  native_symbol=$(\
    grep -E -o 'p[a-z0-9]{3,}' <<< "$bridge_type" \
      | awk '{print substr($1, 2)}' \
  )

  # shellcheck disable=SC2140
  eval "$__native_symbol"="'$native_symbol'"
}

function get_host_symbol_from_bridge_type() {
  local bridge_type
  bridge_type=$1
  __host_symbol=$2

  host_symbol=$(\
    grep -E -o '\-[a-z0-9]{3,}' <<< "$bridge_type" \
      | awk '{print substr($1, 2)}' \
  )

  # shellcheck disable=SC2140
  eval "$__host_symbol"="'$host_symbol'"
}

function get_or_exit() {
  configurable=$1
  __conf_value=$2

  # shellcheck disable=SC2140  
  eval "value"="\$$configurable"

  # shellcheck disable=SC2154  
  exit_if_empty "$value" "Value for $configurable is missing!"

  # shellcheck disable=SC2140
  eval "$__conf_value"="'$value'"
}