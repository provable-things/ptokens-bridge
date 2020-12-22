SCRIPT_CONSTANTS=$HOME/scripts/constants.sh

[ -f $SCRIPT_CONSTANTS ] && . $SCRIPT_CONSTANTS
[ -f $SCRIPT_UTILS ] && . $SCRIPT_UTILS

function eos_init() {
  local symbol
	local chainId
	local account_name
  symbol=$1
  chainId=$2
  account_name=$3

  cd $FOLDER_PROXY && $EXC_PROXY initializeEos \
    --symbol=$symbol \
    --chainId=$chainId \
    --accountName=$account_name \
  	--file=$FOLDER_SYNC/$symbol-init.json \
    1> $FOLDER_SYNC/.$symbol-init-output.json

  [[ ! $? -eq 0 ]] \
    && loge "Failed to initialize enclave...aborting!" && exit 1 \
    || logi "Initializing EOS side...done"
}

function erc20_eos_init() {
	local symbol	
	local chain_id
	symbol=$1
	chain_id=$2

  cd $FOLDER_PROXY && $EXC_PROXY initializeEos \
    --eosChainId=$chain_id \
    --file=$FOLDER_SYNC/$symbol-init.json \
    1> $FOLDER_SYNC/.$symbol-init-output.json

  [[ ! $? -eq 0 ]] \
    && loge "Failed to initialize enclave...aborting!" && exit 1 \
    || logi "Initializing EOS(perc20) side...done"
}


function eos_init_native() {
  exit_if_empty "$NATIVE_ACCOUNT_NAME" "Invalid NATIVE_ACCOUNT_NAME submitted"
  exit_if_empty "$SMART_CONTRACT_TOKEN_NAME" "Invalid SMART_CONTRACT_TOKEN_NAME submitted"
  exit_if_empty "$NATIVE_CHAIN_ID" "Invalid NATIVE_CHAIN_ID submitted"
  
  eos_init \
    "$NATIVE_ACCOUNT_NAME" \
    "$SMART_CONTRACT_TOKEN_NAME" \
    "$NATIVE_CHAIN_ID"
}

function eos_init_host() {
  exit_if_empty "$HOST_ACCOUNT_NAME" "Invalid HOST_ACCOUNT_NAME submitted"
  exit_if_empty "$SMART_CONTRACT_TOKEN_NAME" "Invalid SMART_CONTRACT_TOKEN_NAME submitted"
  exit_if_empty "$HOST_CHAIN_ID" "Invalid HOST_CHAIN_ID submitted"
  
  eos_init \
    "$HOST_ACCOUNT_NAME" \
    "$SMART_CONTRACT_TOKEN_NAME" \
    "$HOST_CHAIN_ID"
}


function initialize_eos() {
  if [[ $NATIVE_SYMBOL == "erc20" ]]; then
    exit_if_empty "$HOST_CHAIN_ID" "Invalid HOST_CHAIN_ID submitted"
    erc20_eos_init "$HOST_CHAIN_ID"
    return 0
  fi

  [[ `env | egrep '^eos$' | grep 'NATIVE'` ]] \
  && eos_init_native \
  || eos_init_host
}

function prepare_eos_sync_material() {
  loge "prepare_eos_sync_material: NOT implemented!"
exit 1
}