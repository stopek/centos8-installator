#!/bin/bash

ID=3
MODULE_NAME="Narzędzia"

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
    "1") function_install_git ;;
    "2") function_install_yarn ;;
    "3") function_install_symfony ;;
    "4") function_create_cloudflare_ssl ;;
    "5") function_install_composer ;;
    "6") function_install_nextcloud ;;
    "*");;
  esac
}