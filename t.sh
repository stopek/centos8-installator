#!/bin/bash

base="$(dirname "$(readlink -f "$0")")"

source ./utils/core.sh

import_utils "util"
import_utils "common"

#wsnpm
#yum install -y gcc-c++ make
#function function_install_mongodb() {
#  local -r repo_dir="/etc/yum.repos.d"
#  sudo rm -rf "${repo_dir}/mongod*"
#  sudo yum clean all
#
#  local -r repo_config_path="${repo_dir}mongodb-4.4.repo";
#
#  #dodajemy repozytorium MongoDB
#  cat > "${repo_config_path}" << EOF
#[mongodb-org]
#name=MongoDB Repository
#baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.4/x86_64/
#gpgcheck=1
#enabled=1
#gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
#EOF
#
#  sudo dnf install mongodb-org
#
##  #dodajemy config wyłączający THP
##  local -r thp_config_path="/etc/systemd/system/disable-thp.service"
##  rm -f "${thp_config_path}"
##  cat > "${thp_config_path}" << EOF
##[Unit]
##Description=Disable Transparent Huge Pages (THP)
##After=sysinit.target local-fs.target
##Before=mongod.service
##
##[Service]
##Type=oneshot
##ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'
##
##[Install]
##WantedBy=basic.target
##EOF
##
##  sudo systemctl daemon-reload
##  sudo systemctl start disable-thp.service
##  sudo systemctl enable disable-thp
##
##  local -r tuned_config_path="/etc/tuned/no-thp/tuned.conf"
##  rm -f "${tuned_config_path}"
##  cat > "${tuned_config_path}" << EOF
##[main]
##include=virtual-guest
##
##[vm]
##transparent_hugepages=never
##EOF
##
##
##  sudo tuned-adm profile no-thp
#  sudo systemctl start mongod
#  sudo systemctl enable mongod
#  sudo systemctl status mongod
#  mongo --eval 'db.runCommand({ connectionStatus: 1 })'
#}
#
#function_install_mongodb


  configs_dir=$(get_config "paths" "configs_dir")

  import "${configs_dir}" "${1}"

exit 1

# pozycja aktualnie wybranego menu
# domyślnie 0 oznacza, że żadna
# opcja nie będzie zaznaczona
current_selected_menu=1

# główna funkcja zarządzająca wyborami
# $1 - numer aktualnie wybranego menu
function init() {
  # dodatkowe opcje informujące o aktualnych usługach
  header_services

  # w razie ucieczki w modułach
  # wracamy do katalogu wyjściowego
  cd "$base" || exit

  declare -A controllers_array
  local max_key_number="0"

  line

  controllers=$(controllers_list)
  # pętla po dostępnych controllerach
  for entry in $controllers
  do
    controller_name=$(getFileName "${entry}")
    choice=$(call_controller_function "${controller_name}" "choice")

    controllers_array["$choice"]="${controller_name}"
  done

  #sortujemy klucze z tablicy z listą controllerów
  KEYS=$(
    for KEY in ${!controllers_array[@]}; do
      echo "$KEY"
    done | sort | awk -F::: '{print $1}'
  )

  #wyświetlamy menu
  for KEY in $KEYS; do
    controller_name=${controllers_array[$KEY]}
    name=$(call_controller_function "$controller_name" "name")

    if [[ $current_selected_menu = $KEY ]]; then
      printf "\e[30m\e[107m"
    fi

    #dodajemy controller do menu
    double_column "$KEY" "$name"

    if [[ $current_selected_menu = $KEY ]]; then
      printf "\e[0m"
    fi

    max_key_number="$KEY"
  done

  line
  #dodajemy opcje niezwiązane z modulami
  double_column "x" "Exit"
  line

  #czekamy na wybór controllera
  _read "controller_choice" "Wybierz kategorię" ":allow_empty:" "-rsn1 -p" "-rsn2 -p"

  if [[ -z $var_controller_choice && $current_selected_menu -gt 0 ]];
  then
      var_controller_choice=$current_selected_menu
  fi

  #case dla głównego controllera
  case "$var_controller_choice" in
    #kliknięcie strzałki w górę
    '[A')
      define_next_selected "$max_key_number" "up"
      clear
      init "$max_key_number"
    ;;

    #kliknięcie strzałki w dół
    '[B')
      define_next_selected "$max_key_number" "down"
      clear
      init "$max_key_number"
    ;;

    "x")
      clear
      exit
    ;;

    *)
      if [ ${controllers_array[$var_controller_choice]+_} ];
      then
        current_entry=${controllers_array[$var_controller_choice]}
        entry_filename=$(basename "$current_entry")
        module_name="${entry_filename/.sh/}"

        log "action" "Użytkownik wybrał akcję moduł (${current_entry})"
        clear
        line
        generate_menu "./menus/$module_name"
        line

        #czekamy na dla danego controllera
        _read "sub_controller_choice" "Co robimy?" "" "-rsn1 -p"
        case "$var_sub_controller_choice" in
          "x")
            clear
            exit
          ;;
          "b")
            clear
            init "1"
          ;;
          *)
            import_module "${current_entry}"
            log "action" "Użytkownik wybrał akcję modułu (${current_entry}->${var_sub_controller_choice})"
            call_controller_function "$current_entry" "controller" "$var_sub_controller_choice"
            line
            echo "Kliknij dowolny przycisk aby kontynuować"
            line
            read -r
            clear
            init "1"
          ;;
        esac
      else
        clear
        init "$current_selected_menu"
      fi
      ;;
  esac
}

log "init" "Bash was started"

clear
init "$current_selected_menu"