#!/bin/bash

source ./utils/common.sh
source ./modules/projects.sh

ID=7
MODULE_NAME="Projekty"

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
    "1") clear_symfony ;;
    "*");;
  esac
}