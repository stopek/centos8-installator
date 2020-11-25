#!/bin/bash

source ./utils/common.sh
source ./modules/ssh.sh

ID=4
MODULE_NAME="Opcje SSH"

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
    "1") function_create_ssh ;;
    "2") function_ssh_port ;;
    "*");;
  esac
}