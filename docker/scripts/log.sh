#!/bin/bash

function logd() {
  output=""
  if [[ -z "$1" ]]; then read -r output; else output="D $1"; fi
  if [[ -n "$DEBUG" ]]; then echo "$output"; fi
}

function logi() {
  output=""
  if [[ -z "$1" ]]; then read -r output; else output="✔ $1"; fi
  if [[ -n "$DEBUG" || -n "$INFO" ]]; then echo "$output"; fi
}

function loge() {
  output=""
  if [[ -z "$1" ]]; then read -r output; else output="✘ $1"; fi
  echo "$output"
}