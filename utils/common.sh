#!/bin/bash -x

TRUE=0
FALSE=1

#generuje menu z pliku
# $1 - ścieżka do pliku .txt z wpisami menu bez .txt na końcu
function generate_menu() {
  local menu_filepath="${1}.txt"

  if file_exists "$menu_filepath";
  then
#    cat "$menu_filepath" | while read line
#    do
#      echo "$line"
#    done

    cat "$menu_filepath" | sed 's/\t/,|,/g' | column -s ',' -t
  else
    echo "Menu $menu_filepath nie istnieje"
  fi
}

function double_column() {
    echo "$1,$2" | column -s ',' -t
}

# to nie jest zwykła linia
# to magiczna linia oddzielająca
# dobro od zła!
# cześć magicznej linii!
line() {
  echo "+--------------------------------------------------+"
}

# sprawdza czy dana usługa jest zainstalowana
# $1 - nazwa usługi (np. nginx)
function service_exists() {
  if service --status-all | grep -Fq "$1";
  then
    return 0
  else
    return 1
  fi
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
# $4 - parametry do read (domyślnie: "-r -p")
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

  #jeśli parametr $4 nie zostanie przekazany
  #wtedy użytkownik może wprowadzić dowolny
  #tekst i potwierdzić go ENTER'em
  #
  #w przeciwnym razie ustawiamy tak, żeby
  #potwierdzenie było od razu po wciśnięciu
  #pierwszego znaku
  if [ -z "$4" ];
  then
    read -r -p "| " "var_$1"
  else
    local escape_char=$(printf "\u1b")
    read ${4} "| " "var_$1"

    #jeśli znak jest specjalny wtedy potrzebujemy "2" znaków
    if [[ ${!ref} == $escape_char ]]; then
      read ${5} "| " "var_$1"
    fi
  fi

  line

  if [ -n "$3" ];
  then
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
# $1 - nazwa komendy (np. nano)
function command_exists() {
  type "$1" &>/dev/null
}

# instalacja z repo yum
# $1 - nazwa paczki do zainstalownia (np. nginx)
function simple_via_yum_modules() {
  sudo yum module install "$1"
}

# instalacja przez dnf
# $1 - nazwa paczki do zainstalowania (np. nginx)
function install_via_dnf() {
  sudo dnf install "$1"
}

# zamienia treść w pliku
# $1 - treść do zamiany
# $2 - treść, na którą będzie zamieniane
# $3 - plik, w którym zamieniamy
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
# $1 - szukana treść
# $2 - nazwa pliku
function string_exists_in_file() {
  if [[ $(grep "$1" $2) ]];
  then
    return $TRUE
  else
    return $FALSE
  fi
}