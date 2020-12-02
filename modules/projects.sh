#!/bin/bash

# instaluje czystą wersję symfony
function clear_symfony() {
  _read "clear_symfony" "Zainstalować czysty projekt symfony?" "y/n"

  if [[ "$var_clear_symfony" == "y" ]];
  then
    require_symfony
    require_git
    require_composer

    #właściwe tworzenie projektu
    local -r www_dir=$(www_dir)
    cd "$www_dir" || exit

    _read "project_name" "Podaj nazwę projektu ([a-z][0-9])"
    _read "project_type" "Podaj type projektu" "api/full"

    # instalacja symfony
    if [[ "$var_project_type" == "full" ]];
    then
      symfony new "$var_project_name" --full
    else
      symfony new "$var_project_name"
    fi

    # ustalamy czy tworzyć domyślną konfigurację
    _read "create_vhost" "Czy utworzyć domyślną konfiurację nginx?" "y/n"

    if [[ "$var_create_vhost" == "y" ]];
    then
      _read "domain_name" "Podaj nazwę domeny"

      local -r php_versions=$(get_config "options" "php_versions")
      _read "install_to_php" "Do której wersji?" "${php_versions}"

      local -r target_copy_path="/etc/nginx/sites-available/${var_project_name}.conf"
      local -r sites_enabled_dir="/etc/nginx/sites-enabled/"
      sudo cp "${base}/templates/symfony.empty.conf" "${target_copy_path}"
      local -r without_dot="${var_install_to_php/./}"

      eval "require_php${without_dot}_remi"

      replace_in_file "{{domain}}" "${var_domain_name}" "${target_copy_path}"
      replace_in_file "{{fastcgi_pass}}" "127.0.0.1:90${without_dot}" "${target_copy_path}"

      sudo ln -s "${target_copy_path}" "${sites_enabled_dir}"

      local -r project_dir="${www_dir}/${var_project_name}"
    fi

    cd "${project_dir}" || exit
  fi
}