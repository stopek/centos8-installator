#!/bin/bash -x

TRUE=0
FALSE=1

#generuje menu z pliku
# $1 - ścieżka do pliku .txt z wpisami menu bez .txt na końcu
function generate_menu() {
  local menu_filepath="${1}.txt"

  if file_exists "$menu_filepath";
  then
    cat "$menu_filepath" | sed 's/\t/,|,/g' | column -s ',' -t
  else
    echo "Menu $menu_filepath nie istnieje"
  fi
}

function double_column() {
    echo "$1,$2" | column -s ',' -t
}

line() {
  echo "+--------------------------------------------------+"
}

# zwraca funkcję z danego modułu
# $1 - ścieżka do modułu
# $2 - nazwa funkcji z modułu do wywołania
function call_controller_function() {
  source "$1"

  eval "${2}" "$3" "$4"
}

# wywołuje funkcję z modułu
# $1 - nazwa modułu
# $2 - nazwa funkcji
# $3 $4 - parametry przekazywane do funkcji
function call_module_function() {
  source "./modules/${1}.sh"

  eval "${2}" "${3}" "${4}"
}

function service_exists() {
  # Restart apache2 service, if it exists.
  if service --status-all | grep -Fq "$1";
  then
    return 0
  else
    return 1
  fi
}

# zwraca ustawienie z pliku
# $1 - nazwa pliku/grupy ustawień
# $2 - nazwa funkcji/ustawienia
function get_config() {
  source "./configs/$1.sh"

  eval "${2}"
}


#zwykla funkcja in_array
array_contains() {
  local seeking=$1
  shift
  local in=1
  for element; do
    if [[ $element == "$seeking" ]]; then
      in=0
      break
    fi
  done
  return $in
}

#formater wproawdzania danych
# $1 - nazwa zmiennej
# $2 - opis/pytanie dot. wprowadzanej wartości
# $3 - dostępne opcje wprowadzone po / (np: y/x). Jeśli puste wtedy tylko wymaga wprowadzenia.
function _read() {
  IFS='/' read -ra my_array <<<"$3"

  echo -e "\e[30m\e[107m"
  line
  echo "| $2 "

  if [[ "$3" != ":allow_empty:" ]];
  then
    if [ -n "$3" ];
    then
      echo "| <dostępne: $3>"
    else
      echo "| <wprowadź dowolnie>"
    fi
  fi

  line

  declare -g var_$1
  local ref=var_$1

  read -rsn1 -p "| " "var_$1"

  line

  if [ -n "$3" ]; then
    if [[ "$3" != ":allow_empty:" ]];
    then
      if ! array_contains "${!ref}" "${my_array[@]}"; then
        echo -e "\e[37m\e[41mWartość nieprawidłowa, spróbuj ponownie...\e[0m"
        echo ""

        _read "$1" "$2" "$3"
      fi
    fi
  else
    if [ -z "${!ref}" ]; then
      echo -e "\e[37m\e[41mWartość pusta, wprowadź wartość...\e[0m"
      echo ""
      _read "$1" "$2" "$3"
    fi
  fi
  echo -e "\e[0m"
}

#sprawdza czy dana komenda istnieje
function command_exists() {
  type "$1" &>/dev/null
}

function simple_via_yum_modules() {
  sudo yum module install "$1"
}

function simple_via_dnf() {
  dnf install "$1"
}

function replace_in_file() {
  sudo sed -i -e "s/$1/$2/gi" "$3"
}

#sprawdza czy plik istnieje
# $1 - ścieżka do pliku
function file_exists() {
  if [[ -f "$1" ]];
  then
    return $TRUE
  else
    return $FALSE
  fi
}

#restartowanie nginx jeśli zainstalowany
function restart_nginx() {
  if command_exists nginx; then
    sudo systemctl restart nginx.service
  fi
}

#funkcja sprawdza czy w danym pliku znaleziono stringa
function string_exists_in_file() {
  #nie znaleziono
  if [[ $(grep "$1" $2) ]];
  then
    return 0
  else
    return 1
  fi
}

