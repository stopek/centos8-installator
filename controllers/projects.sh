#!/bin/bash

ID=5
MODULE_NAME="Instalatory projektów"

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
    "1") clear_symfony ;;
    "*");;
  esac
}