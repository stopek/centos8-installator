#!/bin/bash

ID=2
MODULE_NAME="Serwer i bazy danych"

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
    "1") function_install_nginx ;;
    "2") function_install_mysql ;;
    "3") function_install_phpmyadmin ;;
    "*");;
  esac
}