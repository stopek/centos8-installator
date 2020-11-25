#!/bin/bash
# koment, v2
source ./utils/common.sh
source ./utils/util.sh

base="$(dirname "$(readlink -f "$0")")"

function init() {
  cd "$base" || exit
  controllers=$(ls controllers/*.sh)

  declare -A controllers_array

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

    #dodajemy controller do menu
    double_column "$KEY" "$name"
  done

  line
  #dodajemy opcje niezwiązane z modulami
  double_column "x" "Exit"
  line

  #czekamy na wybór modułu
  _read "controller_choice" "Wybierz grupę instalacji"

  case "$var_controller_choice" in
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
            init
          ;;
          *)
            call_controller_function "$current_entry" "controller" "$var_sub_controller_choice"
            line
            echo "Kliknij dowolny przycisk aby kontynuować"
            line
            read -r
            clear
            init
          ;;
        esac

      else
        clear
        init
      fi
      ;;
  esac
}

clear
init
