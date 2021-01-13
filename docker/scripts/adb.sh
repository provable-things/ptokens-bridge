#!/bin/bash

function adb_proxy() {
	/usr/bin/adb -s "$ADB_DEVICE_ID" "$@"
}

function adb_uninstall() {
  local package_name
  package_name=io.ptokens.p${NATIVE_SYMBOL}on${HOST_SYMBOL}
  if [[ $(adb_proxy uninstall "$package_name" 1>> /dev/null) -ne 0 ]]; then
    logi "Failed to uninstall $package_name: maybe app doesn't exist..."
  else
    logi "Uninstalling $package_name...done!"
  fi
}

function maybe_set_write_storage_permissions() {
  local package_name
  local permission
  package_name=io.ptokens.p${NATIVE_SYMBOL}on${HOST_SYMBOL}
  permission=android.permission.WRITE_EXTERNAL_STORAGE
  if [[ $(adb_proxy shell pm grant "$package_name" "$permission") -ne 0 ]]; then
  	loge "Failed to set the permission...aborting!"
  else
    logi "WRITE_EXTERNAL_STORAGE permission set!"
  fi
}

function adb_push_smart_contract_bytecode() {
	adb_proxy push \
    "$FOLDER_SYNC/smart-contract-bytecode" \
    /data/local/tmp/ \
    1>> /dev/null 
}
function adb_install() {
	local apk
  apk=$FOLDER_PROXY/$APK_NAME
        
  if [[ $(adb_proxy install "$apk" 1>> /dev/null) -ne 0 ]]; then
    loge "Failed to install $apk: abort!"
    exit 1
  else
    logi "Installing $apk...done!"
  fi
  
  maybe_set_write_storage_permissions
}
