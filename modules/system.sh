#!/bin/bash

source ./utils/common.sh

#postawowy update systemu
function function_install_base() {
  _read "install_base" "Czy podstawowy upgrade?" "y/n"

  if [[ "$var_install_base" == "y" ]]; then
    sudo dnf upgrade
    sudo dnf update
  fi
}

#wyświetla statusy zainstalowanych usług
function function_show_statuses() {
  _read "show_statuses" "Pokazać stan usług?" "y/n"

  if [[ "$var_show_statuses" == "y" ]]; then
    sudo systemctl status php72-php-fpm
    sudo systemctl status php73-php-fpm
    sudo systemctl status php74-php-fpm
    sudo systemctl status php80-php-fpm
    sudo systemctl status nginx.service
    sudo systemctl status mysqld.service
  fi
}