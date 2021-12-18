#!/bin/bash

function adb_proxy() {
	/usr/bin/adb -s "$ADB_DEVICE_ID" "$@"
}

function adb_uninstall() {
  local package_name
  package_name=io.ptokens.p${NATIVE_SYMBOL}on${HOST_SYMBOL}
  if adb_proxy uninstall "$package_name" > /dev/null; then
    logi "Uninstalling $package_name...done!"
  else
    logi "Failed to uninstall $package_name: maybe app doesn't exist..."
  fi
}

function maybe_set_write_storage_permissions() {
  local package_name
  local permission
  package_name=io.ptokens.p${NATIVE_SYMBOL}on${HOST_SYMBOL}
  permission=android.permission.WRITE_EXTERNAL_STORAGE
  if adb_proxy shell pm grant "$package_name" "$permission"; then
    logi "WRITE_EXTERNAL_STORAGE permission set!"
  else
  	loge "Failed to set the permission...aborting!"
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
        
  if [[ ! -f "$apk" ]]; then
    loge "APK not found at $apk"
    exit 1
  fi

  if adb_proxy install "$apk" 1> /dev/null; then
    logi "Installing $apk...done!"
  else
    loge "Failed to install $apk: abort!"
    exit 1
  fi
  
  maybe_set_write_storage_permissions
}
