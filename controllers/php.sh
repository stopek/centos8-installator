#!/bin/bash

source ./utils/common.sh
source ./modules/php.sh

ID=2
MODULE_NAME="Instalacje PHP"

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
    "1") function_install_php72 ;;
    "2") function_install_php73 ;;
    "3") function_install_php74 ;;
    "4") function_install_php80 ;;
    "5") function_install_default_php ;;
    "6") function_add_extension_to_php ;;
    "*");;
  esac
}