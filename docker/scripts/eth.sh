SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

[ -f $SCRIPT_CONSTANTS ] && . $SCRIPT_CONSTANTS
[ -f $SCRIPT_UTILS ] && . $SCRIPT_UTILS
[ -f $SCRIPT_LOG ] && . $SCRIPT_LOG

function maybe_push_smartcontract_bytecode() { 
  case $TEE in
    strongbox )
      $EXC_ADB push \
        $FOLDER_SYNC/smart-contract-bytecode \
        /data/local/tmp/ \
        1>> /dev/null 
          
      [[ ! $? -eq 0 ]] \
        && loge "Failed to push the file...aborting!" && exit 1 \
        || logi "Smart contract bytecode pushed...done!"
      ;;
  esac
}

function eth_init() {
  local symbol
  local confs
  local chain_id
  local gas_price

  symbol=$1
  confs=$2
  chain_id=$3
  gas_price=$4

  maybe_push_smartcontract_bytecode
  
  case $TEE in
    nitro )
      cd $FOLDER_PROXY && $EXC_PROXY initializeEth \
        --FILE=$FOLDER_SYNC/smart-contract-bytecode \
        --confs=$confs \
        --gasPrice=$gas_price \
        --chainId=$chain_id \
        --file=$FOLDER_SYNC/$symbol-init.json \
        1> $FOLDER_SYNC/.$symbol-init-output.json    
      ;;
    * )
      cd $FOLDER_PROXY && $EXC_PROXY initializeEth \
        $FOLDER_SYNC/smart-contract-bytecode \
        --confs=$confs \
        --gasPrice=$gas_price \
        --chainId=$chain_id \
        --file=$FOLDER_SYNC/$symbol-init.json \
        1> $FOLDER_SYNC/.$symbol-init-output.json
      ;;
  esac

  [[ $? -ne 0 ]] \
    && loge "Failed to initialize enclave...aborting!" && exit 1 \
    || logi "Initializing ETH side...done"
}


function eth_init_native() {
  exit_if_empty "$NATIVE_SYMBOL" "Invalid NATIVE_SYMBOL submitted"
  exit_if_empty "$NATIVE_CHAIN_ID" "Invalid NATIVE_CHAIN_ID submitted"
  exit_if_empty "$NATIVE_GASPRICE" "Invalid NATIVE_GASPRICE submitted"
  exit_if_empty "$NATIVE_CONFS" "Invalid NATIVE_CONFS submitted"

  eth_init \
    "$NATIVE_SYMBOL" \
    "$NATIVE_CONFS" \
    "$NATIVE_CHAIN_ID" \
    "$NATIVE_GASPRICE"
}

function eth_init_host() {
  eth_init \
    "$HOST_SYMBOL" \
    "$HOST_CONFS" \
    "$HOST_CHAIN_ID" \
    "$HOST_GASPRICE"
  exit_if_empty "$HOST_SYMBOL" "Invalid HOST_SYMBOL submitted"
  exit_if_empty "$HOST_CHAIN_ID" "Invalid HOST_CHAIN_ID submitted"
  exit_if_empty "$HOST_GASPRICE" "Invalid HOST_GASPRICE submitted"
  exit_if_empty "$HOST_CONFS" "Invalid HOST_CONFS submitted"
}

function initialize_eth() {
  [[ `env | egrep '^(eth|erc20)$' | grep 'NATIVE'` ]] \
  && eth_init_native \
  || eth_init_host
}

function initialize_erc20() {
  initialize_eth
}


function prepare_eth_sync_material() {
  local symbol
  local initialization_output
  local smart_contract_address
  local enclave_address
  local syncer_file
  local apiserver_file
  local broadcaster_file

  symbol=`echo "$NATIVE_SYMBOL $HOST_SYMBOL" | egrep -o "(erc20|eth)"`
  initialization_output=`cat $FOLDER_SYNC/.$symbol-init-output.json`

  smart_contract_address=`echo $initialization_output \
    | jq  -r '.smart_contract_address'`
  enclave_address=`echo $initialization_output \
    | jq  -r '.eth_address'`

  logd "enclave_address: $enclave_address"
  logd "smart_contract_address: $smart_contract_address"

  syncer_file=$FOLDER_SYNC/$symbol-syncer.json
  broadcaster_file=$FOLDER_SYNC/$symbol-broadcaster.json
  apiserver_file=$FOLDER_SYNC/api-server.json

  maybe_initialize_json_file "$syncer_file"
  maybe_initialize_json_file "$apiserver_file"
  maybe_initialize_json_file "$broadcaster_file"

  local broadcaster_content
  broadcaster_content=`cat $broadcaster_file \
    | jq ".ENCLAVE_ADDRESS=\"$enclave_address\""`

  local api_content
  api_content=`cat $apiserver_file \
    | jq ".SMART_CONTRACT_ADDRESS=\"$smart_contract_address\""`

  echo "$broadcaster_content" > $broadcaster_file
  echo "$api_content" > $apiserver_file

  touch_start_files "$symbol"

  logi "${symbol^^} configuration material ready"
}