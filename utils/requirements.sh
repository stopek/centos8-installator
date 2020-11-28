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