#!/bin/bash

base="$(dirname "$(readlink -f "$0")")"

# shellcheck disable=SC1090
source "${base}/configs/paths.sh"
# shellcheck disable=SC1090
source "${base}/utils/core.sh"

import_utils "requirements"
import_utils "util"
import_utils "common"

# item of the currently selected menu
# 0 means neither
# the option will not be selected
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
    for KEY in "${!controllers_array[@]}"; do
      echo "$KEY"
    done | sort | awk -F::: '{print $1}'
  )

  #wyświetlamy menu
  for KEY in $KEYS; do
    controller_name=${controllers_array[$KEY]}
    name=$(call_controller_function "$controller_name" "name")

    if [[ $current_selected_menu = "$KEY" ]]; then
      printf "\e[30m\e[107m"
    fi

    #dodajemy controller do menu
    double_column "$KEY" "$name"

    if [[ $current_selected_menu = "$KEY" ]]; then
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

        log "app" "Użytkownik wybrał akcję moduł (${current_entry})"
        clear
        line
        generate_menu "$module_name"
        line

        #czekamy na dla danego controllera
        _read "sub_controller_choice" "Co robimy?" "" "-rsn1 -p"
        # shellcheck disable=SC2154
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
            route_name=$(get_route_name_from_id "${current_entry}" "${var_sub_controller_choice}")
            import_module "${current_entry}"
            log "app" "Użytkownik wybrał akcję modułu (${current_entry}->$route_name) id: ${var_sub_controller_choice}"
            call_controller_function "$current_entry" "router" "$var_sub_controller_choice"

            echo
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

log "app" "Bash was started"

clear
init "$current_selected_menu"