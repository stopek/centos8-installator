#!/bin/bash

ID=4
MODULE_NAME="Funkcje systemowe"

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
    "1") function_install_base ;;
    "2") function_show_statuses ;;
    "*");;
  esac
}