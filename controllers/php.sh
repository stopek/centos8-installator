#!/bin/bash

ID=1
MODULE_NAME="PHP"

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
    "1") function_install_php72 ;;
    "2") function_install_php73 ;;
    "3") function_install_php74 ;;
    "4") function_install_php80 ;;
    "5") function_install_default_php ;;
    "6") function_add_extension_to_php ;;
    "*") echo "nie ma tego" ;;
  esac
}