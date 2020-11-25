#!/bin/bash

source ./utils/common.sh
source ./modules/other.sh

ID=1
MODULE_NAME="Inne"

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
    "1") animation ;;
    "2") star_wars ;;
    "*");;
  esac
}