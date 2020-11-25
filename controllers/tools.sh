#!/bin/bash

source ./utils/common.sh
source ./modules/tools.sh

ID=6
MODULE_NAME="Dodatkowe narzędzia"

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
    "1") function_install_git ;;
    "2") function_install_yarn ;;
    "3") function_install_symfony ;;
    "4") function_create_cloudflare_ssl ;;
    "5") function_install_composer ;;
    "*");;
  esac
}