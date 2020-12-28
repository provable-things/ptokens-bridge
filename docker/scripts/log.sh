#!/bin/bash

function logd() {
  output=""
  [ -z "$1" ] && read -r output || output="D $1"
  [ ! -z "$DEBUG" ] && echo "$output" || :
}

function logi() {
  output=""
  [ -z "$1" ] && read -r output || output="✔ $1"
  [[ ! -z "$DEBUG" || ! -z "$INFO" ]] && echo "$output" || :
}

function loge() {
  output=""
  [ -z "$1" ] && read -r output || output="✘ $1"
  echo "$output"
}