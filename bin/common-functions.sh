#!/usr/bin/env bash


function set-config(){
  key=$1;shift
  value="$@"; shift
  [[ -f $PROJECT_ENV_FILE ]]  || (echo No PROJECT_ENV_FILE set; exit 1)
  config=$(cat $PROJECT_ENV_FILE)
  config="$(echo "$config" | grep -v "export $key=" | sort)"
  if [[ -n $value ]]; then
  cat <<EOF | sort > $PROJECT_ENV_FILE
$config
export $key="$value"
EOF
  else
  cat <<EOF | sort > $PROJECT_ENV_FILE
$config
EOF
  fi
}

function unset-config(){
  key=$1;shift
  set-config $key ""
}

function log(){
  echo $(date +"[%Y-%m-%d %H:%m:%S]") "$@"
}

function banner(){
  cat <<EOF
========================================================================
$@
========================================================================
EOF
}
