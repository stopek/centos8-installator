#!/bin/bash

ID=6
MODULE_NAME="SSH"

# wybór tej opcji spowoduje uruchomienie
# controllera dla tego modułu
function choice() {
  echo $ID
}

# zwraca nazwę wyświetlaną w menu
function name() {
  echo "$MODULE_NAME"
}

# główny router
# $1 - opcja wybrana przez użytkownika
function router() {
  case "$1" in
    "1") function_create_ssh ;;
    "2") function_ssh_port ;;
    "*");;
  esac
}