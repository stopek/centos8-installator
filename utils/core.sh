#!/bin/bash -x

function header_service_item() {
  local -r service_name="${1}"
  local -r service_display="${2}"
  local -r is_dont_active=$(statusServiceDontExists "${service_name}")
  if [[ $is_dont_active ]];
  then
    printf "\e[41m\e[97m"
  else
    printf "\e[42m\e[97m"
  fi

  printf "["
  printf "${service_display}"
  printf "]"

  printf "\e[0m "
}

function header_services() {
  header_service_item "nginx" "NGINX"
  header_service_item "mysqld" "MySQL"
  header_service_item "postgresql-12" "PostgreSQL"
  header_service_item "redis" "Redis"
  header_service_item "php-fpm" "PHP"
  header_service_item "php72-php-fpm" "PHP 7.2"
  header_service_item "php73-php-fpm" "PHP 7.3"
  header_service_item "php74-php-fpm" "PHP 7.4"
  header_service_item "php80-php-fpm" "PHP 8.0"

  echo
}

#funkcja określa aktualny numer zaznaczonego elementu
# $1 - maxymalna ilość elementów
# $2 - typ akcji (up|down)
function define_next_selected() {
  local max="$1"
  local type="$2"

  if [[ $current_selected_menu = 1  && "$type" = "up" ]];
  then
    return 0
  fi

  if [[ $current_selected_menu = $max && "$type" = "down" ]];
  then
    return 0
  fi

  if [ "$type" = "up" ];
  then
    ((current_selected_menu=current_selected_menu-1))
  fi

  if [ "$type" = "down" ];
  then
    ((current_selected_menu=current_selected_menu+1))
  fi
}