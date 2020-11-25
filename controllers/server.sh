#!/bin/bash

source ./utils/common.sh
source ./modules/server.sh

ID=3
MODULE_NAME="Funkcje serwerowe"

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
    "1") function_install_nginx ;;
    "2") function_install_mysql ;;
    "3") function_install_phpmyadmin ;;
    "*");;
  esac
}