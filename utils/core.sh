#!/bin/bash -x

function current_date() {
  # shellcheck disable=SC2034
  display_date=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${display_date}"
}

# zwraca ustawienie z pliku
# $1 - nazwa pliku/grupy ustawień
# $2 - nazwa funkcji/ustawienia
function get_config() {
  source "${base}/configs/${2}.sh"

  eval "${2}"
}

# wczytuje plik z ustawieniami
# $1 - nazwa pliku (np. core)
function import_configs() {
  local -r configs_dir=$(get_config "paths" "configs_dir")

  import "${configs_dir}" "${1}"
}

# wczytuje plik z narzędziami
# $1 - nazwa pliku (np. core)
function import_utils() {
  local -r utils_dir=$(get_config "paths" "utils_dir")

  import "${utils_dir}" "${1}"
}

# wczytuje plik z narzędziami
# $1 - nazwa pliku (np. core)
function import_module() {
  local -r modules_dir=$(get_config "paths" "modules_dir")

  import "${modules_dir}" "${1}"
}

# wczytuje plik z controllerami
# $1 - nazwa pliku (np. core)
function import_controller() {
  local -r controller_dir=$(get_config "paths" "controller_dir")

  import "${controller_dir}" "${1}"
}

# funkcja importująca source
# $1 - nazwa katalogu do importu
#      parametr powinien zawierać / na początku
#      i nie powinien kończyć się / (np. /utils)
# $2 - nazwa pliku do importu bez rozszerzenia (np. core)
function import() {
  # shellcheck disable=SC1090
  # shellcheck disable=SC2154
  source "${base}${1}/${2}.sh"
}

# zwraca funkcję z danego modułu
# $1 - ścieżka do controllera
# $2 - nazwa funkcji z modułu do wywołania
function call_controller_function() {
  import_controller "${1}"

  eval "${2}" "$3" "$4"
}

# wywołuje funkcję z modułu
# $1 - nazwa modułu
# $2 - nazwa funkcji
# $3 $4 - parametry przekazywane do funkcji
function call_module_function() {
  import_module "${1}"

  eval "${2}" "${3}" "${4}"
}

# zwraca listę controllerów
function controllers_list() {
  local -r controller_dir=$(get_config "paths" "controller_dir")
  controller_dir_full="${base}${controller_dir}/*.sh"

  # shellcheck disable=SC2086
  ls ${controller_dir_full}
}

function log() {
  local -r date=$(current_date)
  local -r logs_dir=$(get_config "paths" "logs_dir")

  local -r file="${1}"
  local -r message="${2}"
  local -r group="${3}"

  if [ ! -z "$group" ]
  then
    local -r log_path="${base}${logs_dir}/${file}.txt"
  else
    local -r log_dir="${base}${logs_dir}/${group}/"
    mkdir -p "${log_dir}"

    local -r log_path="${log_dir}${file}.txt"
  fi

  echo -e "DATA-Line-1\n$(cat input)" > input
#  (echo "${new_message}"; cat "${log_path}") > "${log_path}"
#  sed -i.old "1s;^;${new_message};" "${log_path}"
  echo "${date}: ${message}"  | tee -a "${log_path}"
}

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