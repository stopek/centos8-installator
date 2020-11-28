#!/bin/bash

# instaluje czystą wersję symfony
function clear_symfony() {
  _read "clear_symfony" "Zainstalować czysty projekt symfony?" "y/n"

  # shellcheck disable=SC2154
  if [[ "$var_clear_symfony" == "y" ]];
  then
    require_symfony
    require_git
    require_composer

    #właściwe tworzenie projektu
    local -r www_dir=$(www_dir)
    echo "Instalacje są w $www_dir"
    cd "$www_dir" || exit

    _read "project_name" "Podaj nazwę projektu ([a-z][0-9])"
    _read "project_type" "Podaj type projektu" "api/full"

    # shellcheck disable=SC2154
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