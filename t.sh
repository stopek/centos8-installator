#!/bin/bash

source ./utils/common.sh
source ./utils/util.sh
source ./utils/core.sh

base="$(dirname "$(readlink -f "$0")")"

#pozycja aktualnie wybranego menu
#domyślnie 0 oznacza, że żadna
#opcja nie będzie zaznaczona
current_selected_menu=1

#główna funkcja zarządzająca wyborami
# $1 - numer aktualnie wybranego menu
function init() {
  header_services

  cd "$base" || exit
  controllers=$(ls controllers/*.sh)

  declare -A controllers_array
  local max_key_number="0"

  line

  #pętla po dostępnych controllerach
  for entry in $controllers
  do
    choice=$(call_controller_function "$entry" "choice")

    controllers_array["$choice"]="$entry"
  done

  #sortujemy
  KEYS=$(
    for KEY in ${!controllers_array[@]}; do
      echo "$KEY"
    done | sort | awk -F::: '{print $1}'
  )

  #wyświetlamy menu
  for KEY in $KEYS; do
    entry=${controllers_array[$KEY]}
    name=$(call_controller_function "$entry" "name")

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

  #czekamy na wybór modułu
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

    #kliknięcie strzałi w dół
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

clear
init "$current_selected_menu"