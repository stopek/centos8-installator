#!/bin/bash

# pomocnicza funkcja wyświetlająca
# komunikat dla danej reguły wymagalności
function require_message_before() {
  message_sufix="Uruchamiam instalację..."
  local -r command_name="${1}"

  warning "Pakiet ${command_name} nie jest zainstalowany. ${message_sufix}"
}

# reguła wymagalności dla NGINX'a
function require_nginx() {
  if ! command_exists nginx;
  then
    require_message_before "Nginx"
    call_module_function "server" "function_install_nginx"
  fi
}

# reguła wymagalności dla GIT'a
function require_git() {
  if ! command_exists git;
  then
    require_message_before "GIT"
    call_module_function "tools" "function_install_git"
  fi
}

# reguła wymagalności dla Socat'a
function require_socat() {
  if ! command_exists socat;
  then
    require_message_before "Socat"
    install_via_dnf "socat"
  fi
}

# reguła wymaglaności dla Composer'a
function require_composer() {
  if ! command_exists composer;
  then
    require_message_before "Composer"
    call_module_function "tools" "function_install_composer"
  fi
}

# reguła wymagalności dla Symfony CLI
function require_symfony() {
    if ! command_exists symfony;
    then
      require_message_before "Symfony CLI"
      call_module_function "tools" "function_install_symfony"
    fi
}

# reguła wymagalności dla PHP7.2 z repozytorium remi
function require_php72_remi() {
    if ! command_exists php72;
    then
      require_message_before "PHP 7.2 remi:repo"
      call_module_function "php" "install_php72"
    fi
}

# reguła wymagalności dla PHP7.3 z repozytorium remi
function require_php73_remi() {
    if ! command_exists php73;
    then
      require_message_before "PHP 7.3 remi:repo"
      call_module_function "php" "install_php73"
    fi
}

# reguła wymagalności dla PHP7.4 z repozytorium remi
function require_php74_remi() {
    if ! command_exists php74;
    then
      require_message_before "PHP 7.4 remi:repo"
      call_module_function "php" "install_php74"
    fi
}

# reguła wymagalności dla PHP8.0 z repozytorium remi
function require_php80_remi() {
    if ! command_exists php80;
    then
      require_message_before "PHP 8.0 remi:repo"
      call_module_function "php" "install_php80"
    fi
}
# reguła wymagalności, która sprowadza się
# do instalacji prostej paczki z dnf
# $1 - nazwa wymaganej komendy (np. telnet)
function require_simple_dnf() {
  local -r command_name="${1}"

  if ! command_exists "${command_name}";
  then
    require_message_before "${command_name}"
    install_via_dnf "${command_name}"
  fi
}