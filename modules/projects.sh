#!/bin/bash

source ./utils/common.sh


function clear_symfony() {
  _read "clear_symfony" "Zainstalować czysty projekt symfony?" "y/n"

  if [[ "$var_clear_symfony" == "y" ]];
  then
    #sprawdzamy dostępność symfony
    if ! command_exists symfony;
    then
      echo "Symfony CLI nie jest zainstalowane!"

      source ./modules/tools.sh
      function_install_symfony
    fi

    #sprawdzamy dostępność composera
    if ! command_exists composer;
    then
      echo "Composer nie jest zainstalowany!"

      source ./modules/tools.sh
      function_install_composer
    fi

    #właściwe tworzenie projektu
    www_dir=$(get_config "paths" "www_dir")
    echo "Instalacje są w $www_dir"
    cd "$www_dir" || exit

    _read "project_name" "Podaj nazwę projektu ([a-z][0-9])"
    _read "project_type" "Podaj type projektu" "api/full"

    if [[ "$var_project_type" == "full" ]];
    then
      symfony new "$var_project_name" --full
    else
      symfony new "$var_project_name"
    fi

    cd "$www_dir/$var_project_name" || exit
    php bin/console about
  fi
}