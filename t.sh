#!/bin/bash
# koment, v2
source ./utils/common.sh
source ./utils/util.sh

base="$(dirname "$(readlink -f "$0")")"

#pozycja aktualnie wybranego menu
#domyślnie 0 oznacza, że żadna
#opcja nie będzie zaznaczona
current_selected_menu=0

function define_next_selected() {
  local max="$1"
  local type="$2"

  if [[ $current_selected_menu = 0  && "$type" = "up" ]]; then
    current_selected_menu=0
    return 0
  fi

  if [[ $current_selected_menu = $max && "$type" = "down" ]]; then
    current_selected_menu=$max
    return 0
  fi

  if [ "$type" = "up" ]; then
    ((current_selected_menu=current_selected_menu-1))
  fi

  if [ "$type" = "down" ]; then
    ((current_selected_menu=current_selected_menu+1))
  fi
}

function init() {
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
  escape_char=$(printf "\u1b")
  _read "controller_choice" "Wybierz kategorię" ":allow_empty:"

  #jeśli znak jest specjalny wtedy potrzebujemy "2"znaków
  if [[ $var_controller_choice == $escape_char ]]; then
      read -rsn2 var_controller_choice
  fi

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
        _read "sub_controller_choice" "Co robimy?"
        case "$var_sub_controller_choice" in
          "x")
            clear
            exit
          ;;
          "b")
            clear
            init "0"
          ;;
          *)
            call_controller_function "$current_entry" "controller" "$var_sub_controller_choice"
            line
            echo "Kliknij dowolny przycisk aby kontynuować"
            line
            read -r
            clear
            init "0"
          ;;
        esac

      else
        clear
        init "0"
      fi
      ;;
  esac
}

clear
init "0"
