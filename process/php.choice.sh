#!/bin/bash

# @todo - funkcja wywoływana w momencie gdy proces zostanie przerwany
function end() {
  exit 1
}

# proces w którym użytkownik musi wybrać
# z listy zainstalowanych wersji php jakąś wersję
# lub zainstalować jakąś wersję php
# funkcja powinna zwracać nazwę usługi (np. php73)
function start() {
  clear
  local -r php_versions=$(get_config "options" "php_versions")
  _read "choice_php_version" "Jaką wersję php potrzebujesz?" "${php_versions}/n"
  if [[ "$var_choice_php_version" == "n" ]];
  then
    end
  fi

  local -r choiced_version="php${var_choice_php_version/./}"

  # jeśli ta wersja php istnieje - wtedy zwracamy ją
  if ! command_exists "${choiced_version}";
  then
    call_module_function "php" "install_${choiced_version}"
  fi

  # zwracamy wersję wybraną przez użytkownika
  return "${choiced_version}"
}