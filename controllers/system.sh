#!/bin/bash

source ./utils/common.sh
source ./modules/system.sh

ID=5
MODULE_NAME="System"

#wybór tej opcji spowoduje uruchomienie
#controllera dla tego modułu
function choice() {
  echo $ID
}

#zwraca nazwę wyświetlaną w menu
function name() {
  echo "$MODULE_NAME"
}

#główny kontroller
#powinien zawierać switch
function controller() {
  case "$1" in
    "1") function_install_base ;;
    "2") function_show_statuses ;;
    "*");;
  esac
}