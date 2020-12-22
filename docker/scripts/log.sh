function logd() {
  output=""
  [ -z "$1" ] && read output || output="D $1"
  [ ! -z "$DEBUG" ] && echo "$output" || :
}

function logi() {
  output=""
  [ -z "$1" ] && read output || output="✔ $1"
  [[ ! -z "$DEBUG" || ! -z "$INFO" ]] && echo "$output" || :
}

function loge() {
  output=""
  [ -z "$1" ] && read output || output="✘ $1"
  echo "$output"
}